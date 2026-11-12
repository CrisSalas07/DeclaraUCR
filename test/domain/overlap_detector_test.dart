import 'package:declara_ucr/domain/overlap_detector.dart';
import 'package:declara_ucr/domain/schedule_slot.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to build slots with short code. Defaults: first weekday, full year.
ScheduleSlot slot({
  required String id,
  required int start,
  required int end,
  SlotOrigin origin = SlotOrigin.appointment,
  Weekday? day,
  DateTime? startDate,
  DateTime? endDate,
}) => ScheduleSlot(
  itemId: id,
  label: 'Item $id',
  origin: origin,
  day: day ?? Weekday.values.first,
  startMinutes: start,
  endMinutes: end,
  startDate: startDate ?? DateTime(2026, 1, 1),
  endDate: endDate ?? DateTime(2026, 12, 31),
);

void main() {
  const detector = OverlapDetector();

  group('OverlapDetector', () {
    test('13:00-17:00 vs 16:00-20:00 produces conflict 16:00-17:00', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 780, end: 1020),
        slot(id: 'b', start: 960, end: 1200),
      ]);

      expect(issues, hasLength(1));
      expect(issues.first.conflictStartMinutes, 960);
      expect(issues.first.conflictEndMinutes, 1020);
      expect(issues.first.severity, ValidationSeverity.blocking);
      expect(issues.first.relatedItemIds, ['a', 'b']);
    });

    test('slots on different days do not conflict', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 780, end: 1020, day: Weekday.values[0]),
        slot(id: 'b', start: 960, end: 1200, day: Weekday.values[1]),
      ]);

      expect(issues, isEmpty);
    });

    test('separated slots on the same day do not conflict', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 480, end: 600),
        slot(id: 'b', start: 780, end: 900),
      ]);

      expect(issues, isEmpty);
    });

    test('two appointments -> internalOverlap', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 780, end: 1020),
        slot(id: 'b', start: 960, end: 1200),
      ]);

      expect(issues.single.code, ValidationIssueCode.internalOverlap);
    });

    test('appointment + external job -> externalOverlap', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 780, end: 1020),
        slot(id: 'b', start: 960, end: 1200, origin: SlotOrigin.externalJob),
      ]);

      expect(issues.single.code, ValidationIssueCode.externalOverlap);
    });

    test('adjacent slots do not conflict (doubt 12, pending)', () {
      final issues = detector.findConflicts([
        slot(id: 'a', start: 480, end: 600),
        slot(id: 'b', start: 600, end: 720),
      ]);

      expect(issues, isEmpty);
    });

    test(
      'validity periods that do not coincide do not conflict (doubt 13)',
      () {
        final issues = detector.findConflicts([
          slot(
            id: 'a',
            start: 780,
            end: 1020,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 6, 30),
          ),
          slot(
            id: 'b',
            start: 960,
            end: 1200,
            startDate: DateTime(2026, 7, 1),
            endDate: DateTime(2026, 12, 31),
          ),
        ]);

        expect(issues, isEmpty);
      },
    );
  });
}
