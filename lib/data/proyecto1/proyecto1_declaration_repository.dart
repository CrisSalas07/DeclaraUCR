import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_mapper.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:flutter/foundation.dart';

/// [DeclarationRepository] over the Proyecto 1 schema, scoped to one
/// declarant: `declarations/{id}` with its current version, the version's
/// appointment and external jobs, plus the period and the coordination's
/// assignment (where the courses come from).
///
/// Writes follow the batches of DeclaraHorario (`createDraft`,
/// `reopenAsDraft`, `markValidated`), because its `firestore.rules` only
/// accept them that way: a status change always carries its audit event.
class Proyecto1DeclarationRepository implements DeclarationRepository {
  Proyecto1DeclarationRepository(
    this._firestore, {
    required this._uid,
    required this._periods,
  });

  final FirebaseFirestore _firestore;
  final String _uid;
  final PeriodRepository _periods;

  /// Content saves do not touch the declaration document, so the list
  /// stream would not see them: this tells it to load again.
  final _changes = StreamController<void>.broadcast();

  CollectionReference<Map<String, dynamic>> get _declarations =>
      _firestore.collection('declarations');

  // ---- Reading ------------------------------------------------------------

  /// The declarant's declarations, all statuses, most recent first. The
  /// rules only allow this query filtered by `declarantUid`.
  @override
  Stream<List<Declaration>> watchAll() {
    late final StreamController<List<Declaration>> out;
    QuerySnapshot<Map<String, dynamic>>? last;
    StreamSubscription<Object?>? query, changes;
    var latest = 0;

    Future<void> emit() async {
      final snap = last;
      if (snap == null) return;
      // Only the newest load is delivered, whatever order they finish in.
      final mine = ++latest;
      final lookups = _Lookups(_periods);
      final items = await Future.wait(
        snap.docs.map((doc) => _tryLoad(doc.id, doc.data(), lookups)),
      );
      if (mine != latest || out.isClosed) return;
      out.add(
        items.nonNulls.toList()
          ..sort((a, b) => _byDateDesc(a.updatedAt, b.updatedAt)),
      );
    }

    out = StreamController<List<Declaration>>(
      onListen: () {
        query = _declarations
            .where('declarantUid', isEqualTo: _uid)
            .snapshots()
            .listen((snap) {
              last = snap;
              emit();
            }, onError: out.addError);
        changes = _changes.stream.listen((_) => emit());
      },
      onCancel: () async {
        await query?.cancel();
        await changes?.cancel();
      },
    );
    return out.stream;
  }

  static int _byDateDesc(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));

  /// One declaration that cannot be read must not hide the whole list: it
  /// is skipped and logged.
  Future<Declaration?> _tryLoad(
    String id,
    Map<String, dynamic> data,
    _Lookups lookups,
  ) async {
    try {
      return await _load(id, data, lookups);
    } catch (e) {
      debugPrint('Skipping declaration $id: $e');
      return null;
    }
  }

  @override
  Future<Declaration?> getById(String id) async {
    final data = (await _declarations.doc(id).get()).data();
    if (data == null || data['declarantUid'] != _uid) return null;
    return _load(id, data, _Lookups(_periods));
  }

  Future<Declaration> _load(
    String id,
    Map<String, dynamic> data,
    _Lookups lookups,
  ) async {
    final versionId = data['currentVersionId'];
    final periodId = data['periodId'];
    if (versionId is! String || periodId is! String) {
      throw FormatException('Malformed declaration $id');
    }
    final version = _declarations.doc(id).collection('versions').doc(versionId);
    final (versionDoc, appointments, externalJobs, assignment, period) = await (
      version.get(),
      version.collection('appointments').get(),
      version.collection('externalJobs').get(),
      lookups.assignment(periodId),
      lookups.period(periodId),
    ).wait;
    final versionData = versionDoc.data();
    if (versionData == null) {
      throw FormatException('Declaration $id without its version');
    }
    return Proyecto1Mapper.declaration(
      id: id,
      declaration: data,
      version: versionData,
      appointments: [for (final d in appointments.docs) d.data()],
      externalJobs: [for (final d in externalJobs.docs) d.data()],
      assignment: assignment,
      period: period,
    );
  }

  // ---- Writing ------------------------------------------------------------

  @override
  Future<String> save(Declaration declaration) async {
    final target = declaration.status;
    if (target != DeclarationStatus.draft &&
        target != DeclarationStatus.validated) {
      throw const DeclarationSaveException(
        'Desde el teléfono solo se guarda el borrador o se valida.',
      );
    }
    try {
      final id = declaration.id;
      if (id == null || id.isEmpty) {
        await _create(declaration);
      } else if (!await _update(declaration, id)) {
        return id;
      }
      if (target == DeclarationStatus.validated) {
        await _transition(
          declaration.id!,
          from: DeclarationStatus.draft,
          to: DeclarationStatus.validated,
          event: 'VALIDACION_EJECUTADA',
          versionChanges: {
            'hoursSummary': _hoursSummary(declaration),
            'validationPassed': true,
          },
        );
      }
      declaration.updatedAt = DateTime.now();
      return declaration.id!;
    } on FirebaseException catch (e) {
      // Offline, or the server did not answer: nothing was written (the
      // first read of every save goes to the server, see [_fromServer]).
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw const OfflineException();
      }
      rethrow;
    } finally {
      _changes.add(null);
    }
  }

  /// Every save starts by reading from the server, never from the copy in
  /// the phone: without a connection it fails at once instead of leaving
  /// writes queued that the server might reject later, unnoticed.
  static const _fromServer = GetOptions(source: Source.server);

  /// `createDraft` of DeclaraHorario plus the content, in one batch: the
  /// declaration in BORRADOR, version 1, the DECLARACION_CREADA event, the
  /// reservation of the period, the appointment and the external jobs.
  Future<void> _create(Declaration d) async {
    final periodId = d.periodId;
    if (periodId == null) {
      throw const DeclarationSaveException(
        'Elija el período de la declaración.',
      );
    }
    final profileData =
        (await _firestore.collection('users').doc(_uid).get(_fromServer))
            .data();
    if (profileData == null) {
      throw const DeclarationSaveException('Su perfil no está completo.');
    }
    final profile = FirestoreProfileRepository.fromMap(profileData);
    final (periodDoc, assignment, slot) = await (
      _firestore.collection('periods').doc(periodId).get(),
      _periods.assignmentFor(periodId),
      _firestore.collection('declarationSlots').doc('${periodId}_$_uid').get(),
    ).wait;
    final period = periodDoc.data();
    final problem = switch (()) {
      _ when !profile.hasSuperior =>
        'Aún no tiene superior asignado. Administración debe asignarlo en el '
            'sistema web.',
      _ when profile.campusId == null =>
        'Su perfil no tiene sede. Complete su perfil.',
      _ when period == null || period['enabled'] != true =>
        'El período ya no está abierto para nuevas declaraciones.',
      _ when assignment == null =>
        'La Coordinación de su carrera aún no le asignó cursos en este '
            'período.',
      _ when slot.exists => 'Ya tiene una declaración en este período.',
      _ => null,
    };
    if (problem != null) throw DeclarationSaveException(problem);

    final names = await _workplaceNames(profile);
    final ref = _declarations.doc();
    final version = ref.collection('versions').doc();
    final event = ref.collection('events').doc();
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch()
      ..set(ref, {
        'declarantUid': _uid,
        'declarantName': profile.fullName,
        'periodId': periodId,
        'superiorUid': profile.superiorUid,
        'campusId': profile.campusId,
        'status': DeclarationStatus.draft.value,
        'currentVersionId': version.id,
        'currentVersionNumber': 1,
        'currentResponsibleUid': _uid,
        'currentResponsibleRole': UserRole.declarant.value,
        'lastEventId': event.id,
        'createdAt': now,
        'updatedAt': now,
      })
      ..set(version, {
        'number': 1,
        'declarantSnapshot': {
          'fullName': profile.fullName,
          'identification': profile.identification,
          'phone': profile.phone,
          'email': profile.email,
          'unitName': names.unit,
          'campusName': names.campus,
        },
        'observations': ScheduleObservations.compose(d),
        'isLocked': false,
        'createdAt': now,
        'createdBy': _uid,
      })
      ..set(event, {
        'type': 'DECLARACION_CREADA',
        'userId': _uid,
        'timestamp': now,
        'version': 1,
        'newStatus': DeclarationStatus.draft.value,
      })
      ..set(
        _firestore.collection('declarationSlots').doc('${periodId}_$_uid'),
        {'declarationId': ref.id},
      );
    _addContent(
      batch,
      version,
      d,
      period: period!,
      workplace: names.workplace,
      appointmentId: null,
      externalJobIds: const [],
    );
    await batch.commit();
    d
      ..id = ref.id
      ..versionId = version.id
      ..versionNumber = 1;
  }

  /// Writes the content of an existing declaration. A VALIDADA one goes
  /// back to BORRADOR first, as editing it does in the web. Returns `false`
  /// when there was nothing to write (a VALIDADA declaration validated
  /// again without changes).
  Future<bool> _update(Declaration d, String id) async {
    final stored = (await _declarations.doc(id).get(_fromServer)).data();
    if (stored == null || stored['declarantUid'] != _uid) {
      throw const DeclarationSaveException('La declaración ya no existe.');
    }
    final status = DeclarationStatus.fromValue(stored['status'] as String);
    if (status == DeclarationStatus.validated &&
        d.status == DeclarationStatus.validated) {
      return false;
    }
    if (status == DeclarationStatus.validated ||
        status == DeclarationStatus.pendingDeclarantSignature) {
      await _transition(
        id,
        from: status,
        to: DeclarationStatus.draft,
        event: 'HORARIO_MODIFICADO',
      );
    } else if (status != DeclarationStatus.draft) {
      throw DeclarationSaveException(
        'La declaración está «${status.label}»: ya no se puede editar desde '
        'el teléfono.',
      );
    }

    final versionRef = _declarations
        .doc(id)
        .collection('versions')
        .doc(stored['currentVersionId'] as String);
    final (versionDoc, appointments, jobs, periodDoc, userDoc) = await (
      versionRef.get(),
      versionRef.collection('appointments').get(),
      versionRef.collection('externalJobs').get(),
      _firestore.collection('periods').doc(stored['periodId'] as String).get(),
      _firestore.collection('users').doc(_uid).get(),
    ).wait;
    final snapshot = Map<String, dynamic>.from(
      versionDoc.data()?['declarantSnapshot'] as Map? ?? const {},
    );
    // An unsigned draft carries the profile as it is now: the person may
    // have corrected their name, cédula or phone (U-07).
    final user = userDoc.data();
    final batch = _firestore.batch()
      ..update(versionRef, {
        'observations': ScheduleObservations.compose(d),
        if (user != null)
          'declarantSnapshot': {
            ...snapshot,
            for (final key in const ['fullName', 'identification', 'phone'])
              if (user[key] is String) key: user[key],
          },
      });
    _addContent(
      batch,
      versionRef,
      d,
      period: periodDoc.data()!,
      workplace: _workplaceOf(
        snapshot['campusName'] as String? ?? '',
        snapshot['unitName'] as String? ?? '',
      ),
      // The mobile app edits the first appointment; any other one made in
      // the web is kept as it is.
      appointmentId: appointments.docs.isEmpty
          ? null
          : appointments.docs.first.id,
      externalJobIds: [for (final doc in jobs.docs) doc.id],
    );
    await batch.commit();
    return true;
  }

  /// The appointment (UCR blocks and projects) and the external jobs of
  /// [d], with the validity of the period, as the rules require.
  void _addContent(
    WriteBatch batch,
    DocumentReference<Map<String, dynamic>> version,
    Declaration d, {
    required Map<String, dynamic> period,
    required String workplace,
    required String? appointmentId,
    required List<String> externalJobIds,
  }) {
    // The exact stored values: the rules compare them with the period.
    final dates = {
      'startDate': period['startDate'],
      'endDate': period['endDate'],
    };
    final appointments = version.collection('appointments');
    batch.set(
      appointmentId == null
          ? appointments.doc()
          : appointments.doc(appointmentId),
      {
        'workplace': workplace,
        'position': d.position,
        'workload':
            WorkloadCatalog.labelFor(d.coursesMinutes) ??
            TimeRules.hoursLabel(d.universityMinutes),
        ...dates,
        'blocks': [
          for (final i in d.sortedIntervals)
            if (i.task.kind != TaskKind.external) _block(i),
        ],
        if (d.projects.isNotEmpty)
          'projects': [
            for (final p in d.projects)
              {'name': p.name, 'weeklyMinutes': p.weeklyMinutes},
          ],
      },
    );
    final jobs = version.collection('externalJobs');
    for (final (index, job) in d.externalJobs.indexed) {
      final ref = index < externalJobIds.length
          ? jobs.doc(externalJobIds[index])
          : jobs.doc();
      batch.set(ref, {
        'institution': job.institution,
        'institutionType': job.type.value,
        'position': job.position,
        'workload': WorkloadCatalog.labelFor(job.weeklyMinutes) ?? '',
        'weeklyMinutes': job.weeklyMinutes,
        ...dates,
        'blocks': [
          for (final i in d.sortedIntervals)
            if (i.task.kind == TaskKind.external &&
                i.task.name == job.institution)
              _block(i),
        ],
      });
    }
    for (final extra in externalJobIds.skip(d.externalJobs.length)) {
      batch.delete(jobs.doc(extra));
    }
  }

  /// A block of the Proyecto 1: lessons, attention and planning carry their
  /// category and course; a project block only its name.
  static Map<String, Object> _block(ScheduleInterval i) => {
    'day': i.day.number,
    'startMinutes': i.startMinutes,
    'endMinutes': i.endMinutes,
    'category': ?_categoryOf[i.task.kind],
    if (i.task.kind != TaskKind.external) 'course': i.task.name,
  };

  static final Map<TaskKind, String> _categoryOf = {
    for (final MapEntry(:key, :value) in Proyecto1Mapper.categories.entries)
      value: key,
  };

  /// A status change of the declarant, as `_transition` of DeclaraHorario:
  /// in one transaction, the declaration gets the new status and points to
  /// a new audit event recording where it came from.
  Future<void> _transition(
    String id, {
    required DeclarationStatus from,
    required DeclarationStatus to,
    required String event,
    Map<String, Object> versionChanges = const {},
  }) => _firestore.runTransaction((tx) async {
    final ref = _declarations.doc(id);
    final data = (await tx.get(ref)).data();
    if (data == null || data['status'] != from.value) {
      throw const DeclarationSaveException(
        'La declaración cambió mientras la editaba. Vuelva a abrirla.',
      );
    }
    final eventRef = ref.collection('events').doc();
    final now = FieldValue.serverTimestamp();
    tx
      ..set(eventRef, {
        'type': event,
        'userId': _uid,
        'timestamp': now,
        'version': data['currentVersionNumber'],
        'previousStatus': from.value,
        'newStatus': to.value,
      })
      ..update(ref, {
        'status': to.value,
        'lastEventId': eventRef.id,
        'updatedAt': now,
        'currentResponsibleUid': _uid,
        'currentResponsibleRole': UserRole.declarant.value,
      });
    if (versionChanges.isNotEmpty) {
      tx.update(
        ref.collection('versions').doc(data['currentVersionId'] as String),
        versionChanges,
      );
    }
  });

  /// Expected hours at the university (courses and projects) against the
  /// hours placed there, as `HoursCalculator` of DeclaraHorario.
  static Map<String, int> _hoursSummary(Declaration d) {
    final declared = d.intervals
        .where((i) => i.task.kind != TaskKind.external)
        .fold(0, (total, i) => total + i.durationMinutes);
    return {
      'expectedMinutes': d.universityMinutes,
      'declaredMinutes': declared,
      'differenceMinutes': declared - d.universityMinutes,
    };
  }

  Future<({String campus, String unit, String workplace})> _workplaceNames(
    UserProfile profile,
  ) async {
    Future<String> nameOf(String collection, String? id) async {
      if (id == null) return '';
      final data = (await _firestore.collection(collection).doc(id).get())
          .data();
      return data?['name'] as String? ?? '';
    }

    final (campus, unit) = await (
      nameOf('campuses', profile.campusId),
      nameOf('units', profile.unitId),
    ).wait;
    return (campus: campus, unit: unit, workplace: _workplaceOf(campus, unit));
  }

  /// "Universidad de Costa Rica · {sede} · {carrera}", as
  /// `AppointmentDefaults.workplaceOf` of DeclaraHorario.
  static String _workplaceOf(String campus, String unit) => [
    Workplace.institution,
    campus.trim(),
    unit.trim(),
  ].where((part) => part.isNotEmpty).join(' · ');
}

/// Periods and assignments read once per list, however many declarations
/// share them.
class _Lookups {
  _Lookups(this._repository);

  final PeriodRepository _repository;
  final _periods = <String, Future<Period?>>{};
  final _assignments = <String, Future<WorkloadAssignment?>>{};

  Future<Period?> period(String id) =>
      _periods.putIfAbsent(id, () => _repository.getById(id));

  Future<WorkloadAssignment?> assignment(String periodId) => _assignments
      .putIfAbsent(periodId, () => _repository.assignmentFor(periodId));
}
