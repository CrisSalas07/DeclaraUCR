import 'package:declara_ucr/models/zonaje_request.dart';

/// One reason why a teacher cannot receive zonaje (RF-8.2).
enum ZonajeIneligibility {
  /// R16: only teachers under salario compuesto.
  notCompositeSalary,

  /// R17: the previous and current home must be more than 60 km apart.
  distanceTooShort,

  /// R18: the workday must be at least half time.
  workloadBelowHalfTime,

  /// R19: zonaje and bonificación cannot be held at the same time.
  alreadyHasBonus,
}

/// Limits of the Reglamento General de Zonaje y Bonificación (UCR, 2014).
/// firestore.rules repeats them: change both together.
abstract final class ZonajeLimits {
  /// R17: the distance must be strictly greater than this, in km (art. 8).
  static const double minDistanceKm = 60;

  /// R18: half time, 20 weekly hours (art. 4 d).
  static const int minWeeklyMinutes = 20 * 60;

  static const int maxAddressLength = 300;
  static const double maxDistanceKm = 1000;
}

/// Eligibility rules for zonaje (R16 to R19), reused from DeclaraHorario
/// (`ZonajeEligibility`). Pure Dart.
abstract final class ZonajeEligibility {
  /// Every reason why the teacher cannot receive zonaje, in rule order; an
  /// empty list means eligible. [weeklyMinutes] is the workday of the
  /// courses of a VALIDADA declaration (zero without one).
  static List<ZonajeIneligibility> check({
    required SalaryRegime regime,
    required double distanceKm,
    required int weeklyMinutes,
    required bool hasBonus,
  }) => [
    if (regime != SalaryRegime.composite)
      ZonajeIneligibility.notCompositeSalary,
    if (distanceKm <= ZonajeLimits.minDistanceKm)
      ZonajeIneligibility.distanceTooShort,
    if (weeklyMinutes < ZonajeLimits.minWeeklyMinutes)
      ZonajeIneligibility.workloadBelowHalfTime,
    if (hasBonus) ZonajeIneligibility.alreadyHasBonus,
  ];

  static String message(ZonajeIneligibility reason) => switch (reason) {
    ZonajeIneligibility.notCompositeSalary =>
      'El zonaje solo aplica para salario compuesto. Con salario global, el '
          'desarraigo lo autoriza la Sede Regional.',
    ZonajeIneligibility.distanceTooShort =>
      'La distancia entre el domicilio anterior y el actual debe ser mayor '
          'de ${ZonajeLimits.minDistanceKm.toInt()} km.',
    ZonajeIneligibility.workloadBelowHalfTime =>
      'Su jornada en cursos debe ser de al menos ½ tiempo (20 horas).',
    ZonajeIneligibility.alreadyHasBonus =>
      'No puede tener zonaje y bonificación al mismo tiempo.',
  };
}
