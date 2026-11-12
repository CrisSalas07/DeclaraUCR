import 'package:declara_ucr/models/weekday.dart';

/// Severity of a validation finding.
///
/// `blocking` prevents moving on to signing (HU-14). Whether the difference
/// from the workload is blocking or only a warning is pending (doubt 11).
/// `warning` is shown to the person but does not prevent signing.
enum ValidationSeverity {
  /// Must be fixed before signing.
  blocking,

  /// Shown, but signing is allowed.
  warning,
}

/// Codes of the business rules in the assignment (section 7).
enum ValidationIssueCode {
  /// 7.2: the end time must be after the start time.
  invalidTimeRange,

  /// 7.1 / HU-10: overlap between appointment blocks.
  internalOverlap,

  /// 7.1 / HU-11: overlap with schedules at other institutions.
  externalOverlap,

  /// 7.4: excluded time from 12:00 to 13:00.
  excludedHour,

  /// 7.4: maximum of 10 declared hours per day.
  maxDailyHoursExceeded,

  /// 7.3 / HU-13: difference between declared hours and expected workload.
  workloadMismatch,

  /// A block starts before 07:00 or ends after 22:00.
  outsideWorkWindow,

  /// More than 40 weekly hours at the university.
  maxWeeklyHoursExceeded,

  /// More than 20 weekly hours in other institutions ("Otro").
  maxExternalHoursExceeded,

  /// More than 6 continuous hours without a 1-hour break.
  maxContinuousHoursExceeded,

  /// A category has more hours than authorized.
  categoryExceeded,

  /// A category has fewer hours than authorized (schedule incomplete).
  categoryIncomplete,

  /// Declared lesson blocks differ from the slots the coordinator assigned.
  lessonsMismatch,

  /// No appointment has any time block: there are no hours to declare.
  emptySchedule,

  /// A field has an invalid format or exceeds its maximum length.
  invalidField,

  /// The career coordinator has not assigned courses to the teacher in the
  /// period, so there are no authorized hours to declare.
  missingAssignment,

  /// The blocks of a job at another institution do not add up to its
  /// weekly hours.
  externalHoursMismatch,

  /// The blocks of a project do not add up to its weekly hours.
  projectHoursMismatch,
}

/// Validation finding. HU-10 requires identifying the day, the intervals and
/// the exact time of the conflict.
class ValidationIssue {
  /// Creates a finding; the location fields are optional because not every
  /// rule refers to a specific day or interval.
  const ValidationIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.day,
    this.conflictStartMinutes,
    this.conflictEndMinutes,
    this.relatedItemIds = const <String>[],
  });

  /// Rule that produced the finding.
  final ValidationIssueCode code;

  /// Whether the finding blocks signing.
  final ValidationSeverity severity;

  /// Message shown to the person, in Spanish.
  final String message;

  /// Day affected, if the rule is about a single day.
  final Weekday? day;

  /// Start of the exact conflict interval, in minutes since midnight.
  final int? conflictStartMinutes;

  /// End of the exact conflict interval, in minutes since midnight.
  final int? conflictEndMinutes;

  /// Ids of the appointments / external jobs involved.
  final List<String> relatedItemIds;
}
