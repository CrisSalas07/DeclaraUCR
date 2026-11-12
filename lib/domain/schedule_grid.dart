import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';

/// One 30-minute cell of the weekly grid.
class GridCell {
  const GridCell(this.day, this.startMinutes);

  final Weekday day;

  /// Start in minutes since midnight; it ends [ScheduleGrid.stepMinutes]
  /// later.
  final int startMinutes;

  int get endMinutes => startMinutes + ScheduleGrid.stepMinutes;

  @override
  bool operator ==(Object other) =>
      other is GridCell &&
      other.day == day &&
      other.startMinutes == startMinutes;

  @override
  int get hashCode => Object.hash(day, startMinutes);

  @override
  String toString() => 'GridCell(${day.name}, $startMinutes)';
}

/// The weekly grid, as in DeclaraHorario: Monday to Saturday, 07:00 to
/// 22:00 in 30-minute cells, lunch hour (12:00-13:00) closed and at most 10
/// hours a day. Pure Dart.
///
/// Converts between cells (what the editor paints, each labelled with its
/// [ScheduleTask.key]) and [ScheduleInterval]s (what is stored): contiguous cells
/// with the same label become one interval.
abstract final class ScheduleGrid {
  static const int stepMinutes = 30;
  static const int dayStartMinutes = 7 * 60;
  static const int dayEndMinutes = 22 * 60;
  static const int lunchStartMinutes = 12 * 60;
  static const int lunchEndMinutes = 13 * 60;
  static const int maxDailyMinutes = 10 * 60;

  static const List<Weekday> days = Weekday.values;

  /// Start of every row, 07:00 to 21:30.
  static final List<int> rowStarts = <int>[
    for (var s = dayStartMinutes; s < dayEndMinutes; s += stepMinutes) s,
  ];

  static bool isLunch(int startMinutes) =>
      startMinutes >= lunchStartMinutes && startMinutes < lunchEndMinutes;

  /// Labelled cells of [intervals]. Times off the grid (older data) are
  /// rounded outwards; a later interval wins a shared cell.
  static Map<GridCell, String> cellsOf(List<ScheduleInterval> intervals) => {
    for (final i in intervals)
      for (
        var s = i.startMinutes - i.startMinutes % stepMinutes;
        s < i.endMinutes;
        s += stepMinutes
      )
        GridCell(i.day, s): i.task.key,
  };

  /// Joins contiguous cells with the same label into intervals, sorted by
  /// day and time. [newId] names each interval.
  static List<ScheduleInterval> intervalsOf(
    Map<GridCell, String> cells,
    String Function() newId,
  ) {
    final result = <ScheduleInterval>[];
    for (final day in days) {
      final starts =
          cells.keys
              .where((c) => c.day == day)
              .map((c) => c.startMinutes)
              .toList()
            ..sort();
      var i = 0;
      while (i < starts.length) {
        final label = cells[GridCell(day, starts[i])]!;
        final start = starts[i];
        var end = start + stepMinutes;
        while (i + 1 < starts.length &&
            starts[i + 1] == end &&
            cells[GridCell(day, starts[i + 1])] == label) {
          i++;
          end += stepMinutes;
        }
        result.add(
          ScheduleInterval(
            id: newId(),
            day: day,
            startMinutes: start,
            endMinutes: end,
            task: ScheduleTask.fromKey(label),
          ),
        );
        i++;
      }
    }
    return result;
  }

  static int minutesOn(Weekday day, Map<GridCell, String> cells) =>
      cells.keys.where((c) => c.day == day).length * stepMinutes;
}
