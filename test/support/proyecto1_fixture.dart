import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Fictitious data in the Proyecto 1 schema, as the web leaves it: a
/// campus and career, the open period [periodId] and, for [uid], a profile
/// with superior and the coordination's assignment of the course "Redes"
/// (IF0009, 1/8 TC: lessons Monday 8:00-10:00).
abstract final class Proyecto1Fixture {
  static const String uid = 'user-a';
  static const String periodId = '2026_II';
  static final DateTime periodStart = DateTime.utc(2026, 8, 10, 6);
  static final DateTime periodEnd = DateTime.utc(2026, 12, 5, 6);

  static const Map<String, Object> profile = {
    'fullName': 'Ana Pérez Mora',
    'identification': '105430987',
    'identificationType': 'CEDULA',
    'phone': '88881234',
    'email': 'ana.perez@ucr.ac.cr',
    'roles': ['declarant'],
    'active': true,
    'campusId': 'sede-sur',
    'unitId': 'ie',
    'superiorUid': 'rev',
  };

  /// Writes the campus, career and period, and, unless they are `null`,
  /// the [user] profile and the [assignment] of [uid].
  static Future<void> seed(
    FakeFirebaseFirestore db, {
    Map<String, Object>? user = profile,
    bool assignment = true,
  }) async {
    await db.collection('campuses').doc('sede-sur').set({
      'name': 'Sede del Sur',
      'active': true,
    });
    await db.collection('units').doc('ie').set({
      'name': 'Informática Empresarial',
      'active': true,
      'campusId': 'sede-sur',
    });
    await db.collection('periods').doc(periodId).set({
      'name': 'II Ciclo - 2026',
      'startDate': Timestamp.fromDate(periodStart),
      'endDate': Timestamp.fromDate(periodEnd),
      'enabled': true,
    });
    if (user != null) {
      await db.collection('users').doc(uid).set(user);
      await db
          .collection('identifications')
          .doc('CEDULA_${user['identification']}')
          .set({'uid': uid});
    }
    if (assignment) {
      await db.collection('workloadAssignments').doc('${periodId}_$uid').set({
        'declarantUid': uid,
        'periodId': periodId,
        'courses': [
          {
            'name': 'Redes',
            'code': 'IF0009',
            'lessonMinutes': 120,
            'workloadMinutes': 300,
          },
        ],
        'slots': [
          {
            'day': 1,
            'startMinutes': 8 * 60,
            'endMinutes': 10 * 60,
            'course': 'Redes',
          },
        ],
      });
    }
  }

  static PeriodRepository periods(FirebaseFirestore db, [String who = uid]) =>
      FirestorePeriodRepository(db, uid: who);

  static Proyecto1DeclarationRepository declarations(
    FirebaseFirestore db, [
    String who = uid,
  ]) => Proyecto1DeclarationRepository(db, uid: who, periods: periods(db, who));
}
