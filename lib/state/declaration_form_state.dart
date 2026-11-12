import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/course_rules.dart';
import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/schedule_grid.dart';
import 'package:declara_ucr/domain/schedule_requirements.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:flutter/foundation.dart';

/// State of the form and the summary of one declaration (R2, R3, R4, R6).
///
/// Depends on abstractions injected through the constructor (repository and
/// validator), so it can be tested without Firebase.
class DeclarationFormState extends ChangeNotifier {
  DeclarationFormState({
    required this._repository,
    this._validator = const DeclarationValidator(),
    Declaration? initial,
    UserProfile? profile,
  }) : declaration = initial?.copy() ?? Declaration() {
    // The profile is the source of the name and cédula: never typed here.
    if (profile != null) {
      declaration
        ..declarantName = profile.name
        ..identification = profile.identification;
    }
  }

  final DeclarationRepository _repository;
  final DeclarationValidator _validator;
  final Declaration declaration;

  bool saving = false;

  /// User-facing message of the last failed save, in Spanish.
  String? error;
  int _nextId = 0;

  List<String> get missingFields => _validator.missingFields(declaration);

  /// How many required fields the form has (all missing on an empty one).
  int get requiredFieldCount => _validator.missingFields(Declaration()).length;
  List<ValidationIssue> get issues => _validator.issues(declaration);
  bool get canValidate => _validator.isValid(declaration);

  /// Applies a change. As in DeclaraHorario, editing a VALIDADA declaration
  /// sends it back to BORRADOR until it is validated again.
  void edit(void Function(Declaration d) change) {
    change(declaration);
    if (declaration.status == DeclarationStatus.validated) {
      declaration.status = DeclarationStatus.draft;
    }
    notifyListeners();
  }

  // ---- Courses, projects and other institutions ---------------------------

  /// Adds [course], or replaces the one at [index]. Its blocks follow a new
  /// name; a smaller workday leaves the extra hours to remove (the
  /// validation says how many). Returns why it was not saved, in Spanish.
  String? saveCourse(CourseLoad course, {int? index}) {
    final d = declaration;
    final courses = [...d.courses];
    if (index == null) {
      if (courses.length >= FieldRules.maxCourses) {
        return 'Puede agregar como máximo ${FieldRules.maxCourses} cursos.';
      }
      courses.add(course);
    } else {
      courses[index] = course;
    }
    final problem = CourseRules.validateAll(
      courses,
      d.projects,
      d.externalJobs,
    );
    if (problem != null) return problem;
    edit((d) {
      if (index != null) {
        final old = d.courses[index].name;
        for (final kind in [
          TaskKind.lesson,
          TaskKind.attention,
          TaskKind.planning,
        ]) {
          _renameTask(
            d,
            ScheduleTask(kind, old),
            ScheduleTask(kind, course.name),
          );
        }
      }
      d.courses
        ..clear()
        ..addAll(courses);
    });
    return null;
  }

  /// Removes the course at [index] and its blocks.
  void removeCourse(int index) => edit((d) {
    final name = d.courses.removeAt(index).name;
    d.intervals.removeWhere((i) => i.task.kind.isCourse && i.task.name == name);
  });

  String? saveProject(ProjectHours project, {int? index}) {
    final d = declaration;
    final projects = [...d.projects];
    if (index == null) {
      if (projects.length >= FieldRules.maxProjects) {
        return 'Puede agregar como máximo ${FieldRules.maxProjects} proyectos.';
      }
      projects.add(project);
    } else {
      projects[index] = project;
    }
    final problem = CourseRules.validateAll(
      d.courses,
      projects,
      d.externalJobs,
    );
    if (problem != null) return problem;
    edit((d) {
      if (index != null) {
        _renameTask(
          d,
          ScheduleTask(TaskKind.project, d.projects[index].name),
          ScheduleTask(TaskKind.project, project.name),
        );
      }
      d.projects
        ..clear()
        ..addAll(projects);
    });
    return null;
  }

  void removeProject(int index) => edit((d) {
    final task = ScheduleTask(
      TaskKind.project,
      d.projects.removeAt(index).name,
    );
    d.intervals.removeWhere((i) => i.task == task);
  });

  String? saveExternalJob(ExternalJob job, {int? index}) {
    final d = declaration;
    final jobs = [...d.externalJobs];
    if (index == null) {
      if (jobs.length >= FieldRules.maxExternalJobs) {
        return 'Puede agregar como máximo ${FieldRules.maxExternalJobs} '
            'instituciones.';
      }
      jobs.add(job);
    } else {
      jobs[index] = job;
    }
    final problem = CourseRules.validateAll(d.courses, d.projects, jobs);
    if (problem != null) return problem;
    edit((d) {
      if (index != null) {
        _renameTask(
          d,
          ScheduleTask(TaskKind.external, d.externalJobs[index].institution),
          ScheduleTask(TaskKind.external, job.institution),
        );
      }
      d.externalJobs
        ..clear()
        ..addAll(jobs);
    });
    return null;
  }

  void removeExternalJob(int index) => edit((d) {
    final task = ScheduleTask(
      TaskKind.external,
      d.externalJobs.removeAt(index).institution,
    );
    d.intervals.removeWhere((i) => i.task == task);
  });

  static void _renameTask(Declaration d, ScheduleTask from, ScheduleTask to) {
    if (from == to) return;
    for (final interval in d.intervals) {
      if (interval.task == from) interval.task = to;
    }
  }

  // ---- Schedule -----------------------------------------------------------

  /// Places [task] on [cells], or frees them when it is `null`. Lunch cells
  /// are skipped. Returns why nothing changed (in Spanish), or `null`.
  String? paint(Iterable<GridCell> cells, ScheduleTask? task) {
    final current = ScheduleGrid.cellsOf(declaration.intervals);
    final next = Map<GridCell, String>.of(current);
    for (final cell in cells) {
      if (ScheduleGrid.isLunch(cell.startMinutes)) continue;
      if (task == null) {
        next.remove(cell);
      } else {
        next[cell] = task.key;
      }
    }
    return _commit(current, next);
  }

  /// Replaces the schedule of every day in [to] with the one of [from].
  String? copyDay(Weekday from, Iterable<Weekday> to) {
    final targets = to.toSet()..remove(from);
    final current = ScheduleGrid.cellsOf(declaration.intervals);
    final next = Map<GridCell, String>.of(current)
      ..removeWhere((cell, _) => targets.contains(cell.day));
    for (final entry in current.entries.where((e) => e.key.day == from)) {
      for (final day in targets) {
        next[GridCell(day, entry.key.startMinutes)] = entry.value;
      }
    }
    return _commit(current, next);
  }

  /// Applies [next] unless it breaks a limit that [current] did not: 10
  /// hours a day, or more hours of a task than it has. Fixing older data
  /// (removing hours) is always allowed.
  String? _commit(Map<GridCell, String> current, Map<GridCell, String> next) {
    for (final day in ScheduleGrid.days) {
      final after = ScheduleGrid.minutesOn(day, next);
      if (after > ScheduleGrid.maxDailyMinutes &&
          after > ScheduleGrid.minutesOn(day, current)) {
        return 'El ${day.label} no puede pasar de '
            '${ScheduleGrid.maxDailyMinutes ~/ 60} horas.';
      }
    }
    final required = ScheduleRequirements.requiredMinutes(declaration);
    int placed(Map<GridCell, String> cells, ScheduleTask task) =>
        cells.values.where((key) => key == task.key).length *
        ScheduleGrid.stepMinutes;
    for (final MapEntry(key: task, value: limit) in required.entries) {
      final after = placed(next, task);
      if (after > limit && after > placed(current, task)) {
        final what = ScheduleRequirements.describe(task, declaration);
        final left = limit - placed(current, task);
        return left <= 0
            ? 'Ya ubicó todas las horas de $what '
                  '(${TimeRules.hoursLabel(limit)}).'
            : 'Solo quedan ${TimeRules.hoursLabel(left)} de $what por ubicar.';
      }
    }
    final intervals = ScheduleGrid.intervalsOf(
      next,
      () => '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
    );
    if (intervals.length > FieldRules.maxIntervals) {
      return 'El horario admite como máximo ${FieldRules.maxIntervals} '
          'bloques.';
    }
    edit(
      (d) => d.intervals
        ..clear()
        ..addAll(intervals),
    );
    return null;
  }

  // ---- Saving -------------------------------------------------------------

  /// Saves as BORRADOR (R5). Does not require complete fields.
  Future<bool> saveDraft() => _save(DeclarationStatus.draft);

  /// Moves to VALIDADA only with no missing fields and no problems (R4).
  Future<bool> validateAndSave() async {
    if (!canValidate) return false;
    return _save(DeclarationStatus.validated);
  }

  Future<bool> _save(DeclarationStatus status) async {
    saving = true;
    error = null;
    notifyListeners();
    final previous = declaration.status;
    try {
      declaration.status = status;
      await _repository.save(declaration);
      return true;
    } catch (e) {
      declaration.status = previous;
      // Technical details go to the log, never to the user.
      debugPrint('Saving declaration failed: $e');
      error = 'No se pudo guardar. Revise la conexión e intente de nuevo.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
