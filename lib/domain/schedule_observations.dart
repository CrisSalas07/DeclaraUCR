import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';

/// The observations of a declaration, written from its schedule; reused
/// from DeclaraHorario (`ScheduleObservations`). Pure Dart.
///
/// One line per course, project and job at another institution, in the
/// style of the official form:
///
///     IF0004 HC: L 1 pm a 5 pm, K 1 pm a 5 pm. AE: L 10 am a 12 pm. PyE: M 7 am a 12 pm.
///     Huertas (proyecto): V 2 pm a 4 pm.
///     Colegio X: S 8 am a 12 pm.
///
/// Notes typed by the person go after [manualMarker].
abstract final class ScheduleObservations {
  static const String manualMarker = 'Otras observaciones: ';

  static const Map<Weekday, String> _days = <Weekday, String>{
    Weekday.monday: 'L',
    Weekday.tuesday: 'K',
    Weekday.wednesday: 'M',
    Weekday.thursday: 'J',
    Weekday.friday: 'V',
    Weekday.saturday: 'S',
  };

  /// "1 pm", "7:30 am", "12 pm".
  static String clock(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour < 12 ? 'am' : 'pm';
    final shown = hour % 12 == 0 ? 12 : hour % 12;
    return minute == 0
        ? '$shown $suffix'
        : '$shown:${minute.toString().padLeft(2, '0')} $suffix';
  }

  /// "L 1 pm a 5 pm, K 1 pm a 5 pm", by day and time.
  static String ranges(Iterable<ScheduleInterval> intervals) {
    final ordered = intervals.toList()
      ..sort(
        (a, b) => a.day.number != b.day.number
            ? a.day.number.compareTo(b.day.number)
            : a.startMinutes.compareTo(b.startMinutes),
      );
    return ordered
        .map(
          (i) =>
              '${_days[i.day]} ${clock(i.startMinutes)} a '
              '${clock(i.endMinutes)}',
        )
        .join(', ');
  }

  /// The lines of the schedule: every course (by sigla), then the projects
  /// and the other institutions. Empty parts are left out.
  static String summary(Declaration d) {
    Iterable<ScheduleInterval> of(TaskKind kind, String name) =>
        d.intervals.where((i) => i.task == ScheduleTask(kind, name));
    final lines = <String>[];
    for (final course in d.courses) {
      final parts = [
        for (final kind in [
          TaskKind.lesson,
          TaskKind.attention,
          TaskKind.planning,
        ])
          if (of(kind, course.name).isNotEmpty)
            '${kind.code}: ${ranges(of(kind, course.name))}.',
      ];
      if (parts.isNotEmpty) lines.add('${course.shortName} ${parts.join(' ')}');
    }
    for (final project in d.projects) {
      final own = of(TaskKind.project, project.name);
      if (own.isNotEmpty) {
        lines.add('${project.name} (proyecto): ${ranges(own)}.');
      }
    }
    for (final job in d.externalJobs) {
      final own = of(TaskKind.external, job.institution);
      if (own.isNotEmpty) lines.add('${job.institution}: ${ranges(own)}.');
    }
    return lines.join('\n');
  }

  /// [summary] plus the typed [notes], as stored and shown.
  static String compose(Declaration d) {
    final generated = summary(d);
    final notes = d.notes.trim();
    if (notes.isEmpty) return generated;
    return generated.isEmpty
        ? '$manualMarker$notes'
        : '$generated\n$manualMarker$notes';
  }
}
