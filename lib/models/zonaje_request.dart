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

/// Status of a zonaje request, with the names of the original system. This
/// app only sends requests: HR review is out of scope, like signatures.
enum ZonajeStatus {
  requested('SOLICITADA'),
  approved('APROBADA'),
  rejected('RECHAZADA'),
  annulled('ANULADA');

  const ZonajeStatus(this.value);

  final String value;

  static ZonajeStatus fromValue(String value) => ZonajeStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => throw ArgumentError('Unknown ZonajeStatus: $value'),
  );
}

/// A zonaje request (Reglamento General de Zonaje y Bonificación, UCR).
class ZonajeRequest {
  const ZonajeRequest({
    this.id,
    required this.previousAddress,
    required this.currentAddress,
    required this.distanceKm,
    required this.regime,
    required this.hasBonus,
    required this.weeklyMinutes,
    required this.declarationId,
    this.status = ZonajeStatus.requested,
    this.createdAt,
  });

  final String? id;
  final String previousAddress;
  final String currentAddress;

  /// Distance between the previous and the current home, as declared.
  final double distanceKm;
  final SalaryRegime regime;

  /// Whether the person already receives bonificación.
  final bool hasBonus;

  /// Workday of the courses of [declarationId] when it was sent.
  final int weeklyMinutes;

  /// The VALIDADA declaration whose courses give the workday.
  final String declarationId;
  final ZonajeStatus status;
  final DateTime? createdAt;
}
