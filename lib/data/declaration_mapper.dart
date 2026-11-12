import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';

/// Converts [Declaration]s to and from Firestore documents. Keeps Firestore
/// types (such as [Timestamp]) out of the model layer.
///
/// Stored documents are untrusted input: [fromMap] checks every type and
/// throws a [FormatException] instead of building a half-valid object.
class DeclarationMapper {
  const DeclarationMapper();

  Map<String, dynamic> toMap(Declaration d) => <String, dynamic>{
    'declarantName': d.declarantName,
    'identification': d.identification,
    'institution': d.institution,
    'position': d.position,
    'workdayType': d.workdayType,
    'validFrom': _toTimestamp(d.validFrom),
    'validTo': _toTimestamp(d.validTo),
    'additionalInstitutions': d.additionalInstitutions,
    'observations': d.observations,
    'intervals': d.intervals.map(_intervalToMap).toList(),
    'status': d.status.value,
    'updatedAt': _toTimestamp(d.updatedAt),
  };

  Declaration fromMap(String id, Map<String, dynamic> map) {
    try {
      return Declaration(
        id: id,
        declarantName: map['declarantName'] as String? ?? '',
        identification: map['identification'] as String? ?? '',
        institution: map['institution'] as String? ?? '',
        position: map['position'] as String? ?? '',
        workdayType: map['workdayType'] as String?,
        validFrom: (map['validFrom'] as Timestamp?)?.toDate(),
        validTo: (map['validTo'] as Timestamp?)?.toDate(),
        additionalInstitutions: map['additionalInstitutions'] as String? ?? '',
        observations: map['observations'] as String? ?? '',
        intervals: (map['intervals'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => _intervalFromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        status: DeclarationStatus.fromValue(
          map['status'] as String? ?? DeclarationStatus.draft.value,
        ),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed declaration $id: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed declaration $id: ${e.message}');
    }
  }

  Map<String, dynamic> _intervalToMap(ScheduleInterval i) => <String, dynamic>{
    'id': i.id,
    'day': i.day.number,
    'startMinutes': i.startMinutes,
    'endMinutes': i.endMinutes,
    'institution': i.institution,
  };

  ScheduleInterval _intervalFromMap(Map<String, dynamic> map) =>
      ScheduleInterval(
        id: map['id'] as String,
        day: Weekday.fromNumber(map['day'] as int),
        startMinutes: map['startMinutes'] as int,
        endMinutes: map['endMinutes'] as int,
        institution: map['institution'] as String? ?? '',
      );

  static Timestamp? _toTimestamp(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);
}
