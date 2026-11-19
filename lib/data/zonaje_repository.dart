import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:flutter/foundation.dart';

/// The zonaje requests of one person, read only (DIP: the UI never sees
/// Firestore). Requests are made in the web system of the Proyecto 1.
abstract class ZonajeRepository {
  /// The person's requests, newest first.
  Stream<List<ZonajeRequest>> watchAll();
}

/// `zonajeRequests` of the Proyecto 1, filtered by `declarantUid`: the only
/// list query its rules allow a declarant.
class FirestoreZonajeRepository implements ZonajeRepository {
  FirestoreZonajeRepository(FirebaseFirestore firestore, {required this._uid})
    : _collection = firestore.collection('zonajeRequests');

  final CollectionReference<Map<String, dynamic>> _collection;
  final String _uid;

  @override
  Stream<List<ZonajeRequest>> watchAll() => _collection
      .where('declarantUid', isEqualTo: _uid)
      .snapshots()
      .map(
        (snap) => snap.docs.map(_tryMap).nonNulls.toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          ),
      );

  static ZonajeRequest? _tryMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      return fromMap(doc.id, doc.data());
    } on Object catch (e) {
      // One malformed document must not hide the whole list.
      debugPrint('Skipping zonaje request ${doc.id}: $e');
      return null;
    }
  }

  /// Reads a stored request; a missing or mistyped field throws.
  static ZonajeRequest fromMap(String id, Map<String, dynamic> m) {
    DateTime? date(String key) => (m[key] as Timestamp?)?.toDate();
    return ZonajeRequest(
      id: id,
      periodId: m['periodId'] as String?,
      previousAddress: m['previousAddress'] as String,
      currentAddress: m['currentAddress'] as String,
      declaredDistanceKm: (m['declaredDistanceKm'] as num).toDouble(),
      confirmedDistanceKm: (m['confirmedDistanceKm'] as num?)?.toDouble(),
      regime: SalaryRegime.fromValue(m['salaryRegime'] as String),
      weeklyMinutes: m['weeklyMinutes'] as int,
      status: ZonajeStatus.fromValue(m['status'] as String),
      createdAt: date('createdAt'),
      hrObservation: m['hrObservation'] as String?,
      reviewedAt: date('reviewedAt'),
      annulReason: m['annulReason'] as String?,
    );
  }
}
