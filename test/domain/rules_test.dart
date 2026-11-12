import 'package:declara_ucr/domain/declarant_history.dart';
import 'package:declara_ucr/domain/period_rules.dart';
import 'package:declara_ucr/domain/zonaje_eligibility.dart';
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

  group('ZonajeEligibility', () {
    test('eligible: compuesto, more than 60 km, half time, no bonus', () {
      expect(
        ZonajeEligibility.check(
          regime: SalaryRegime.composite,
          distanceKm: 74,
          weeklyMinutes: 1200,
          hasBonus: false,
        ),
        isEmpty,
      );
    });

    test('lists every reason, in rule order', () {
      expect(
        ZonajeEligibility.check(
          regime: SalaryRegime.global,
          distanceKm: 60,
          weeklyMinutes: 900,
          hasBonus: true,
        ),
        ZonajeIneligibility.values,
      );
    });
  });

  test('history: years and declarations newest first', () {
    final old = Declaration(validFrom: DateTime(2025, 3, 1));
    final recent = Declaration(validFrom: DateTime(2026, 8, 1));
    final request = ZonajeRequest(
      previousAddress: 'San José, Central',
      currentAddress: 'Golfito, Golfito',
      distanceKm: 300,
      regime: SalaryRegime.composite,
      hasBonus: false,
      weeklyMinutes: 1200,
      declarationId: 'd',
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
}
