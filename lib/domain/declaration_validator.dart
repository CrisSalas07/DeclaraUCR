import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/overlap_detector.dart';
import 'package:declara_ucr/domain/schedule_slot.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/validation_issue.dart';

/// Validation of the mobile declaration (R2 and R4). Pure Dart; the overlap
/// rule is the `OverlapDetector` reused from DeclaraHorario.
///
/// Messages are user-facing, so they are in Spanish.
class DeclarationValidator {
  const DeclarationValidator({this.overlapDetector = const OverlapDetector()});

  final OverlapDetector overlapDetector;

  /// Labels of the required fields that are still empty (R2, test 03).
  List<String> missingFields(Declaration d) => <String>[
    if (d.declarantName.trim().isEmpty) 'Nombre de la persona declarante',
    if (d.identification.trim().isEmpty) 'Identificación',
    if (d.institution.trim().isEmpty) 'Institución',
    if (d.position.trim().isEmpty) 'Puesto',
    if (d.workdayType == null) 'Tipo de jornada o nombramiento',
    if (d.validFrom == null) 'Inicio de vigencia',
    if (d.validTo == null) 'Fin de vigencia',
  ];

  /// Format and length problems of the filled-in fields. The form already
  /// limits input, but this is the authoritative check (data may come from
  /// storage or another client).
  List<ValidationIssue> fieldIssues(Declaration d) {
    final messages = <String>[
      if (d.identification.trim().isNotEmpty &&
          !FieldRules.isValidIdentification(d.identification))
        'La identificación solo admite números, letras y guiones '
            '(de 5 a ${FieldRules.identificationMaxLength} caracteres).',
      if (d.declarantName.length > FieldRules.nameMaxLength)
        'El nombre supera ${FieldRules.nameMaxLength} caracteres.',
      if (d.institution.length > FieldRules.institutionMaxLength)
        'La institución supera ${FieldRules.institutionMaxLength} caracteres.',
      if (d.position.length > FieldRules.positionMaxLength)
        'El puesto supera ${FieldRules.positionMaxLength} caracteres.',
      if (d.additionalInstitutions.length >
          FieldRules.additionalInstitutionsMaxLength)
        'Las instituciones adicionales superan '
            '${FieldRules.additionalInstitutionsMaxLength} caracteres.',
      if (d.observations.length > FieldRules.observationsMaxLength)
        'Las observaciones superan '
            '${FieldRules.observationsMaxLength} caracteres.',
      if (d.intervals.length > FieldRules.maxIntervals)
        'El horario admite como máximo ${FieldRules.maxIntervals} intervalos.',
    ];
    return messages
        .map(
          (message) => ValidationIssue(
            code: ValidationIssueCode.invalidField,
            severity: ValidationSeverity.blocking,
            message: message,
          ),
        )
        .toList();
  }

  /// Schedule and validity problems (R4). All of them block validation.
  List<ValidationIssue> scheduleIssues(Declaration d) {
    final issues = <ValidationIssue>[];

    if (d.validFrom != null &&
        d.validTo != null &&
        d.validTo!.isBefore(d.validFrom!)) {
      issues.add(
        const ValidationIssue(
          code: ValidationIssueCode.invalidTimeRange,
          severity: ValidationSeverity.blocking,
          message: 'El fin de la vigencia es anterior a su inicio.',
        ),
      );
    }

    if (d.intervals.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: ValidationIssueCode.emptySchedule,
          severity: ValidationSeverity.blocking,
          message: 'Registre al menos un intervalo en el horario semanal.',
        ),
      );
      return issues;
    }

    final validSlots = <ScheduleSlot>[];
    for (final interval in d.intervals) {
      final label = interval.institution.trim().isEmpty
          ? 'Sin institución'
          : interval.institution.trim();
      if (!TimeRules.isValidRange(interval.startMinutes, interval.endMinutes)) {
        issues.add(
          ValidationIssue(
            code: ValidationIssueCode.invalidTimeRange,
            severity: ValidationSeverity.blocking,
            message:
                'El ${interval.day.label}, "$label": la hora de '
                'finalización (${TimeRules.shortClock(interval.endMinutes)}) '
                'debe ser posterior a la de inicio '
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
          // An institution other than the main one counts as external, but
          // the overlap blocks all the same (R4).
          origin: label == d.institution.trim()
              ? SlotOrigin.appointment
              : SlotOrigin.externalJob,
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
    return issues;
  }

  /// Every blocking problem except missing fields: field format first, then
  /// the schedule.
  List<ValidationIssue> issues(Declaration d) => <ValidationIssue>[
    ...fieldIssues(d),
    ...scheduleIssues(d),
  ];

  /// The declaration may become VALIDADA only with no missing fields and no
  /// problems.
  bool isValid(Declaration d) => missingFields(d).isEmpty && issues(d).isEmpty;
}
