import 'package:declara_ucr/models/weekday.dart';

/// Where a schedule block comes from.
enum SlotOrigin { appointment, externalJob }

/// "Flattened" block used by the overlap detector: merges the blocks of the
/// appointments and of the other institutions into a single list. Member B.
class ScheduleSlot {
  const ScheduleSlot({
    required this.itemId,
    required this.label,
    required this.origin,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.startDate,
    required this.endDate,
  });

  /// Id of the source appointment or other institution.
  final String itemId;

  /// Human-readable text used in the conflict message (place or institution).
  final String label;
  final SlotOrigin origin;
  final Weekday day;
  final int startMinutes;
  final int endMinutes;

  /// Validity of the appointment (doubt 13: are only coinciding validity
  /// periods compared?).
  final DateTime startDate;
  final DateTime endDate;
}
