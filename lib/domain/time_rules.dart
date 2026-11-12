/// Time utilities in minutes since midnight: clock times and amounts of
/// time. Member B. Pure Dart.
///
/// The one place that formats them: [hoursLabel] for amounts ("4 h",
/// "2,5 h") and [format] for clock times ("07:30").
class TimeRules {
  const TimeRules._();

  /// 7.2: the end time must be later than the start time.
  static bool isValidRange(int startMinutes, int endMinutes) =>
      endMinutes > startMinutes;

  /// Length of an interval in minutes.
  static int durationMinutes(int startMinutes, int endMinutes) =>
      endMinutes - startMinutes;

  /// Minutes shared by two intervals on the same day (0 if they don't touch).
  /// Doubt 12: do adjacent intervals count as an overlap?
  /// For now they don't: 8-10 and 10-12 return 0.
  static int overlapMinutes({
    required int startA,
    required int endA,
    required int startB,
    required int endB,
  }) {
    // The overlap starts at the later start and ends at the earlier end.
    final start = startA > startB ? startA : startB;
    final end = endA < endB ? endA : endB;
    final overlap = end - start;
    // A negative or zero value means the intervals don't overlap.
    return overlap > 0 ? overlap : 0;
  }

  /// The one format of an amount of time in the app: 240 -> "4 h",
  /// 150 -> "2,5 h", 0 -> "0 h" (decimal comma, at most two decimals).
  /// [format] is only for clock times; "04:00 h" read like one.
  static String hoursLabel(int minutes) {
    final text = (minutes / 60).toStringAsFixed(2);
    final trimmed = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return '${trimmed.replaceAll('.', ',')} h';
  }

  /// Progress between two amounts: (0, 240) -> "0 h de 4 h".
  static String hoursOf(int part, int total) =>
      '${hoursLabel(part)} de ${hoursLabel(total)}';

  /// A clock time as people read it, without a leading zero: 450 ->
  /// "7:30", 600 -> "10:00". For summaries; [format] keeps the fixed width
  /// of the pickers and the grid.
  static String shortClock(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  /// A clock time: 510 -> "08:30". Never an amount of time (see
  /// [hoursLabel]).
  static String format(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  /// "08:30" -> 510. Throws a FormatException if the text is not HH:MM.
  static int parse(String hhmm) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(hhmm)) {
      throw FormatException('Expected HH:MM', hhmm);
    }
    final hours = int.parse(hhmm.substring(0, 2));
    final mins = int.parse(hhmm.substring(3, 5));
    if (hours > 23 || mins > 59) {
      throw FormatException('Time out of range', hhmm);
    }
    return hours * 60 + mins;
  }
}
