import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/screens/declaration_form_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// R1: identifies the system, lists the declarations with their status and
/// lets the user create a new one or open a draft.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _open(BuildContext context, String? id) async {
    final repository = context.read<DeclarationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    Declaration? declaration;
    if (id != null) {
      // Loads the saved version (test 04), not the one in the list.
      try {
        declaration = await repository.getById(id);
      } catch (e) {
        debugPrint('Opening declaration $id failed: $e');
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la declaración.')),
        );
        return;
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeclarationFormScreen(initial: declaration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Declaraciones Juradas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva declaración'),
      ),
      body: Column(
        children: [
          const UcrHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Sistema de Declaraciones Juradas de Horario y Jornada de '
              'Trabajo',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Declaration>>(
              stream: context.read<DeclarationRepository>().watchAll(),
              builder: (context, snap) {
                if (snap.hasError) {
                  // Technical details go to the log, never to the user.
                  debugPrint('Loading declarations failed: ${snap.error}');
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No se pudieron cargar las declaraciones. Revise la '
                        'conexión e intente de nuevo.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay declaraciones registradas.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          d.declarantName.isEmpty
                              ? 'Declaración sin nombre'
                              : d.declarantName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Status goes below, not on the right: the long
                        // PENDIENTE_FIRMA_DECLARANTE does not fit beside it.
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.institution.isEmpty ? 'Sin institución' : d.institution}\n'
                              '${formatDate(d.validFrom)} – ${formatDate(d.validTo)} · '
                              '${TimeRules.hoursLabel(d.totalMinutes)}',
                            ),
                            const SizedBox(height: 6),
                            StatusChip(d.status),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(context, d.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
