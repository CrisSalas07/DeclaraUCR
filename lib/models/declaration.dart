import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';

/// Workday / appointment types offered by the form (R2). Shown to the user,
/// so the values are in Spanish.
const List<String> workdayTypes = <String>[
  'Tiempo completo',
  'Tres cuartos de tiempo',
  'Medio tiempo',
  'Cuarto de tiempo',
  'Interino',
  'Propiedad',
];

/// One interval of the weekly schedule (R3). Times are minutes since
/// midnight, as in DeclaraHorario (`TimeRules`).
///
/// Pure Dart: persistence details live in the data layer.
class ScheduleInterval {
  ScheduleInterval({
    required this.id,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.institution,
  });

  final String id;
  Weekday day;
  int startMinutes;
  int endMinutes;
  String institution;

  /// Length in minutes; 0 when the range is invalid (end <= start).
  int get durationMinutes =>
      endMinutes > startMinutes ? endMinutes - startMinutes : 0;

  ScheduleInterval copy() => ScheduleInterval(
    id: id,
    day: day,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    institution: institution,
  );
}

/// Sworn declaration of the mobile module (R2 + R3). Mutable: the form
/// edits it in place and the repository saves it as a whole.
class Declaration {
  Declaration({
    this.id,
    this.declarantName = '',
    this.identification = '',
    this.institution = '',
    this.position = '',
    this.workdayType,
    this.validFrom,
    this.validTo,
    this.additionalInstitutions = '',
    this.observations = '',
    List<ScheduleInterval>? intervals,
    this.status = DeclarationStatus.draft,
    this.updatedAt,
  }) : intervals = intervals ?? <ScheduleInterval>[];

  String? id;
  String declarantName;
  String identification;
  String institution;
  String position;
  String? workdayType;
  DateTime? validFrom;
  DateTime? validTo;
  String additionalInstitutions;
  String observations;
  final List<ScheduleInterval> intervals;
  DeclarationStatus status;
  DateTime? updatedAt;

  /// Total registered time in minutes (valid intervals only).
  int get totalMinutes =>
      intervals.fold(0, (total, interval) => total + interval.durationMinutes);

  /// Intervals ordered by day and start time, for read-only views.
  List<ScheduleInterval> get sortedIntervals => [...intervals]
    ..sort((a, b) {
      final byDay = a.day.number.compareTo(b.day.number);
      return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
    });

  /// Deep copy, so the form can edit without touching the home list until
  /// the declaration is saved.
  Declaration copy() => Declaration(
    id: id,
    declarantName: declarantName,
    identification: identification,
    institution: institution,
    position: position,
    workdayType: workdayType,
    validFrom: validFrom,
    validTo: validTo,
    additionalInstitutions: additionalInstitutions,
    observations: observations,
    intervals: intervals.map((i) => i.copy()).toList(),
    status: status,
    updatedAt: updatedAt,
  );
}
