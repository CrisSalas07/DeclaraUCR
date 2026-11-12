import 'package:declara_ucr/domain/declarant_history.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/zonaje_screen.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Historial: every declaration and zonaje request of the person, filtered
/// by year and newest first (DeclaraHorario `DeclarantHistory`).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// `null` shows every year.
  int? _year;

  @override
  Widget build(BuildContext context) {
    final declarations =
        context.watch<Loadable<List<Declaration>>>().value ??
        const <Declaration>[];
    final requests =
        context.watch<Loadable<List<ZonajeRequest>>>().value ??
        const <ZonajeRequest>[];
    final years = DeclarantHistory.years(declarations, requests);
    final year = years.contains(_year) ? _year : null;
    final shownDeclarations = DeclarantHistory.declarationsOf(
      declarations,
      year: year,
    );
    final shownRequests = DeclarantHistory.requestsOf(requests, year: year);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: declarations.isEmpty && requests.isEmpty
          ? const EmptyMessage(
              icon: Icons.history,
              title: 'Aún no hay historial.',
              body:
                  'Aquí verá sus declaraciones y solicitudes de zonaje por '
                  'año.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: year == null,
                      onSelected: (_) => setState(() => _year = null),
                    ),
                    for (final y in years)
                      ChoiceChip(
                        label: Text('$y'),
                        selected: year == y,
                        onSelected: (_) => setState(() => _year = y),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Declaraciones (${shownDeclarations.length})',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                if (shownDeclarations.isEmpty)
                  const Text('Sin declaraciones en este año.'),
                for (final d in shownDeclarations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeclarationCard(
                      declaration: d,
                      onTap: () => openDeclaration(context, d.id),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Solicitudes de zonaje (${shownRequests.length})',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                if (shownRequests.isEmpty)
                  const Text('Sin solicitudes en este año.'),
                for (final r in shownRequests) ZonajeRequestTile(request: r),
              ],
            ),
    );
  }
}
