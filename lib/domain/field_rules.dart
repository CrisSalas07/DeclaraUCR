/// Input limits for the declaration fields. Single source for the form
/// (maxLength, input filters), the validator and `firestore.rules`.
///
/// Keep these numbers in sync with `firestore.rules`.
abstract final class FieldRules {
  static const int nameMaxLength = 120;
  static const int identificationMaxLength = 20;
  static const int institutionMaxLength = 120;
  static const int positionMaxLength = 120;
  static const int additionalInstitutionsMaxLength = 500;
  static const int observationsMaxLength = 1000;
  static const int maxIntervals = 50;

  /// Characters allowed while typing an identification (national ID, DIMEX
  /// or passport): digits, letters and hyphens.
  static final RegExp identificationChars = RegExp(r'[0-9A-Za-z-]');

  /// Full identification format: 5 to 20 allowed characters.
  static final RegExp identificationFormat = RegExp(r'^[0-9A-Za-z-]{5,20}$');

  static bool isValidIdentification(String value) =>
      identificationFormat.hasMatch(value.trim());
}
