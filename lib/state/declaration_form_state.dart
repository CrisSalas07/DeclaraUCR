import 'dart:async';

import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/network_status.dart';
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
    this._network = const AlwaysOnline(),
    this._saveTimeout = const Duration(seconds: 15),
    Declaration? initial,
    UserProfile? profile,
  }) : declaration = initial?.copy() ?? Declaration() {
    // The profile is the source of the name and cédula: never typed here.
    if (profile != null) {
      declaration
        ..declarantName = profile.name
        ..identification = profile.identification;
    }
    _placeAssignedLessons();
    // Placing the coordination's lessons is redone on every open: not a
    // change of the person's.
    unsaved = false;
  }

  /// Message when a fixed lesson would be moved, in Spanish.
  static const String lessonsAreFixed =
      'Las clases las asigna la Coordinación de su carrera: no se mueven.';

  /// The lessons are the coordination's slots (Proyecto 1): the person only
  /// places attention, planning, projects and other institutions.
  bool get lessonsFixed => declaration.lessonSlots.isNotEmpty;

  /// Half hours taken by the assigned lessons.
  Set<GridCell> get fixedCells => {
    for (final slot in declaration.lessonSlots)
      for (
        var m = slot.startMinutes;
        m < slot.endMinutes;
        m += ScheduleGrid.stepMinutes
      )
        GridCell(slot.day, m),
  };

  /// Puts the lessons exactly where the coordination assigned them. A
  /// declaration whose lessons differ (the assignment changed, or they were
  /// moved) is corrected, which counts as an edit.
  void _placeAssignedLessons() {
    if (!lessonsFixed || !editable) return;
    String keyOf(ScheduleInterval i) =>
        '${i.day.number}|${i.startMinutes}|${i.endMinutes}|${i.task.name}';
    final assigned = [
      for (final (index, slot) in declaration.lessonSlots.indexed)
        ScheduleInterval(
          id: 'slot-$index',
          day: slot.day,
          startMinutes: slot.startMinutes,
          endMinutes: slot.endMinutes,
          task: ScheduleTask(TaskKind.lesson, slot.course),
        ),
    ];
    final current = declaration.intervals
        .where((i) => i.task.kind == TaskKind.lesson)
        .map(keyOf)
        .toSet();
    if (current.length == assigned.length &&
        current.containsAll(assigned.map(keyOf))) {
      return;
    }
    edit(
      (d) => d.intervals
        ..removeWhere((i) => i.task.kind == TaskKind.lesson)
        ..addAll(assigned),
    );
  }

  final DeclarationRepository _repository;
  final DeclarationValidator _validator;
  final NetworkStatus _network;

  /// How long a save may wait for the server before telling the person.
  final Duration _saveTimeout;

  /// Shown when the server does not confirm a save in time.
  static const String timeoutMessage =
      'El servidor no confirmó el guardado a tiempo. Sus cambios siguen en '
      'pantalla: revise la conexión y vuelva a guardar.';
  final Declaration declaration;

  bool saving = false;

  /// Changes on screen that are not stored yet; leaving asks first, so
  /// nothing is lost without the person knowing (§5 of the Proyecto 2).
  bool unsaved = false;

  /// User-facing message of the last failed save, in Spanish.
  String? error;
  int _nextId = 0;

  List<String> get missingFields => _validator.missingFields(declaration);

  /// How many required fields the form has (all missing on an empty one).
  int get requiredFieldCount => _validator.missingFields(Declaration()).length;
  List<ValidationIssue> get issues => _validator.issues(declaration);
  bool get canValidate => _validator.isValid(declaration);

  /// Until it is signed (BORRADOR, VALIDADA, or PENDIENTE_FIRMA_DECLARANTE
  /// when signing was started and not finished), editing sends it back to
  /// BORRADOR, as in the web. Once signed it is read only: review and HR
  /// happen in the web system.
  bool get editable =>
      declaration.status == DeclarationStatus.draft ||
      declaration.status == DeclarationStatus.validated ||
      declaration.status == DeclarationStatus.pendingDeclarantSignature;

  /// Applies a change. As in DeclaraHorario, editing a VALIDADA declaration
  /// sends it back to BORRADOR until it is validated again.
  void edit(void Function(Declaration d) change) {
    if (!editable) return;
    change(declaration);
    unsaved = true;
    if (declaration.status != DeclarationStatus.draft) {
      declaration.status = DeclarationStatus.draft;
    }
    notifyListeners();
  }

  // ---- Projects and other institutions ------------------------------------
  // (Courses come from the career coordination's assignment.)

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
    final fixed = lessonsFixed ? fixedCells : const <GridCell>{};
    final touched = cells.where((c) => !ScheduleGrid.isLunch(c.startMinutes));
    if (lessonsFixed &&
        (task?.kind == TaskKind.lesson ||
            (touched.isNotEmpty && touched.every(fixed.contains)))) {
      return lessonsAreFixed;
    }
    final current = ScheduleGrid.cellsOf(declaration.intervals);
    final next = Map<GridCell, String>.of(current);
    for (final cell in touched) {
      // The assigned lessons stay; the rest of the range is painted.
      if (fixed.contains(cell)) continue;
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
    final fixed = lessonsFixed ? fixedCells : const <GridCell>{};
    bool isLesson(String key) =>
        lessonsFixed && ScheduleTask.fromKey(key).kind == TaskKind.lesson;
    final current = ScheduleGrid.cellsOf(declaration.intervals);
    // The target days keep their own assigned lessons; the source day's
    // lessons are not copied.
    final next = Map<GridCell, String>.of(current)
      ..removeWhere(
        (cell, _) => targets.contains(cell.day) && !fixed.contains(cell),
      );
    for (final entry in current.entries.where((e) => e.key.day == from)) {
      if (isLesson(entry.value)) continue;
      for (final day in targets) {
        final cell = GridCell(day, entry.key.startMinutes);
        if (!fixed.contains(cell)) next[cell] = entry.value;
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
        final what = ScheduleRequirements.ofTask(task, declaration);
        final left = limit - placed(current, task);
        return left <= 0
            ? 'Ya ubicó todas las horas $what '
                  '(${TimeRules.hoursLabel(limit)}).'
            : 'Solo quedan ${TimeRules.hoursLabel(left)} $what por ubicar.';
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
      // Without a network nothing is attempted: the changes stay here.
      if (!await _network.isOnline()) throw const OfflineException();
      declaration.status = status;
      await _repository.save(declaration).timeout(_saveTimeout);
      unsaved = false;
      return true;
    } on OfflineException {
      declaration.status = previous;
      error = OfflineException.message;
      return false;
    } on TimeoutException {
      declaration.status = previous;
      error = timeoutMessage;
      return false;
    } on DeclarationSaveException catch (e) {
      declaration.status = previous;
      error = e.message;
      return false;
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
