/// What the declarant adds to a declaration besides the schedule: courses,
/// projects and jobs at other institutions. Pure Dart, immutable.
library;

/// A course of the career and its weekly hours, as `CourseAssignment` of
/// DeclaraHorario (Resolución VD-12928-2024 §1.2 and VD-13015-2024).
///
/// The declarant picks the workday; the rest follows from it: lessons are
/// 2 of every 5 hours, attention 30 minutes per lesson hour and planning the
/// rest (1/8 TC = 2 h lessons + 1 h attention + 2 h planning).
class CourseLoad {
  const CourseLoad({
    required this.name,
    required this.code,
    required this.workloadMinutes,
  });

  /// Course name, unique in the declaration.
  final String name;

  /// Sigla, upper case letters and digits ("IF0009"); may be empty.
  final String code;

  /// Weekly load: lessons + attention + planning.
  final int workloadMinutes;

  int get lessonMinutes => workloadMinutes * 2 ~/ 5;
  int get attentionMinutes => lessonMinutes ~/ 2;
  int get planningMinutes => workloadMinutes - lessonMinutes - attentionMinutes;

  /// How the observations and the grid name it: the sigla, else the name.
  String get shortName => code.isEmpty ? name : code;
}

/// Weekly hours of a project inside the university appointment (research,
/// social action...), as `ProjectHours` of DeclaraHorario.
class ProjectHours {
  const ProjectHours({required this.name, required this.weeklyMinutes});

  final String name;
  final int weeklyMinutes;
}

/// Kind of another institution (section 5.3 of the original assignment).
enum InstitutionType {
  public('public', 'Pública'),
  private('private', 'Privada'),
  foundation('foundation', 'Fundación');

  const InstitutionType(this.value, this.label);

  /// Stored in Firestore.
  final String value;

  /// Shown to the user.
  final String label;

  static InstitutionType fromValue(String value) =>
      InstitutionType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => throw ArgumentError('Unknown InstitutionType: $value'),
      );
}

/// A job at another institution, declared on the same weekly schedule
/// (`ExternalJob` of DeclaraHorario). Its blocks add up to exactly
/// [weeklyMinutes]; all of them together, at most 20 hours.
class ExternalJob {
  const ExternalJob({
    required this.institution,
    required this.type,
    required this.position,
    required this.weeklyMinutes,
  });

  /// Name, unique in the declaration.
  final String institution;
  final InstitutionType type;
  final String position;
  final int weeklyMinutes;
}

/// Positions offered by the form, from `PositionField` of DeclaraHorario.
abstract final class Positions {
  /// Puestos of the Régimen Académico of the university.
  static const List<String> university = <String>[
    'Interino Bachiller',
    'Interino Licenciado',
    'Instructor',
    'Adjunto',
    'Asociado',
    'Catedrático',
  ];

  /// Usual positions at other institutions.
  static const List<String> otherInstitution = <String>[
    'Docente',
    'Profesor',
    'Investigador',
    'Administrativo',
    'Asesor',
    'Consultor',
  ];
}

/// Kinds of appointment (R2: "tipo de nombramiento").
const List<String> appointmentTypes = <String>['Interino', 'Propiedad'];
