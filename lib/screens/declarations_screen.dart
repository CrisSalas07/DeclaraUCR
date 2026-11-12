import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/screens/declaration_form_screen.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the form: a new declaration when [id] is `null`, else the saved
/// version of [id] (test 04), not the one in the list.
Future<void> openDeclaration(BuildContext context, String? id) async {
  final repository = context.read<DeclarationRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  Declaration? declaration;
  if (id != null) {
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
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => DeclarationFormScreen(initial: declaration),
    ),
  );
}

/// R1: the person's declarations with their statuses; the counts work as
/// filters. Creates new declarations and opens drafts.
class DeclarationsScreen extends StatefulWidget {
  const DeclarationsScreen({super.key});

  @override
  State<DeclarationsScreen> createState() => _DeclarationsScreenState();
}

class _DeclarationsScreenState extends State<DeclarationsScreen> {
  /// `null` shows every declaration.
  DeclarationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<Loadable<List<Declaration>>>();
    final all = loaded.value ?? const <Declaration>[];
    final visible = _filter == null
        ? all
        : all.where((d) => d.status == _filter).toList();
    int count(DeclarationStatus s) => all.where((d) => d.status == s).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis declaraciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDeclaration(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva declaración'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _FilterTile(
                  label: 'Todas',
                  count: all.length,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 10),
                _FilterTile(
                  label: 'Borradores',
                  count: count(DeclarationStatus.draft),
                  selected: _filter == DeclarationStatus.draft,
                  onTap: () =>
                      setState(() => _filter = DeclarationStatus.draft),
                ),
                const SizedBox(width: 10),
                _FilterTile(
                  label: 'Validadas',
                  count: count(DeclarationStatus.validated),
                  selected: _filter == DeclarationStatus.validated,
                  onTap: () =>
                      setState(() => _filter = DeclarationStatus.validated),
                ),
              ],
            ),
          ),
          Expanded(
            child: loaded.failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'No se pudieron cargar las declaraciones.',
                    body: 'Revise la conexión e intente de nuevo.',
                  )
                : loaded.loading
                ? const Center(child: CircularProgressIndicator())
                : all.isEmpty
                ? const EmptyMessage(
                    icon: Icons.post_add_rounded,
                    title: 'Aún no hay declaraciones registradas.',
                    body:
                        'Cree su primera declaración jurada de horario con el '
                        'botón «Nueva declaración».',
                  )
                : visible.isEmpty
                ? const EmptyMessage(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No hay declaraciones en este estado.',
                    body: 'Toque «Todas» para ver la lista completa.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => DeclarationCard(
                      declaration: visible[i],
                      onTap: () => openDeclaration(context, visible[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Count by status that also works as a filter toggle.
class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final foreground = selected ? UcrColors.white : UcrColors.ink;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '$label: $count',
        excludeSemantics: true,
        child: Material(
          color: selected
              ? UcrColors.blue
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: text.headlineSmall?.copyWith(color: foreground),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One declaration in a list: position and workday, validity, hours and
/// status.
class DeclarationCard extends StatelessWidget {
  const DeclarationCard({
    super.key,
    required this.declaration,
    required this.onTap,
  });

  final Declaration declaration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = declaration;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final statusColor = theme.extension<StatusColors>()!.of(d.status);
    final workday = WorkloadCatalog.labelFor(d.coursesMinutes);
    final title = [if (d.position.isNotEmpty) d.position, ?workday].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: UcrColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Declaración sin completar' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.courses.isEmpty
                          ? Workplace.full
                          : d.courses.map((c) => c.shortName).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _Meta(
                          Icons.event_outlined,
                          '${formatDate(d.validFrom)} – '
                          '${formatDate(d.validTo)}',
                        ),
                        _Meta(
                          Icons.schedule_outlined,
                          TimeRules.hoursLabel(d.totalMinutes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status goes below: the long PENDIENTE_FIRMA_DECLARANTE
                    // does not fit beside the title.
                    StatusChip(d.status),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Centered icon, title and explanation for empty or failed lists.
class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 104),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: UcrColors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
