import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/period.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// Reads the Proyecto 1 (DeclaraHorario) documents into the models of this
/// app. Field names follow `docs/MODELO_FIRESTORE.md` of DeclaraHorario; the
/// mapping is explained in `docs/COMPARACION_BACKEND_P1.md`.
///
/// Stored documents are untrusted: a missing or mistyped required field
/// throws a [FormatException] instead of building a half-valid object.
abstract final class Proyecto1Mapper {
  /// Hour categories of `blocks[].category`.
  static const Map<String, TaskKind> categories = {
    'lesson': TaskKind.lesson,
    'attention': TaskKind.attention,
    'planning': TaskKind.planning,
  };

  static Period period(String id, Map<String, dynamic> map) => _guard(
    'period $id',
    () => Period(
      id: id,
      name: map['name'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      enabled: map['enabled'] == true,
    ),
  );

  static WorkloadAssignment assignment(Map<String, dynamic> map) => _guard(
    'assignment',
    () => WorkloadAssignment(
      periodId: map['periodId'] as String,
      courses: [
        for (final c in _maps(map['courses']))
          CourseLoad(
            name: c['name'] as String,
            code: c['code'] as String? ?? '',
            workloadMinutes: c['workloadMinutes'] as int,
            lessonMinutes: c['lessonMinutes'] as int?,
          ),
      ],
      slots: [
        for (final s in _maps(map['slots']))
          LessonSlot(
            day: Weekday.fromNumber(s['day'] as int),
            startMinutes: s['startMinutes'] as int,
            endMinutes: s['endMinutes'] as int,
            course: s['course'] as String? ?? '',
          ),
      ],
    ),
  );

  /// The declaration [id] built from its document, its current [version],
  /// the [appointments] and [externalJobs] of that version, and the
  /// [assignment] and [period] it belongs to (either may be missing).
  static Declaration declaration({
    required String id,
    required Map<String, dynamic> declaration,
    required Map<String, dynamic> version,
    required List<Map<String, dynamic>> appointments,
    required List<Map<String, dynamic>> externalJobs,
    WorkloadAssignment? assignment,
    Period? period,
  }) => _guard('declaration $id', () {
    final snapshot = Map<String, dynamic>.from(
      version['declarantSnapshot'] as Map? ?? const {},
    );
    // The mobile app keeps one appointment: the university one.
    final appointment = appointments.isEmpty ? null : appointments.first;
    final intervals = <ScheduleInterval>[];
    void addBlocks(
      String source,
      Object? blocks,
      ScheduleTask? Function(Map<String, dynamic>) taskOf,
    ) {
      final list = _maps(blocks);
      for (var i = 0; i < list.length; i++) {
        final block = list[i];
        final task = taskOf(block);
        // Blocks this app cannot show (no category nor name) are left out.
        if (task == null) continue;
        intervals.add(
          ScheduleInterval(
            id: '$source-$i',
            day: Weekday.fromNumber(block['day'] as int),
            startMinutes: block['startMinutes'] as int,
            endMinutes: block['endMinutes'] as int,
            task: task,
          ),
        );
      }
    }

    if (appointment != null) {
      addBlocks('a', appointment['blocks'], (block) {
        final course = block['course'] as String? ?? '';
        final kind = categories[block['category']];
        if (kind != null) return ScheduleTask(kind, course);
        // No category and a name: a project block.
        return course.isEmpty ? null : ScheduleTask(TaskKind.project, course);
      });
    }
    final jobs = <ExternalJob>[];
    for (var j = 0; j < externalJobs.length; j++) {
      final job = externalJobs[j];
      final institution = job['institution'] as String;
      jobs.add(
        ExternalJob(
          institution: institution,
          type: InstitutionType.fromValue(job['institutionType'] as String),
          position: job['position'] as String? ?? '',
          weeklyMinutes: job['weeklyMinutes'] as int? ?? 0,
        ),
      );
      addBlocks(
        'e$j',
        job['blocks'],
        (_) => ScheduleTask(TaskKind.external, institution),
      );
    }

    return Declaration(
      id: id,
      declarantName:
          snapshot['fullName'] as String? ??
          declaration['declarantName'] as String? ??
          '',
      identification: snapshot['identification'] as String? ?? '',
      position: appointment?['position'] as String? ?? '',
      appointmentType: appointment?['appointmentType'] as String?,
      validFrom: _date(appointment?['startDate']) ?? period?.startDate,
      validTo: _date(appointment?['endDate']) ?? period?.endDate,
      courses: [...?assignment?.courses],
      projects: [
        for (final p in _maps(appointment?['projects']))
          ProjectHours(
            name: p['name'] as String,
            weeklyMinutes: p['weeklyMinutes'] as int,
          ),
      ],
      externalJobs: jobs,
      notes: notesOf(version['observations'] as String? ?? ''),
      intervals: intervals,
      status: DeclarationStatus.fromValue(declaration['status'] as String),
      updatedAt: _date(declaration['updatedAt']),
      periodId: declaration['periodId'] as String,
      periodName: period?.name,
      versionId: declaration['currentVersionId'] as String,
      versionNumber: declaration['currentVersionNumber'] as int,
      pendingObservation: declaration['pendingObservation'] as String?,
    );
  });

  /// The notes the person typed: what follows the "Otras observaciones"
  /// marker (the rest is written from the schedule).
  static String notesOf(String observations) {
    final at = observations.lastIndexOf(ScheduleObservations.manualMarker);
    return at < 0
        ? ''
        : observations
              .substring(at + ScheduleObservations.manualMarker.length)
              .trim();
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static List<Map<String, dynamic>> _maps(Object? value) => [
    for (final e in value as List<dynamic>? ?? const <dynamic>[])
      Map<String, dynamic>.from(e as Map),
  ];

  static T _guard<T>(String what, T Function() read) {
    try {
      return read();
    } on TypeError catch (e) {
      throw FormatException('Malformed $what: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed $what: ${e.message}');
    }
  }
}
