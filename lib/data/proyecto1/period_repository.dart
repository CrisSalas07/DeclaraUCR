import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_mapper.dart';
import 'package:declara_ucr/models/period.dart';
import 'package:flutter/foundation.dart';

export 'package:declara_ucr/models/period.dart';

/// Declaration periods and the career coordination's course assignment of
/// one person (DIP: the UI never sees Firestore).
abstract class PeriodRepository {
  /// Periods open for new declarations, newest first.
  Stream<List<Period>> watchEnabled();

  /// The period [id], open or not, or `null` if it does not exist.
  Future<Period?> getById(String id);

  /// The courses and lesson slots assigned to the person in [periodId], or
  /// `null` while the coordination has not assigned any.
  Future<WorkloadAssignment?> assignmentFor(String periodId);
}

class FirestorePeriodRepository implements PeriodRepository {
  FirestorePeriodRepository(this._firestore, {required this._uid});

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _periods =>
      _firestore.collection('periods');

  @override
  Stream<List<Period>> watchEnabled() => _periods
      .where('enabled', isEqualTo: true)
      .snapshots()
      .map(
        (snap) =>
            [for (final doc in snap.docs) ?_tryPeriod(doc.id, doc.data())]
              ..sort((a, b) => b.startDate.compareTo(a.startDate)),
      );

  /// A malformed period is skipped and logged, not the whole list.
  static Period? _tryPeriod(String id, Map<String, dynamic> data) {
    try {
      return Proyecto1Mapper.period(id, data);
    } on FormatException catch (e) {
      debugPrint('Skipping period: ${e.message}');
      return null;
    }
  }

  @override
  Future<Period?> getById(String id) async {
    final data = (await _periods.doc(id).get()).data();
    return data == null ? null : Proyecto1Mapper.period(id, data);
  }

  /// `workloadAssignments/{periodId}_{uid}`: the rules let a person read
  /// only their own, by its id.
  @override
  Future<WorkloadAssignment?> assignmentFor(String periodId) async {
    final data =
        (await _firestore
                .collection('workloadAssignments')
                .doc('${periodId}_$_uid')
                .get())
            .data();
    return data == null ? null : Proyecto1Mapper.assignment(data);
  }
}
