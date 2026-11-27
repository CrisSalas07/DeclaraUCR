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
  testWidgets('a validated declaration offers signing, not validating again, '
      'until it changes (U-04)', (tester) async {
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

    expect(find.text('Validar'), findsNothing);
    expect(button('Firmar y enviar').onPressed, isNotNull);
    expect(find.text('Validada. Siguiente paso: firmarla.'), findsOneWidget);

    // Any change sends it back to BORRADOR: it can be validated again.
    state.edit((d) => d.notes = 'Cambio');
    await tester.pump();
    expect(state.declaration.status, DeclarationStatus.draft);
    expect(button('Validar').onPressed, isNotNull);
    expect(find.text('Firmar y enviar'), findsNothing);
  });

  testWidgets('Back after validating goes to the start, not to the editor '
      '(U-05)', (tester) async {
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
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildUcrTheme(),
        home: const Text('Inicio'),
      ),
    );
    // Start → editor → summary, as in the app.
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('Editor')),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: state,
          child: const SummaryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Editor'), findsNothing);
    expect(state.declaration.status, DeclarationStatus.validated);
  });
}
