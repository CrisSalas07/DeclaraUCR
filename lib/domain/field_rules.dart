/// Input limits for the declaration fields. Single source for the form
/// (maxLength, input filters), the validator and `firestore.rules`.
///
/// Keep these numbers in sync with the Proyecto 1 `firestore.rules` (copy in
/// `backend/proyecto1/`).
abstract final class FieldRules {
  static const int nameMaxLength = 120;
  static const int positionMaxLength = 120;
  static const int notesMaxLength = 1000;
  static const int observationsMaxLength = 4000;
  static const int maxIntervals = 80;
  static const int maxCourses = 12;
  static const int maxProjects = 6;
  static const int maxExternalJobs = 4;

  /// Costa Rican cédula: 9 digits with the zeros of each group, no hyphens
  /// (DeclaraHorario `IdentificationType.nationalId`, e.g. 105430987).
  static final RegExp nationalIdFormat = RegExp(r'^[1-9][0-9]{8}$');

  static bool isValidIdentification(String value) =>
      nationalIdFormat.hasMatch(value.trim());

  /// Costa Rican phone: 8 digits starting with 2, 4, 5, 6, 7 or 8, no
  /// hyphens. Same as `validPhone` in the Proyecto 1 `firestore.rules`.
  static final RegExp phoneFormat = RegExp(r'^[245678][0-9]{7}$');

  /// `null` when [value] is a valid phone; otherwise the message.
  static String? phoneError(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'Ingrese su número de teléfono.';
    if (!phoneFormat.hasMatch(phone)) {
      return 'Use los 8 dígitos del teléfono, sin guiones (ej. 88881234).';
    }
    return null;
  }

  /// `null` when [value] is a valid cédula; otherwise the message.
  static String? identificationError(String? value) {
    final id = (value ?? '').trim();
    if (id.isEmpty) return 'Ingrese su número de cédula.';
    if (!isValidIdentification(id)) {
      return 'Use los 9 dígitos de la cédula, sin guiones (ej. 105430987).';
    }
    return null;
  }
}
