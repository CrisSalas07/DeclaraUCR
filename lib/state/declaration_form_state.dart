import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:flutter/foundation.dart';

/// State of the form and the summary of one declaration (R2, R3, R4, R6).
///
/// Depends on abstractions injected through the constructor (repository and
/// validator), so it can be tested without Firebase.
class DeclarationFormState extends ChangeNotifier {
  DeclarationFormState({
    required this._repository,
    this._validator = const DeclarationValidator(),
    Declaration? initial,
  }) : declaration = initial?.copy() ?? Declaration();

  final DeclarationRepository _repository;
  final DeclarationValidator _validator;
  final Declaration declaration;

  bool saving = false;

  /// User-facing message of the last failed save, in Spanish.
  String? error;
  int _nextId = 0;

  List<String> get missingFields => _validator.missingFields(declaration);
  List<ValidationIssue> get issues => _validator.issues(declaration);
  bool get canValidate => _validator.isValid(declaration);

  /// Problems that involve one interval, to show them on its card.
  List<ValidationIssue> issuesFor(String intervalId) => _validator
      .scheduleIssues(declaration)
      .where((i) => i.relatedItemIds.contains(intervalId))
      .toList();

  /// Applies a change. As in DeclaraHorario, editing a VALIDADA declaration
  /// sends it back to BORRADOR until it is validated again.
  void edit(void Function(Declaration d) change) {
    change(declaration);
    if (declaration.status == DeclarationStatus.validated) {
      declaration.status = DeclarationStatus.draft;
    }
    notifyListeners();
  }

  void addInterval() => edit((d) {
    final last = d.intervals.isEmpty ? null : d.intervals.last;
    d.intervals.add(
      ScheduleInterval(
        id: '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
        day: last?.day ?? Weekday.monday,
        startMinutes: last?.endMinutes ?? 8 * 60,
        endMinutes: (last?.endMinutes ?? 8 * 60) + 2 * 60,
        institution: d.institution,
      ),
    );
  });

  void removeInterval(String id) =>
      edit((d) => d.intervals.removeWhere((i) => i.id == id));

  /// Saves as BORRADOR (R5). Does not require complete fields.
  Future<bool> saveDraft() => _save(DeclarationStatus.draft);

  /// Moves to VALIDADA only with no missing fields and no problems (R4).
  Future<bool> validateAndSave() async {
    if (!canValidate) return false;
    return _save(DeclarationStatus.validated);
  }

  Future<bool> _save(DeclarationStatus status) async {
    saving = true;
    error = null;
    notifyListeners();
    final previous = declaration.status;
    try {
      declaration.status = status;
      await _repository.save(declaration);
      return true;
    } catch (e) {
      declaration.status = previous;
      // Technical details go to the log, never to the user.
      debugPrint('Saving declaration failed: $e');
      error = 'No se pudo guardar. Revise la conexión e intente de nuevo.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
