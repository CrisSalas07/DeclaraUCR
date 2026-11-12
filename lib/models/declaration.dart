import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// The institution and campus of this app, never typed (as
/// `AppointmentDefaults` of DeclaraHorario).
abstract final class Workplace {
  static const String institution = 'Universidad de Costa Rica';
  static const String campus = 'Sede del Sur';
  static const String full = '$institution · $campus';
}

/// One block of the weekly schedule (R3). Times are minutes since midnight,
/// as in DeclaraHorario (`TimeRules`).
class ScheduleInterval {
  ScheduleInterval({
    required this.id,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.task,
  });

  final String id;
  Weekday day;
  int startMinutes;
  int endMinutes;
  ScheduleTask task;

  /// Length in minutes; 0 when the range is invalid (end <= start).
  int get durationMinutes =>
      endMinutes > startMinutes ? endMinutes - startMinutes : 0;

  /// Institution of the block: the university, or the other institution.
  String get institution =>
      task.kind == TaskKind.external ? task.name : Workplace.institution;

  ScheduleInterval copy() => ScheduleInterval(
    id: id,
    day: day,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    task: task,
  );
}

/// Sworn declaration of the mobile module. Mutable: the form edits it in
/// place and the repository saves it as a whole.
///
/// The name and identification come from the profile; the institution is
/// fixed ([Workplace]). The person only picks and places hours.
class Declaration {
  Declaration({
    this.id,
    this.declarantName = '',
    this.identification = '',
    this.position = '',
    this.appointmentType,
    this.validFrom,
    this.validTo,
    List<CourseLoad>? courses,
    List<ProjectHours>? projects,
    List<ExternalJob>? externalJobs,
    this.notes = '',
    List<ScheduleInterval>? intervals,
    this.status = DeclarationStatus.draft,
    this.updatedAt,
  }) : courses = courses ?? <CourseLoad>[],
       projects = projects ?? <ProjectHours>[],
       externalJobs = externalJobs ?? <ExternalJob>[],
       intervals = intervals ?? <ScheduleInterval>[];

  String? id;
  String declarantName;
  String identification;
  String position;
  String? appointmentType;
  DateTime? validFrom;
  DateTime? validTo;
  final List<CourseLoad> courses;
  final List<ProjectHours> projects;
  final List<ExternalJob> externalJobs;

  /// Notes typed by the person; the rest of the observations is written
  /// from the schedule (`ScheduleObservations`).
  String notes;
  final List<ScheduleInterval> intervals;
  DeclarationStatus status;
  DateTime? updatedAt;

  String get institution => Workplace.full;

  /// Weekly load of the courses (the workday the courses give).
  int get coursesMinutes =>
      courses.fold(0, (total, c) => total + c.workloadMinutes);

  int get projectsMinutes =>
      projects.fold(0, (total, p) => total + p.weeklyMinutes);

  /// Expected weekly minutes at the university: courses plus projects.
  int get universityMinutes => coursesMinutes + projectsMinutes;

  /// Expected weekly minutes at other institutions.
  int get externalMinutes =>
      externalJobs.fold(0, (total, j) => total + j.weeklyMinutes);

  /// Placed minutes in the schedule (valid intervals only).
  int get totalMinutes =>
      intervals.fold(0, (total, interval) => total + interval.durationMinutes);

  /// Placed minutes of every kind of course hours.
  int placedMinutesOf(TaskKind kind) => intervals
      .where((i) => i.task.kind == kind)
      .fold(0, (total, i) => total + i.durationMinutes);

  /// Intervals ordered by day and start time, for read-only views.
  List<ScheduleInterval> get sortedIntervals => [...intervals]
    ..sort((a, b) {
      final byDay = a.day.number.compareTo(b.day.number);
      return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
    });

  /// Deep copy, so the form can edit without touching the home list until
  /// the declaration is saved.
  Declaration copy() => Declaration(
    id: id,
    declarantName: declarantName,
    identification: identification,
    position: position,
    appointmentType: appointmentType,
    validFrom: validFrom,
    validTo: validTo,
    courses: [...courses],
    projects: [...projects],
    externalJobs: [...externalJobs],
    notes: notes,
    intervals: intervals.map((i) => i.copy()).toList(),
    status: status,
    updatedAt: updatedAt,
  );
}
