import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// Converts [Declaration]s to and from Firestore documents. Keeps Firestore
/// types (such as [Timestamp]) out of the model layer.
///
/// Stored documents are untrusted input: [fromMap] checks every type and
/// throws a [FormatException] instead of building a half-valid object.
class DeclarationMapper {
  const DeclarationMapper();

  Map<String, dynamic> toMap(Declaration d) => <String, dynamic>{
    'declarantName': d.declarantName,
    'identification': d.identification,
    'institution': d.institution,
    'position': d.position,
    'appointmentType': d.appointmentType,
    'validFrom': _toTimestamp(d.validFrom),
    'validTo': _toTimestamp(d.validTo),
    'courses': [
      for (final c in d.courses)
        {'name': c.name, 'code': c.code, 'workloadMinutes': c.workloadMinutes},
    ],
    'projects': [
      for (final p in d.projects)
        {'name': p.name, 'weeklyMinutes': p.weeklyMinutes},
    ],
    'externalJobs': [
      for (final j in d.externalJobs)
        {
          'institution': j.institution,
          'type': j.type.value,
          'position': j.position,
          'weeklyMinutes': j.weeklyMinutes,
        },
    ],
    'notes': d.notes,
    // Written from the schedule, so other systems read it as the form shows.
    'observations': ScheduleObservations.compose(d),
    'intervals': d.intervals.map(_intervalToMap).toList(),
    'status': d.status.value,
    'updatedAt': _toTimestamp(d.updatedAt),
  };

  Declaration fromMap(String id, Map<String, dynamic> map) {
    try {
      return Declaration(
        id: id,
        declarantName: map['declarantName'] as String? ?? '',
        identification: map['identification'] as String? ?? '',
        position: map['position'] as String? ?? '',
        appointmentType: map['appointmentType'] as String?,
        validFrom: (map['validFrom'] as Timestamp?)?.toDate(),
        validTo: (map['validTo'] as Timestamp?)?.toDate(),
        courses: [
          for (final c in _list(map['courses']))
            CourseLoad(
              name: c['name'] as String,
              code: c['code'] as String? ?? '',
              workloadMinutes: c['workloadMinutes'] as int,
            ),
        ],
        projects: [
          for (final p in _list(map['projects']))
            ProjectHours(
              name: p['name'] as String,
              weeklyMinutes: p['weeklyMinutes'] as int,
            ),
        ],
        externalJobs: [
          for (final j in _list(map['externalJobs']))
            ExternalJob(
              institution: j['institution'] as String,
              type: InstitutionType.fromValue(j['type'] as String),
              position: j['position'] as String,
              weeklyMinutes: j['weeklyMinutes'] as int,
            ),
        ],
        notes: map['notes'] as String? ?? '',
        intervals: _list(map['intervals']).map(_intervalFromMap).toList(),
        status: DeclarationStatus.fromValue(
          map['status'] as String? ?? DeclarationStatus.draft.value,
        ),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed declaration $id: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed declaration $id: ${e.message}');
    }
  }

  static List<Map<String, dynamic>> _list(Object? value) => [
    for (final e in value as List<dynamic>? ?? const <dynamic>[])
      Map<String, dynamic>.from(e as Map),
  ];

  Map<String, dynamic> _intervalToMap(ScheduleInterval i) => <String, dynamic>{
    'id': i.id,
    'day': i.day.number,
    'startMinutes': i.startMinutes,
    'endMinutes': i.endMinutes,
    'kind': i.task.kind.code,
    'name': i.task.name,
  };

  ScheduleInterval _intervalFromMap(Map<String, dynamic> map) =>
      ScheduleInterval(
        id: map['id'] as String,
        day: Weekday.fromNumber(map['day'] as int),
        startMinutes: map['startMinutes'] as int,
        endMinutes: map['endMinutes'] as int,
        // Drafts saved before tasks only had an institution.
        task: map['kind'] == null
            ? ScheduleTask(
                TaskKind.external,
                map['institution'] as String? ?? '',
              )
            : ScheduleTask(
                TaskKind.fromCode(map['kind'] as String),
                map['name'] as String,
              ),
      );

  static Timestamp? _toTimestamp(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);
}
