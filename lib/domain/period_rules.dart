/// Validity period rules, reused from DeclaraHorario (`PeriodRules`): a
/// period lasts at least one calendar month. Pure Dart.
abstract final class PeriodRules {
  /// [date] one calendar month later, on the same day or on the last day of
  /// a shorter month (31 Jan -> 28 Feb).
  static DateTime addOneMonth(DateTime date) {
    final year = date.month == 12 ? date.year + 1 : date.year;
    final month = date.month == 12 ? 1 : date.month + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  /// The earliest end allowed for a period starting on [start].
  static DateTime minEnd(DateTime start) =>
      addOneMonth(DateTime(start.year, start.month, start.day));

  /// Whether [start]..[end] lasts at least one calendar month.
  static bool lastsOneMonth(DateTime start, DateTime end) =>
      !DateTime(end.year, end.month, end.day).isBefore(minEnd(start));
}
