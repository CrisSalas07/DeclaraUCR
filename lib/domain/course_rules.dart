import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// Rules of the courses, projects and other institutions the declarant
/// adds; reused from DeclaraHorario (`CourseRules`, `ExternalSchedule`).
/// Each method returns the first problem as a Spanish message, or `null`.
abstract final class CourseRules {
  static const int nameMaxLength = 120;
  static const int codeMaxLength = 10;

  /// Sigla: upper case letters and digits ("IF0009").
  static final RegExp codeFormat = RegExp(r'^[A-Z0-9]{2,10}$');

  /// One course on its own.
  static String? validateCourse(CourseLoad course) {
    final name = course.name.trim();
    if (name.isEmpty) return 'Cada curso necesita un nombre.';
    if (name.length > nameMaxLength) {
      return 'El nombre de "$name" supera $nameMaxLength caracteres.';
    }
    if (course.code.isNotEmpty && !codeFormat.hasMatch(course.code)) {
      return 'La sigla de "$name" lleva de 2 a 10 letras mayúsculas o '
          'números (ej. IF0009).';
    }
    if (WorkloadCatalog.labelFor(course.workloadMinutes) == null) {
      return 'Elija de nuevo la jornada de "$name".';
    }
    return null;
  }

  /// The whole list of [courses], [projects] and [jobs]: unique names, at
  /// most one full time at the university and 1/2 TC elsewhere.
  static String? validateAll(
    List<CourseLoad> courses,
    List<ProjectHours> projects,
    List<ExternalJob> jobs,
  ) {
    final names = <String>{};
    final codes = <String>{};
    for (final course in courses) {
      final problem = validateCourse(course);
      if (problem != null) return problem;
      if (!names.add(course.name.trim().toLowerCase())) {
        return 'Hay dos cursos llamados "${course.name.trim()}".';
      }
      if (course.code.isNotEmpty && !codes.add(course.code)) {
        return 'Hay dos cursos con la sigla ${course.code}.';
      }
    }
    final projectNames = <String>{};
    for (final project in projects) {
      final name = project.name.trim();
      if (name.isEmpty) return 'Cada proyecto necesita un nombre.';
      if (!projectNames.add(name.toLowerCase())) {
        return 'Hay dos proyectos llamados "$name".';
      }
      if (project.weeklyMinutes <= 0 || project.weeklyMinutes % 30 != 0) {
        return 'Las horas del proyecto "$name" van en medias horas.';
      }
    }
    final university = [
      ...courses.map((c) => c.workloadMinutes),
      ...projects.map((p) => p.weeklyMinutes),
    ].fold(0, (a, b) => a + b);
    if (university > WorkloadCatalog.maxUniversityMinutes) {
      return 'Los cursos y proyectos suman ${TimeRules.hoursLabel(university)}'
          ': superan el tiempo completo de '
          '${TimeRules.hoursLabel(WorkloadCatalog.maxUniversityMinutes)}.';
    }
    final institutions = <String>{};
    for (final job in jobs) {
      final name = job.institution.trim();
      if (name.isEmpty) return 'Cada institución necesita un nombre.';
      if (!institutions.add(name.toLowerCase())) {
        return 'La institución "$name" está dos veces.';
      }
      if (job.position.trim().isEmpty) {
        return 'Elija el puesto en "$name".';
      }
    }
    final external = jobs.fold(0, (total, j) => total + j.weeklyMinutes);
    if (external > WorkloadCatalog.maxExternalMinutes) {
      return 'Las otras instituciones suman ${TimeRules.hoursLabel(external)}'
          ': el máximo es '
          '${TimeRules.hoursLabel(WorkloadCatalog.maxExternalMinutes)}.';
    }
    return null;
  }
}
