import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRules.emailError', () {
    test('accepts an institutional e-mail, ignoring case and spaces', () {
      expect(AuthRules.emailError(' Ana.Perez@UCR.ac.cr '), isNull);
    });

    test('rejects other domains, look-alikes and bad formats', () {
      for (final email in [
        'ana@gmail.com',
        'ana@ucr.ac.cr.evil.com',
        'ana@fakeucr.ac.cr',
        'ana ucr.ac.cr',
        '',
      ]) {
        expect(AuthRules.emailError(email), isNotNull, reason: email);
      }
    });
  });

  test('passwordError needs 8+ characters with letters and numbers', () {
    expect(AuthRules.passwordError('Clave1234'), isNull);
    expect(AuthRules.passwordError('Ab1'), isNotNull);
    expect(AuthRules.passwordError('soloLetras'), isNotNull);
    expect(AuthRules.passwordError('12345678'), isNotNull);
  });

  test('AppUser greeting data falls back to the e-mail', () {
    const named = AppUser(
      uid: 'u',
      email: 'ana@ucr.ac.cr',
      displayName: 'Ana Pérez Mora',
    );
    const unnamed = AppUser(uid: 'u', email: 'luis@ucr.ac.cr', displayName: '');
    expect(named.firstName, 'Ana');
    expect(named.initials, 'AP');
    expect(unnamed.firstName, 'luis');
    expect(unnamed.initials, 'L');
  });
}
