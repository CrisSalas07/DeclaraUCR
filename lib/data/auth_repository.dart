import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Failure the UI can show as is: [message] is already in Spanish and never
/// carries technical details.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication used by the app (DIP: the UI never imports firebase_auth).
abstract class AuthRepository {
  /// Emits on sign-in, sign-out and profile changes (e.g. the name set
  /// right after registering).
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  /// Creates the account and stores the name and cédula; the person is
  /// signed in.
  Future<void> register({
    required String name,
    required String identification,
    required String email,
    required String password,
  });

  /// Why the last sign-up left the account without a profile (e.g. the
  /// cédula belongs to another account), once; `null` otherwise.
  String? takeSignUpNotice();

  /// Silent when the account does not exist (no account enumeration).
  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._profiles) {
    // Verification and reset e-mails in Spanish.
    _auth.setLanguageCode('es');
  }

  final FirebaseAuth _auth;
  final ProfileRepository _profiles;
  String? _signUpNotice;

  @override
  String? takeSignUpNotice() {
    final notice = _signUpNotice;
    _signUpNotice = null;
    return notice;
  }

  static AppUser? _map(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: AuthRules.normalizeEmail(email),
          password: password,
        ),
      );

  @override
  Future<void> register({
    required String name,
    required String identification,
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: AuthRules.normalizeEmail(email),
      password: password,
    );
    final user = credential.user!;
    try {
      await _profiles.save(
        user.uid,
        UserProfile(name: name, identification: identification),
      );
    } on IdentificationTakenException {
      // The session already opened, so the app shows "Complete su perfil";
      // it tells why and asks for the cédula again.
      _signUpNotice = IdentificationTakenException.message;
    } catch (e) {
      // The account exists: the app asks for the cédula again on entry.
      debugPrint('Saving profile failed: $e');
    }
    await user.updateDisplayName(name.trim());
  });

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: AuthRules.normalizeEmail(email),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth failed: ${e.code}');
      throw AuthException(_messageFor(e));
    }
  }

  static String _messageFor(FirebaseAuthException e) => switch (e.code) {
    // One message for all credential errors: does not reveal which part
    // was wrong or whether the account exists.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => 'Correo o contraseña incorrectos.',
    'invalid-email' => 'El correo no tiene un formato válido.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña es demasiado débil.',
    'user-disabled' => 'Esta cuenta está deshabilitada.',
    'too-many-requests' =>
      'Demasiados intentos. Espere unos minutos e intente de nuevo.',
    'network-request-failed' =>
      'Sin conexión. Revise su red e intente de nuevo.',
    _ => 'No se pudo completar la operación. Intente de nuevo.',
  };
}
