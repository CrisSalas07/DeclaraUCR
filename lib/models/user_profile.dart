/// Roles of the Proyecto 1 system (`users/{uid}.roles`). Only administrators
/// assign them, from the web; sign-up always starts as [declarant].
enum UserRole {
  declarant('declarant', 'Declarante'),
  careerCoordinator('careerCoordinator', 'Coordinación de carrera'),
  superior('superior', 'Superior'),
  hr('hr', 'Recursos Humanos'),
  admin('admin', 'Administración');

  const UserRole(this.value, this.label);

  /// Stored value.
  final String value;

  /// Spanish name for the user.
  final String label;

  /// The role stored as [value], or `null` for an unknown one (a newer
  /// version of the web system may add roles: they are ignored here).
  static UserRole? fromValue(String value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// The person's profile at `users/{uid}`, as the Proyecto 1 (DeclaraHorario)
/// stores it. Name and cédula are copied into every declaration; campus,
/// career and reviewer decide whether the person can declare.
class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.identification,
    this.identificationType = nationalId,
    this.phone = '',
    this.email = '',
    this.roles = const {UserRole.declarant},
    this.active = true,
    this.campusId,
    this.unitId,
    this.superiorUid,
  });

  /// `identificationType` of a Costa Rican cédula. The web also accepts
  /// `PASAPORTE`; the mobile sign-up only asks for the cédula.
  static const String nationalId = 'CEDULA';

  final String fullName;
  final String identification;
  final String identificationType;

  /// 8 digits, no hyphens.
  final String phone;
  final String email;
  final Set<UserRole> roles;

  /// `false` when administration disabled the account.
  final bool active;

  /// Campus (`campuses/{id}`), chosen once by the person.
  final String? campusId;

  /// Career (`units/{id}`), chosen once by a declarant.
  final String? unitId;

  /// Reviewer, assigned by administration from the web. Without one, the
  /// rules reject a new declaration.
  final String? superiorUid;

  /// Name copied into declarations.
  String get name => fullName;

  bool get isDeclarant => roles.contains(UserRole.declarant);

  /// The campus is still to be chosen.
  bool get needsCampus => campusId == null;

  /// A declarant must belong to a career (a coordinator's career is set by
  /// administration, never by the person).
  bool get needsCareer =>
      isDeclarant &&
      !roles.contains(UserRole.careerCoordinator) &&
      unitId == null;

  bool get hasSuperior => superiorUid != null;
}

/// A campus (`campuses/{id}`) or a career (`units/{id}`) to choose from.
class OrgUnit {
  const OrgUnit({required this.id, required this.name});

  final String id;
  final String name;
}
