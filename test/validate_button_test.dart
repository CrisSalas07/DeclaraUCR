import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/screens/summary_screen.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Every declaration passes: the test is about the button, not the rules.
class _AlwaysValid extends DeclarationValidator {
  const _AlwaysValid();

  @override
  List<String> missingFields(Declaration d) => const [];

  @override
  List<ValidationIssue> issues(Declaration d) => const [];
}

void main() {
  testWidgets('a validated declaration cannot be validated again until it '
      'changes', (tester) async {
    final db = FakeFirebaseFirestore();
    final state = DeclarationFormState(
      repository: Proyecto1DeclarationRepository(
        db,
        uid: 'ana',
        periods: FirestorePeriodRepository(db, uid: 'ana'),
      ),
      validator: const _AlwaysValid(),
      initial: Declaration(id: 'd1', status: DeclarationStatus.validated),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildUcrTheme(),
        home: ChangeNotifierProvider.value(
          value: state,
          child: const SummaryScreen(),
        ),
      ),
    );
    FilledButton button(String label) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

    expect(button('Validada').onPressed, isNull);

    // Any change sends it back to BORRADOR: it can be validated again.
    state.edit((d) => d.notes = 'Cambio');
    await tester.pump();
    expect(state.declaration.status, DeclarationStatus.draft);
    expect(button('Validar').onPressed, isNotNull);
  });
}
