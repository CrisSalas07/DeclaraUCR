import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleInterval interval(
  String id,
  int start,
  int end, {
  Weekday day = Weekday.monday,
  String institution = 'UCR',
}) => ScheduleInterval(
  id: id,
  day: day,
  startMinutes: start,
  endMinutes: end,
  institution: institution,
);

/// Complete declaration with fictitious data.
Declaration complete(List<ScheduleInterval> intervals) => Declaration(
  declarantName: 'Ana Pérez Mora',
  identification: '1-1111-1111',
  institution: 'UCR',
  position: 'Docente',
  workdayType: workdayTypes.first,
  validFrom: DateTime(2026, 3, 1),
  validTo: DateTime(2026, 7, 31),
  intervals: intervals,
);

void main() {
  const validator = DeclarationValidator();

  test('mandatory case: Monday 8:00-12:00 and 11:00-14:00 overlap', () {
    final d = complete([
      interval('a', 8 * 60, 12 * 60),
      interval('b', 11 * 60, 14 * 60, institution: 'MEP'),
    ]);

    final issues = validator.scheduleIssues(d);

    expect(issues, hasLength(1));
    expect(issues.single.day, Weekday.monday);
    expect(issues.single.conflictStartMinutes, 11 * 60);
    expect(issues.single.conflictEndMinutes, 12 * 60);
    expect(issues.single.message, contains('11:00-12:00'));
    expect(validator.isValid(d), isFalse);
  });

  test('fixing the overlap makes the declaration valid', () {
    final d = complete([
      interval('a', 8 * 60, 12 * 60),
      interval('b', 12 * 60, 14 * 60),
    ]);

    expect(validator.scheduleIssues(d), isEmpty);
    expect(validator.isValid(d), isTrue);
    expect(d.totalMinutes, 6 * 60);
  });

  test('end before start is reported and adds no hours', () {
    final d = complete([interval('a', 10 * 60, 9 * 60)]);

    final issues = validator.scheduleIssues(d);

    expect(issues.single.code, ValidationIssueCode.invalidTimeRange);
    expect(issues.single.relatedItemIds, ['a']);
    expect(d.totalMinutes, 0);
  });

  test('cannot validate without intervals', () {
    expect(
      validator.scheduleIssues(complete([])).single.code,
      ValidationIssueCode.emptySchedule,
    );
  });

  test('lists the pending required fields', () {
    final missing = validator.missingFields(Declaration());

    expect(missing, contains('Nombre de la persona declarante'));
    expect(missing, contains('Tipo de jornada o nombramiento'));
    expect(missing, hasLength(7));
  });

  test('invalid identification blocks validation', () {
    final d = complete([interval('a', 8 * 60, 10 * 60)])
      ..identification = r'1-1111-1111<script>';

    final issues = validator.fieldIssues(d);

    expect(issues.single.code, ValidationIssueCode.invalidField);
    expect(validator.isValid(d), isFalse);
  });

  test('text longer than its limit blocks validation', () {
    final d = complete([interval('a', 8 * 60, 10 * 60)])
      ..observations = 'x' * (FieldRules.observationsMaxLength + 1);

    expect(validator.fieldIssues(d), hasLength(1));
    expect(validator.isValid(d), isFalse);
  });
}
