/// Sign-up and sign-in input rules. Pure Dart.
///
/// Keep [allowedDomains] in sync with `allowedEmail` in the Proyecto 1
/// `firestore.rules` (copy in `backend/proyecto1/`), which is the real
/// enforcement: this only gives the user early feedback.
abstract final class AuthRules {
  static const String institutionalDomain = 'ucr.ac.cr';

  /// The institutional domain first; the others are the providers the
  /// Proyecto 1 also accepts, so its existing accounts can sign in here.
  static const List<String> allowedDomains = [
    institutionalDomain,
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'zoho.com',
    'zohomail.com',
  ];
  static const int passwordMinLength = 8;
  static const int nameMaxLength = 120;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// `null` when valid; otherwise the message for the user.
  static String? emailError(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Ingrese su correo.';
    if (!_email.hasMatch(email)) return 'El correo no tiene un formato válido.';
    final domain = email.substring(email.lastIndexOf('@') + 1);
    if (!allowedDomains.contains(domain)) {
      return 'Use su correo @$institutionalDomain (o Gmail, Outlook, '
          'Hotmail, Live o Zoho).';
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
