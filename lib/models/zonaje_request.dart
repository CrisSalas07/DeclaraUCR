/// Salary regime of the teacher (DeclaraHorario `SalaryRegime`).
enum SalaryRegime {
  composite('COMPUESTO', 'Salario compuesto'),
  global('GLOBAL', 'Salario global');

  const SalaryRegime(this.value, this.label);

  final String value;
  final String label;

  static SalaryRegime fromValue(String value) => SalaryRegime.values.firstWhere(
    (r) => r.value == value,
    orElse: () => throw ArgumentError('Unknown SalaryRegime: $value'),
  );
}

/// Status of a zonaje request, with the names of the Proyecto 1.
enum ZonajeStatus {
  requested('SOLICITADA', 'En revisión de RRHH'),
  approved('APROBADA', 'Aprobada'),
  rejected('RECHAZADA', 'Rechazada'),
  annulled('ANULADA', 'Anulada');

  const ZonajeStatus(this.value, this.label);

  /// Stored value.
  final String value;

  /// What it means for the person, in Spanish.
  final String label;

  static ZonajeStatus fromValue(String value) => ZonajeStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => throw ArgumentError('Unknown ZonajeStatus: $value'),
  );
}

/// A zonaje request of the Proyecto 1 (`zonajeRequests/{periodId}_{uid}`),
/// read only: it is made in the web system, which asks for the home on a
/// map and the TSE certificate. HR reviews it there.
class ZonajeRequest {
  const ZonajeRequest({
    required this.id,
    required this.previousAddress,
    required this.currentAddress,
    required this.declaredDistanceKm,
    required this.regime,
    required this.weeklyMinutes,
    required this.status,
    this.periodId,
    this.createdAt,
    this.confirmedDistanceKm,
    this.hrObservation,
    this.reviewedAt,
    this.annulReason,
  });

  final String id;

  /// Period of the declaration it is based on (older requests have none).
  final String? periodId;
  final String previousAddress;
  final String currentAddress;

  /// Distance the person declared.
  final double declaredDistanceKm;

  /// Distance HR confirmed when it approved the request.
  final double? confirmedDistanceKm;
  final SalaryRegime regime;

  /// Workday assigned in the period when it was sent.
  final int weeklyMinutes;
  final ZonajeStatus status;
  final DateTime? createdAt;

  /// Why HR rejected it.
  final String? hrObservation;
  final DateTime? reviewedAt;

  /// Why HR annulled an approved request.
  final String? annulReason;

  /// The confirmed distance once there is one, else the declared one.
  double get distanceKm => confirmedDistanceKm ?? declaredDistanceKm;
}
