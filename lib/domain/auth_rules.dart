/// Sign-up and sign-in input rules. Pure Dart.
///
/// Keep [institutionalDomain] in sync with `firestore.rules`, which is the
/// real enforcement: this only gives the user early feedback.
abstract final class AuthRules {
  static const String institutionalDomain = 'ucr.ac.cr';
  static const int passwordMinLength = 8;
  static const int nameMaxLength = 120;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// `null` when valid; otherwise the message for the user.
  static String? emailError(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Ingrese su correo institucional.';
    if (!_email.hasMatch(email)) return 'El correo no tiene un formato válido.';
    if (!email.endsWith('@$institutionalDomain')) {
      return 'Use su correo institucional @$institutionalDomain.';
    }
    return null;
  }

  static String? passwordError(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Ingrese su contraseña.';
    if (password.length < passwordMinLength) {
      return 'Use al menos $passwordMinLength caracteres.';
    }
    if (!password.contains(RegExp(r'[A-Za-z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      return 'Combine letras y números.';
    }
    return null;
  }

  static String? nameError(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Ingrese su nombre completo.';
    if (name.length > nameMaxLength) {
      return 'Use como máximo $nameMaxLength caracteres.';
    }
    return null;
  }
}
