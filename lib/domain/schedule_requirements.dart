import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';

/// What the schedule must hold, from the courses, projects and other
/// institutions of the declaration (`TeachingSchedule` and
/// `ExternalSchedule` of DeclaraHorario). Pure Dart.
///
/// Every task ends with exactly its hours: lessons, attention and planning
/// of each course, each project and each job at another institution.
abstract final class ScheduleRequirements {
  /// Minutes each task needs, in the order the editor shows them.
  static Map<ScheduleTask, int> requiredMinutes(Declaration d) => {
    for (final course in d.courses) ...{
      ScheduleTask(TaskKind.lesson, course.name): course.lessonMinutes,
      ScheduleTask(TaskKind.attention, course.name): course.attentionMinutes,
      ScheduleTask(TaskKind.planning, course.name): course.planningMinutes,
    },
    for (final project in d.projects)
      ScheduleTask(TaskKind.project, project.name): project.weeklyMinutes,
    for (final job in d.externalJobs)
      ScheduleTask(TaskKind.external, job.institution): job.weeklyMinutes,
  };

  /// Minutes of [task] placed in the schedule.
  static int placedMinutes(Declaration d, ScheduleTask task) => d.intervals
      .where((i) => i.task == task)
      .fold(0, (total, i) => total + i.durationMinutes);

  /// One Spanish message per task whose placed hours differ from what it
  /// needs, plus one per block of a task that is no longer declared.
  static List<String> problems(Declaration d) {
    final required = requiredMinutes(d);
    final messages = <String>[];
    for (final MapEntry(key: task, value: minutes) in required.entries) {
      final placed = placedMinutes(d, task);
      final what = describe(task, d);
      if (placed < minutes) {
        messages.add(
          'Faltan ${TimeRules.hoursLabel(minutes - placed)} de $what en el '
          'horario.',
        );
      } else if (placed > minutes) {
        messages.add(
          'Sobran ${TimeRules.hoursLabel(placed - minutes)} de $what en el '
          'horario.',
        );
      }
    }
    final orphans = {
      for (final i in d.intervals)
        if (!required.containsKey(i.task)) i.task,
    };
    for (final task in orphans) {
      messages.add(
        'El horario tiene horas de ${describe(task, d)}, que ya no está en la '
        'declaración.',
      );
    }
    return messages;
  }

  /// "atención de IF0009", "el proyecto «Huertas»", "«Colegio X»".
  static String describe(ScheduleTask task, Declaration d) {
    final course = d.courses.where((c) => c.name == task.name);
    final name = course.isEmpty ? task.name : course.first.shortName;
    return switch (task.kind) {
      TaskKind.lesson => 'clases de $name',
      TaskKind.attention => 'atención a estudiantes de $name',
      TaskKind.planning => 'planificación de $name',
      TaskKind.project => 'el proyecto «${task.name}»',
      TaskKind.external => '«${task.name}»',
    };
  }
}
