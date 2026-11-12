import 'package:declara_ucr/domain/schedule_slot.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/validation_issue.dart';

/// Overlap detection (section 7.1, HU-10 and HU-11). Member B.
///
/// Pure Dart: no dependency on Flutter or Firebase, tested with `flutter test`.
class OverlapDetector {
  /// Stateless: everything comes from the blocks passed to each check.
  const OverlapDetector();

  /// Returns one [ValidationIssue] per conflict, with the day, the intervals
  /// and the exact conflict time. Code `internalOverlap` if both slots belong
  /// to appointments; `externalOverlap` if an external job is involved.
  ///
  /// Example: 13:00-17:00 vs 16:00-20:00 -> conflict 16:00-17:00.
  List<ValidationIssue> findConflicts(List<ScheduleSlot> slots) {
    final issues = <ValidationIssue>[];
    // Compare every pair of slots exactly once.
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final issue = _compare(slots[i], slots[j]);
        if (issue != null) {
          issues.add(issue);
        }
      }
    }
    return issues;
  }

  ValidationIssue? _compare(ScheduleSlot a, ScheduleSlot b) {
    // Different days can never conflict.
    if (a.day != b.day) {
      return null;
    }
    // Doubt 13: only slots whose validity periods coincide are compared.
    if (!_validityOverlaps(a, b)) {
      return null;
    }
    final minutes = TimeRules.overlapMinutes(
      startA: a.startMinutes,
      endA: a.endMinutes,
      startB: b.startMinutes,
      endB: b.endMinutes,
    );
    // Doubt 12: adjacent intervals return 0, so they are not a conflict.
    if (minutes == 0) {
      return null;
    }
    // The conflict starts at the later start; its length is [minutes].
    final conflictStart = a.startMinutes > b.startMinutes
        ? a.startMinutes
        : b.startMinutes;
    final conflictEnd = conflictStart + minutes;

    final bothAppointments =
        a.origin == SlotOrigin.appointment &&
        b.origin == SlotOrigin.appointment;

    return ValidationIssue(
      code: bothAppointments
          ? ValidationIssueCode.internalOverlap
          : ValidationIssueCode.externalOverlap,
      severity: ValidationSeverity.blocking,
      message:
          'Traslape el ${a.day.label} entre "${a.label}" '
          '(${TimeRules.format(a.startMinutes)}-${TimeRules.format(a.endMinutes)}) '
          'y "${b.label}" '
          '(${TimeRules.format(b.startMinutes)}-${TimeRules.format(b.endMinutes)}): '
          '${TimeRules.format(conflictStart)}-${TimeRules.format(conflictEnd)} '
          '($minutes min).',
      day: a.day,
      conflictStartMinutes: conflictStart,
      conflictEndMinutes: conflictEnd,
      relatedItemIds: <String>[a.itemId, b.itemId],
    );
  }

  /// True if the two validity periods share at least one day.
  bool _validityOverlaps(ScheduleSlot a, ScheduleSlot b) =>
      !a.startDate.isAfter(b.endDate) && !b.startDate.isAfter(a.endDate);
}
