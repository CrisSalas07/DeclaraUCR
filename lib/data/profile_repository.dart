import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// What the app knows about the declarant beyond the session: the name and
/// cédula typed once at sign-up, copied into every declaration.
class UserProfile {
  const UserProfile({required this.name, required this.identification});

  final String name;

  /// Cédula, 9 digits.
  final String identification;
}

/// The cédula is already registered to another account.
class IdentificationTakenException implements Exception {
  const IdentificationTakenException();

  static const String message = 'Esa cédula ya está registrada en otra cuenta.';

  @override
  String toString() => message;
}

/// Profiles at `users/{uid}`. The UI only knows this interface (DIP).
abstract class ProfileRepository {
  /// The profile of [uid], or `null` while it has none (accounts created
  /// before the cédula was asked).
  Stream<UserProfile?> watch(String uid);

  /// Creates the profile and reserves its cédula, which is unique: throws
  /// [IdentificationTakenException] when another account has it.
  /// `firestore.rules` never lets the cédula change.
  Future<void> save(String uid, UserProfile profile);
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore)
    : _users = _firestore.collection('users'),
      _ids = _firestore.collection('identifications');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _users;

  /// One document per cédula, `identifications/{cédula}` = {uid}, as in
  /// DeclaraHorario: written with the profile in the same transaction, it
  /// keeps a cédula from being registered twice.
  final CollectionReference<Map<String, dynamic>> _ids;

  @override
  Stream<UserProfile?> watch(String uid) =>
      _users.doc(uid).snapshots().map((snap) {
        final data = snap.data();
        if (data == null) return null;
        final name = data['name'], id = data['identification'];
        if (name is! String || id is! String) {
          debugPrint('Malformed profile $uid');
          return null;
        }
        return UserProfile(name: name, identification: id);
      });

  @override
  Future<void> save(String uid, UserProfile profile) async {
    final id = profile.identification.trim();
    try {
      await _firestore.runTransaction((tx) async {
        final reservation = await tx.get(_ids.doc(id));
        if (reservation.exists && reservation.data()?['uid'] != uid) {
          throw const IdentificationTakenException();
        }
        tx
          ..set(_ids.doc(id), {'uid': uid})
          ..set(_users.doc(uid), {
            'name': profile.name.trim(),
            'identification': id,
          });
      });
    } on FirebaseException catch (e) {
      // The rules only let a person read their own reservation: denied
      // means another account holds the cédula.
      if (e.code == 'permission-denied') {
        throw const IdentificationTakenException();
      }
      rethrow;
    }
  }
}
