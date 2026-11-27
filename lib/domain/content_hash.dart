import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Fingerprint (SHA-256) of a version's declared content, stored with the
/// declarant's signature and in the locked version: it shows the signed
/// content was not changed afterwards.
///
/// It must be EXACTLY `ContentHashService.computeVersionHash` of
/// DeclaraHorario (Proyecto 1): the superior and HR sign that same hash, and
/// a different serialization would give a declaration signed in the phone
/// another fingerprint than the web would compute. It works on the stored
/// documents, reading each field as DeclaraHorario's models do (same
/// defaults), and builds the same canonical JSON: the same keys in the same
/// order, lists sorted by their JSON form, dates as epoch milliseconds, and
/// optional parts only when present. `test/domain/content_hash_test.dart`
/// checks it against a hash computed by DeclaraHorario's own code.
abstract final class ContentHash {
  /// SHA-256 (hex) of the version [version] (`versions/{id}`) with its
  /// [appointments] and [externalJobs] documents. Throws a [TypeError] if a
  /// required field is missing, as DeclaraHorario's models do.
  static String of({
    required Map<String, dynamic> version,
    required List<Map<String, dynamic>> appointments,
    required List<Map<String, dynamic>> externalJobs,
  }) {
    final declarant = Map<String, dynamic>.from(
      version['declarantSnapshot'] as Map,
    );
    final campusName = declarant['campusName'] as String? ?? '';
    final canonical = <String, Object?>{
      'versionNumber': version['number'] as int,
      'declarant': {
        'fullName': declarant['fullName'] as String,
        'identification': declarant['identification'] as String,
        'phone': declarant['phone'] as String,
        'email': declarant['email'] as String,
        'unitName': declarant['unitName'] as String,
        if (campusName.isNotEmpty) 'campusName': campusName,
      },
      'observations': version['observations'] as String? ?? '',
      'appointments': _sorted(appointments.map(_appointment)),
      'externalJobs': _sorted(externalJobs.map(_externalJob)),
    };
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  static Map<String, Object?> _appointment(Map<String, dynamic> map) {
    final projects = [
      for (final raw in map['projects'] as List<dynamic>? ?? const [])
        Map<String, dynamic>.from(raw as Map),
    ];
    return {
      'workplace': map['workplace'] as String,
      'position': map['position'] as String,
      'workload': map['workload'] as String,
      'startDate': _millis(map['startDate']),
      'endDate': _millis(map['endDate']),
      'blocks': _blocks(map['blocks']),
      if (projects.isNotEmpty)
        'projects': _sorted(
          projects.map(
            (p) => <Object?>[p['name'] as String, p['weeklyMinutes'] as int],
          ),
        ),
    };
  }

  static Map<String, Object?> _externalJob(Map<String, dynamic> map) {
    final weeklyMinutes = map['weeklyMinutes'] as int?;
    return {
      'institution': map['institution'] as String,
      'institutionType': map['institutionType'] as String,
      'position': map['position'] as String,
      'workload': map['workload'] as String,
      'startDate': _millis(map['startDate']),
      'endDate': _millis(map['endDate']),
      'blocks': _blocks(map['blocks']),
      'weeklyMinutes': ?weeklyMinutes,
    };
  }

  /// Each block as `[day, start, end, category?, course?]`.
  static List<Object?> _blocks(Object? raw) => _sorted(
    (raw as List<dynamic>).map((b) {
      final block = Map<String, dynamic>.from(b as Map);
      final category = block['category'] as String?;
      final course = block['course'] as String?;
      return <Object?>[
        block['day'] as int,
        block['startMinutes'] as int,
        block['endMinutes'] as int,
        ?category,
        if (course != null && course.isNotEmpty) course,
      ];
    }),
  );

  static int _millis(Object? value) =>
      (value as Timestamp).toDate().millisecondsSinceEpoch;

  /// Firestore does not guarantee read order: every list is sorted by its
  /// JSON form (arbitrary, but always the same).
  static List<Object?> _sorted(Iterable<Object?> items) =>
      items.toList()..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
}
