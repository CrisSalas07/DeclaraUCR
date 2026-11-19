import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/network_status.dart';
import 'package:declara_ucr/models/user_profile.dart';

export 'package:declara_ucr/models/user_profile.dart';

/// The cédula is already registered to another account.
class IdentificationTakenException implements Exception {
  const IdentificationTakenException();

  static const String message = 'Esa cédula ya está registrada en otra cuenta.';

  @override
  String toString() => message;
}

/// Profiles at `users/{uid}` in the Proyecto 1 schema, plus the campuses
/// and careers a person chooses from. The UI only knows this interface.
abstract class ProfileRepository {
  /// The profile of [uid], or `null` while it has none (the sign-up did not
  /// finish). A stored profile that cannot be read is an error.
  Stream<UserProfile?> watch(String uid);

  /// Creates the profile at sign-up, as a declarant, and reserves its cédula,
  /// which is unique: throws [IdentificationTakenException] when another
  /// account has it.
  Future<void> create(String uid, UserProfile profile);

  /// Stores the campus and career the person chose ("Completa tu perfil").
  /// Each one is written only while it is empty: the rules never let the
  /// person change them afterwards. A declarant also gets their entry in the
  /// teacher directory, so the career coordination can find them.
  Future<void> chooseWorkplace(
    String uid,
    UserProfile profile, {
    String? campusId,
    String? unitId,
  });

  /// Active campuses, by name.
  Future<List<OrgUnit>> activeCampuses();

  /// Active careers of [campusId], by name.
  Future<List<OrgUnit>> activeCareers(String campusId);
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore)
    : _users = _firestore.collection('users'),
      _ids = _firestore.collection('identifications');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _users;

  /// `identifications/{TYPE}_{number}` = {uid}: written with the profile in
  /// the same transaction, it keeps a cédula from being registered twice.
  final CollectionReference<Map<String, dynamic>> _ids;

  static String reservationId(String type, String number) => '${type}_$number';

  @override
  Stream<UserProfile?> watch(String uid) =>
      _users.doc(uid).snapshots().map((snap) {
        final data = snap.data();
        return data == null ? null : fromMap(data);
      });

  /// Reads a stored profile. Stored documents are untrusted: a missing or
  /// mistyped required field throws a [FormatException].
  static UserProfile fromMap(Map<String, dynamic> map) {
    final fullName = map['fullName'];
    final identification = map['identification'];
    final roles = map['roles'];
    if (fullName is! String || identification is! String || roles is! List) {
      throw const FormatException('Malformed profile');
    }
    String? optional(String key) {
      final value = map[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return UserProfile(
      fullName: fullName,
      identification: identification,
      identificationType:
          optional('identificationType') ?? UserProfile.nationalId,
      phone: optional('phone') ?? '',
      email: optional('email') ?? '',
      roles: {
        for (final role in roles)
          if (role is String && UserRole.fromValue(role) != null)
            UserRole.fromValue(role)!,
      },
      // A profile without the flag is treated as disabled, like the web.
      active: map['active'] == true,
      campusId: optional('campusId'),
      unitId: optional('unitId'),
      superiorUid: optional('superiorUid'),
    );
  }

  @override
  Future<void> create(String uid, UserProfile profile) async {
    final id = profile.identification.trim();
    final reservation = _ids.doc(reservationId(profile.identificationType, id));
    await _firestore.runTransaction((tx) async {
      final held = await tx.get(reservation);
      final holder = held.data()?['uid'];
      if (held.exists && holder != uid) {
        throw const IdentificationTakenException();
      }
      // The fields the rules accept at sign-up, and nothing else: roles,
      // campus, career and reviewer are not the person's to set here.
      tx.set(_users.doc(uid), {
        'fullName': profile.fullName.trim(),
        'identification': id,
        'identificationType': profile.identificationType,
        'phone': profile.phone.trim(),
        'email': profile.email.trim().toLowerCase(),
        'roles': [UserRole.declarant.value],
        'active': true,
      });
      // A reservation is never rewritten: an earlier attempt of this same
      // account may have left it.
      if (!held.exists) tx.set(reservation, {'uid': uid});
    });
  }

  @override
  Future<void> chooseWorkplace(
    String uid,
    UserProfile profile, {
    String? campusId,
    String? unitId,
  }) async {
    final changes = <String, Object>{
      if (profile.campusId == null && campusId != null) 'campusId': campusId,
      if (profile.unitId == null && unitId != null) 'unitId': unitId,
    };
    if (changes.isEmpty) return;
    // From the server first: offline it fails at once instead of leaving
    // the batch queued in the phone.
    try {
      await _users.doc(uid).get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw const OfflineException();
      rethrow;
    }
    final batch = _firestore.batch()..update(_users.doc(uid), changes);
    final unit = unitId ?? profile.unitId;
    if (profile.active && profile.isDeclarant && unit != null) {
      batch.set(_firestore.collection('teacherDirectory').doc(uid), {
        'fullName': profile.fullName,
        'unitId': unit,
        'identification': profile.identification,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<List<OrgUnit>> activeCampuses() =>
      _activeByName(_firestore.collection('campuses'));

  @override
  Future<List<OrgUnit>> activeCareers(String campusId) => _activeByName(
    _firestore.collection('units').where('campusId', isEqualTo: campusId),
  );

  /// Inactive items stay stored (they may be in use) but are not offered.
  Future<List<OrgUnit>> _activeByName(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    final items = [
      for (final doc in snapshot.docs)
        if (doc.data()['active'] != false && doc.data()['name'] is String)
          OrgUnit(id: doc.id, name: doc.data()['name'] as String),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }
}
