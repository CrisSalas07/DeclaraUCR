import 'dart:async';

import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/models/app_user.dart';

/// In-memory [AuthRepository]: one account, password "Clave1234". On
/// sign-up it stores the profile in [profiles], like the real one.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn, this.profiles}) : _user = signedIn;

  static const verifiedUser = AppUser(
    uid: 'user-a',
    email: 'ana.perez@ucr.ac.cr',
    displayName: 'Ana Pérez Mora',
  );

  static const password = 'Clave1234';

  final ProfileRepository? profiles;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  void _emit(AppUser? user) => _controller.add(_user = user);

  @override
  Stream<AppUser?> userChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (email != verifiedUser.email ||
        password != FakeAuthRepository.password) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    _emit(verifiedUser);
  }

  @override
  Future<void> register({
    required String name,
    required String identification,
    required String email,
    required String password,
  }) async {
    try {
      await profiles?.save(
        'new',
        UserProfile(name: name, identification: identification),
      );
    } on IdentificationTakenException {
      _notice = IdentificationTakenException.message;
    }
    _emit(AppUser(uid: 'new', email: email, displayName: name));
  }

  String? _notice;

  @override
  String? takeSignUpNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => _emit(null);
}
