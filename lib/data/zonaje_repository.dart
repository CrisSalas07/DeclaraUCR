import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:flutter/foundation.dart';

/// Zonaje requests of one person (`zonajeRequests`). The UI only knows this
/// interface (DIP).
abstract class ZonajeRepository {
  /// The person's requests, newest first.
  Stream<List<ZonajeRequest>> watchAll();

  /// Sends [request] as SOLICITADA.
  Future<void> send(ZonajeRequest request);
}

/// Scoped to [_ownerUid]; `firestore.rules` enforces the same and repeats
/// the eligibility limits.
class FirestoreZonajeRepository implements ZonajeRepository {
  FirestoreZonajeRepository(
    FirebaseFirestore firestore, {
    required this._ownerUid,
  }) : _collection = firestore.collection('zonajeRequests');

  final CollectionReference<Map<String, dynamic>> _collection;
  final String _ownerUid;

  @override
  Stream<List<ZonajeRequest>> watchAll() => _collection
      .where('ownerUid', isEqualTo: _ownerUid)
      .snapshots()
      .map(
        (snap) => snap.docs.map(_tryMap).nonNulls.toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          ),
      );

  ZonajeRequest? _tryMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    try {
      return ZonajeRequest(
        id: doc.id,
        previousAddress: m['previousAddress'] as String,
        currentAddress: m['currentAddress'] as String,
        distanceKm: (m['distanceKm'] as num).toDouble(),
        regime: SalaryRegime.fromValue(m['salaryRegime'] as String),
        hasBonus: m['hasBonus'] as bool,
        weeklyMinutes: m['weeklyMinutes'] as int,
        declarationId: m['declarationId'] as String,
        status: ZonajeStatus.fromValue(m['status'] as String),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
    } on Object catch (e) {
      // One malformed document must not hide the whole list.
      debugPrint('Skipping zonaje request ${doc.id}: $e');
      return null;
    }
  }

  @override
  Future<void> send(ZonajeRequest request) => _collection.add({
    'ownerUid': _ownerUid,
    'previousAddress': request.previousAddress.trim(),
    'currentAddress': request.currentAddress.trim(),
    'distanceKm': request.distanceKm,
    'salaryRegime': request.regime.value,
    'hasBonus': request.hasBonus,
    'weeklyMinutes': request.weeklyMinutes,
    'declarationId': request.declarationId,
    'status': ZonajeStatus.requested.value,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
