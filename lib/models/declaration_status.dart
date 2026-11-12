/// Procedure statuses. [value] keeps the exact names of the original system
/// (R1), which are stored in Firestore and shown to the user. SHARED CONTRACT.
///
/// `NUEVA VERSIÓN` in the diagram is NOT a status: it is an action that
/// creates version N+1 and leaves the declaration in BORRADOR (assumption,
/// doubt 1).
enum DeclarationStatus {
  /// Being edited by the declarant.
  draft('BORRADOR'),

  /// Passed validation without blocking errors.
  validated('VALIDADA'),

  /// Waiting for the declarant's signature.
  pendingDeclarantSignature('PENDIENTE_FIRMA_DECLARANTE'),

  /// Signed by the declarant; the version is locked.
  signedByDeclarant('FIRMADA_POR_DECLARANTE'),

  /// Waiting for the supervisor's signature.
  pendingSupervisorSignature('PENDIENTE_FIRMA_SUPERIOR'),

  /// Returned to the declarant with an observation.
  returned('DEVUELTA'),

  /// Signed by the supervisor.
  signedBySupervisor('FIRMADA_POR_SUPERIOR'),

  /// Sent to Human Resources.
  sentToHr('ENVIADA_A_RRHH'),

  /// Received by Human Resources.
  receivedByHr('RECIBIDA_RRHH'),

  /// Procedure closed.
  closed('FINALIZADA'),

  /// Procedure annulled.
  annulled('ANULADA');

  const DeclarationStatus(this.value);

  /// Value stored in Firestore and shown to the user.
  final String value;

  /// Returns the status whose [value] matches; throws an [ArgumentError] for
  /// an unknown value.
  static DeclarationStatus fromValue(String value) =>
      DeclarationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw ArgumentError('Unknown DeclarationStatus: $value'),
      );
}
