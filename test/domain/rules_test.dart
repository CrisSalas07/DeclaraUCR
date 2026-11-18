import 'package:declara_ucr/domain/declarant_history.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/period_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodRules', () {
    test('one month later keeps the day, or the last of a short month', () {
      expect(
        PeriodRules.addOneMonth(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        PeriodRules.addOneMonth(DateTime(2026, 12, 15)),
        DateTime(2027, 1, 15),
      );
    });

    test('lastsOneMonth', () {
      expect(
        PeriodRules.lastsOneMonth(DateTime(2026, 3, 1), DateTime(2026, 3, 31)),
        isFalse,
      );
      expect(
        PeriodRules.lastsOneMonth(DateTime(2026, 3, 1), DateTime(2026, 4, 1)),
        isTrue,
      );
    });
  });

  test('history: years and declarations newest first', () {
    final old = Declaration(validFrom: DateTime(2025, 3, 1));
    final recent = Declaration(validFrom: DateTime(2026, 8, 1));
    final request = ZonajeRequest(
      id: '2024_I_ana',
      previousAddress: 'San José, Central',
      currentAddress: 'Golfito, Golfito',
      declaredDistanceKm: 300,
      regime: SalaryRegime.composite,
      weeklyMinutes: 1200,
      status: ZonajeStatus.approved,
      createdAt: DateTime(2024, 5, 1),
    );

    expect(DeclarantHistory.years([old, recent], [request]), [
      2026,
      2025,
      2024,
    ]);
    expect(DeclarantHistory.declarationsOf([old, recent]), [recent, old]);
    expect(DeclarantHistory.declarationsOf([old, recent], year: 2025), [old]);
  });

  test('phone: 8 digits starting as the Proyecto 1 rules require', () {
    for (final ok in ['88881234', '22223333', '40001234']) {
      expect(FieldRules.phoneError(ok), isNull, reason: ok);
    }
    for (final bad in ['', '8888-1234', '1234567', '12345678', '888812345']) {
      expect(FieldRules.phoneError(bad), isNotNull, reason: bad);
    }
  });
}
