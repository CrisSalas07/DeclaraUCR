import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_mapper.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:flutter/foundation.dart';

/// [DeclarationRepository] over the Proyecto 1 schema, scoped to one
/// declarant: `declarations/{id}` with its current version, the version's
/// appointment and external jobs, plus the period and the coordination's
/// assignment (where the courses come from).
///
/// Reading only, for now: saving and the status changes follow the
/// Proyecto 1 batches and come in the next step of the migration.
class Proyecto1DeclarationRepository implements DeclarationRepository {
  Proyecto1DeclarationRepository(
    this._firestore, {
    required this._uid,
    required this._periods,
  });

  final FirebaseFirestore _firestore;
  final String _uid;
  final PeriodRepository _periods;

  CollectionReference<Map<String, dynamic>> get _declarations =>
      _firestore.collection('declarations');

  /// The declarant's declarations, all statuses, most recent first. The
  /// rules only allow this query filtered by `declarantUid`.
  @override
  Stream<List<Declaration>> watchAll() => _declarations
      .where('declarantUid', isEqualTo: _uid)
      .snapshots()
      .asyncMap((snap) async {
        final context = _Lookups(_periods);
        final items = await Future.wait(
          snap.docs.map((doc) => _tryLoad(doc.id, doc.data(), context)),
        );
        return items.nonNulls.toList()
          ..sort((a, b) => _byDateDesc(a.updatedAt, b.updatedAt));
      });

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

  @override
  Future<String> save(Declaration declaration) => throw UnsupportedError(
    'Saving in the Proyecto 1 schema is the next migration step.',
  );
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
