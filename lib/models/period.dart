import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';

/// A declaration period of the Proyecto 1 (`periods/{year}_{cycle}`): one
/// lecture cycle. Administration opens and closes it from the web.
class Period {
  const Period({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.enabled,
  });

  /// e.g. `2026_II`.
  final String id;

  /// e.g. "II Ciclo - 2026".
  final String name;

  /// Validity of every appointment of the period.
  final DateTime startDate;
  final DateTime endDate;

  /// Open for new declarations.
  final bool enabled;
}

/// One weekly lesson slot the career coordination assigned (fixed: the
/// teacher does not move it).
class LessonSlot {
  const LessonSlot({
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.course,
  });

  final Weekday day;
  final int startMinutes;
  final int endMinutes;

  /// Name of the course, as in [CourseLoad.name].
  final String course;
}

/// The courses and lesson slots the career coordination assigned to a
/// teacher in a period (`workloadAssignments/{periodId}_{uid}`). Without it,
/// the rules reject a new declaration for that period.
class WorkloadAssignment {
  const WorkloadAssignment({
    required this.periodId,
    required this.courses,
    required this.slots,
  });

  final String periodId;
  final List<CourseLoad> courses;
  final List<LessonSlot> slots;

  /// Weekly load of all the courses.
  int get workloadMinutes =>
      courses.fold(0, (total, c) => total + c.workloadMinutes);
}
