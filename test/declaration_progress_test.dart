import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/widgets/declaration_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every status is placed on the steps of the web', () {
    int step(DeclarationStatus s) => DeclarationProgress.currentStep(s);
    expect(step(DeclarationStatus.validated), 0);
    expect(step(DeclarationStatus.pendingSupervisorSignature), 2);
    expect(step(DeclarationStatus.receivedByHr), 3);
    expect(step(DeclarationStatus.closed), DeclarationProgress.steps.length);
    for (final status in DeclarationStatus.values) {
      expect(DeclarationProgress.caption(status), isNotEmpty);
    }
  });

  testWidgets('a validated declaration shows the steps and what is next', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeclarationProgress(status: DeclarationStatus.validated),
        ),
      ),
    );
    for (final step in DeclarationProgress.steps) {
      expect(find.text(step), findsOneWidget);
    }
    expect(
      find.text('Validada: falta firmarla y enviarla a su revisor.'),
      findsOneWidget,
    );
  });

  testWidgets('a returned declaration says so on its step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeclarationProgress(status: DeclarationStatus.returned),
        ),
      ),
    );
    expect(find.text('Devuelta'), findsOneWidget);
    expect(find.text('Elaboración'), findsNothing);
  });
}
