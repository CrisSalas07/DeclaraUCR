import 'package:declara_ucr/domain/course_rules.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/overlap_detector.dart';
import 'package:declara_ucr/domain/period_rules.dart';
import 'package:declara_ucr/domain/schedule_grid.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/domain/schedule_requirements.dart';
import 'package:declara_ucr/domain/schedule_slot.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// Validation of the mobile declaration (R2 and R4). Pure Dart; the overlap
/// rule is the `OverlapDetector` reused from DeclaraHorario.
///
/// Messages are user-facing, so they are in Spanish.
class DeclarationValidator {
  const DeclarationValidator({this.overlapDetector = const OverlapDetector()});

  final OverlapDetector overlapDetector;

  /// Labels of the required fields that are still empty (R2, test 03).
  /// Name and identification come from the profile.
  List<String> missingFields(Declaration d) => <String>[
    if (d.declarantName.trim().isEmpty) 'Nombre de la persona declarante',
    if (d.identification.trim().isEmpty) 'Cédula',
    if (d.position.trim().isEmpty) 'Puesto',
    if (d.appointmentType == null) 'Tipo de nombramiento',
    if (d.validFrom == null) 'Inicio de vigencia',
    if (d.validTo == null) 'Fin de vigencia',
    if (d.courses.isEmpty && d.projects.isEmpty) 'Cursos o proyectos',
  ];

  static ValidationIssue _blocking(
    String message, [
    ValidationIssueCode code = ValidationIssueCode.invalidField,
  ]) => ValidationIssue(
    code: code,
    severity: ValidationSeverity.blocking,
    message: message,
  );

  /// Format and length problems of the filled-in fields: the authoritative
  /// check, since data may come from storage or another client.
  List<ValidationIssue> fieldIssues(Declaration d) => [
    if (d.identification.trim().isNotEmpty &&
        !FieldRules.isValidIdentification(d.identification))
      _blocking('La cédula debe tener 9 dígitos, sin guiones.'),
    if (d.declarantName.length > FieldRules.nameMaxLength)
      _blocking('El nombre supera ${FieldRules.nameMaxLength} caracteres.'),
    if (d.position.isNotEmpty && !Positions.university.contains(d.position))
      _blocking('Elija el puesto de la lista.'),
    if (d.appointmentType != null &&
        !appointmentTypes.contains(d.appointmentType))
      _blocking('Elija el tipo de nombramiento de la lista.'),
    if (d.notes.length > FieldRules.notesMaxLength)
      _blocking(
        'Las otras observaciones superan '
        '${FieldRules.notesMaxLength} caracteres.',
      ),
    if (ScheduleObservations.compose(d).length >
        FieldRules.observationsMaxLength)
      _blocking('Las observaciones son demasiado largas.'),
    if (d.intervals.length > FieldRules.maxIntervals)
      _blocking(
        'El horario admite como máximo ${FieldRules.maxIntervals} bloques.',
      ),
    if (CourseRules.validateAll(d.courses, d.projects, d.externalJobs)
        case final problem?)
      _blocking(problem, ValidationIssueCode.workloadMismatch),
  ];

  /// Validity, schedule and hours problems (R4). All of them block.
  List<ValidationIssue> scheduleIssues(Declaration d) {
    final issues = <ValidationIssue>[];

    if (d.validFrom != null &&
        d.validTo != null &&
        !PeriodRules.lastsOneMonth(d.validFrom!, d.validTo!)) {
      issues.add(
        _blocking(
          'El período de vigencia debe durar al menos un mes: el fin debe ser '
          'el ${_date(PeriodRules.minEnd(d.validFrom!))} o después.',
          ValidationIssueCode.invalidTimeRange,
        ),
      );
    }

    if (d.intervals.isEmpty) {
      issues.add(
        _blocking(
          'Ubique sus horas en el horario semanal.',
          ValidationIssueCode.emptySchedule,
        ),
      );
      return issues;
    }

    final validSlots = <ScheduleSlot>[];
    for (final interval in d.intervals) {
      final label = ScheduleRequirements.describe(interval.task, d);
      if (!TimeRules.isValidRange(interval.startMinutes, interval.endMinutes)) {
        issues.add(
          ValidationIssue(
            code: ValidationIssueCode.invalidTimeRange,
            severity: ValidationSeverity.blocking,
            message:
                'El ${interval.day.label}, $label: la hora de finalización '
                '(${TimeRules.shortClock(interval.endMinutes)}) debe ser '
                'posterior a la de inicio '
                '(${TimeRules.shortClock(interval.startMinutes)}).',
            day: interval.day,
            relatedItemIds: <String>[interval.id],
          ),
        );
        continue;
      }
      validSlots.add(
        ScheduleSlot(
          itemId: interval.id,
          label: label,
          // Hours at other institutions overlap-block all the same (R4).
          origin: interval.task.kind == TaskKind.external
              ? SlotOrigin.externalJob
              : SlotOrigin.appointment,
          day: interval.day,
          startMinutes: interval.startMinutes,
          endMinutes: interval.endMinutes,
          // Every interval shares the validity period of the declaration.
          startDate: DateTime(2000),
          endDate: DateTime(2100),
        ),
      );
    }
    issues.addAll(overlapDetector.findConflicts(validSlots));

    for (final day in ScheduleGrid.days) {
      final minutes = d.intervals
          .where((i) => i.day == day)
          .fold(0, (total, i) => total + i.durationMinutes);
      if (minutes > ScheduleGrid.maxDailyMinutes) {
        issues.add(
          _blocking(
            'El ${day.label} tiene ${TimeRules.hoursLabel(minutes)}: el máximo '
            'es ${TimeRules.hoursLabel(ScheduleGrid.maxDailyMinutes)} al día.',
            ValidationIssueCode.maxDailyHoursExceeded,
          ),
        );
      }
    }

    for (final message in ScheduleRequirements.problems(d)) {
      issues.add(_blocking(message, ValidationIssueCode.categoryIncomplete));
    }
    return issues;
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Every blocking problem except missing fields: fields first, then the
  /// schedule.
  List<ValidationIssue> issues(Declaration d) => <ValidationIssue>[
    ...fieldIssues(d),
    ...scheduleIssues(d),
  ];

  /// The declaration may become VALIDADA only with no missing fields and no
  /// problems.
  bool isValid(Declaration d) => missingFields(d).isEmpty && issues(d).isEmpty;
}
