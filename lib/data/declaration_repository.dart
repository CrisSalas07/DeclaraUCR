import 'package:declara_ucr/models/declaration.dart';

export 'package:declara_ucr/data/network_status.dart' show OfflineException;

/// Access to declarations (R5). Same pattern as DeclaraHorario: the UI and
/// the state layer only know this interface, never Firestore (DIP). The
/// implementation is `Proyecto1DeclarationRepository`.
abstract class DeclarationRepository {
  /// Registered declarations, most recent first (R1).
  Stream<List<Declaration>> watchAll();

  /// The saved declaration, or `null` if it does not exist (draft recovery).
  /// Throws a [FormatException] if the stored documents are malformed.
  Future<Declaration?> getById(String id);

  /// Creates or updates the declaration and returns its id. Its [status]
  /// says where it should end: BORRADOR, or VALIDADA after validating.
  /// Throws a [DeclarationSaveException] when the save is not possible for
  /// a reason the person can understand (e.g. no reviewer assigned).
  Future<String> save(Declaration declaration);
}

/// A save refused for a reason the person can act on. [message] is in
/// Spanish and shown as is; it never carries technical details.
class DeclarationSaveException implements Exception {
  const DeclarationSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
