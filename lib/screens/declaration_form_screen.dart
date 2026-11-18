import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/network_status.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:declara_ucr/screens/summary_screen.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:declara_ucr/widgets/schedule_editor.dart';
import 'package:declara_ucr/widgets/workload_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// R2 (form) and R3 (weekly schedule) on a single scrolling screen, split
/// in section cards, with the progress of the required fields on top.
///
/// The person types only names: their own data comes from the profile, the
/// institution is fixed and everything else is picked from a list or placed
/// on the grid.
class DeclarationFormScreen extends StatelessWidget {
  const DeclarationFormScreen({super.key, this.initial});

  final Declaration? initial;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => DeclarationFormState(
      repository: context.read<DeclarationRepository>(),
      network: context.read<NetworkStatus>(),
      initial: initial,
      profile: context.read<UserProfile?>(),
    ),
    child: const _FormBody(),
  );
}

class _FormBody extends StatefulWidget {
  const _FormBody();

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveDraft() async {
    final state = context.read<DeclarationFormState>();
    // Flags the pending required fields (test 03) but saves anyway: it is
    // a draft.
    _formKey.currentState!.validate();
    final ok = await state.saveDraft();
    if (!mounted) return;
    final missing = state.missingFields.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? state.error!
              : missing == 0
              ? 'Borrador guardado.'
              : missing == 1
              ? 'Borrador guardado. Falta 1 dato obligatorio.'
              : 'Borrador guardado. Faltan $missing datos obligatorios.',
        ),
      ),
    );
  }

  void _openSummary() {
    _formKey.currentState!.validate();
    final state = context.read<DeclarationFormState>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: state,
          child: const SummaryScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeclarationFormState>();
    final d = state.declaration;
    final editable = state.editable;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          d.id == null
              ? 'Nueva declaración'
              : editable
              ? 'Editar declaración'
              : 'Declaración',
        ),
        bottom: _ProgressHeader(
          total: state.requiredFieldCount,
          missing: state.missingFields.length,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (!editable) ...[
              _ReadOnlyNotice(declaration: d),
              const SizedBox(height: 16),
            ],
            SectionCard(
              icon: Icons.badge_outlined,
              title: 'Persona declarante',
              subtitle: 'Datos de su cuenta',
              trailing: StatusChip(d.status),
              children: [
                ReadOnlyLine(label: 'Nombre completo', value: d.declarantName),
                ReadOnlyLine(label: 'Cédula', value: d.identification),
              ],
            ),
            SectionCard(
              icon: Icons.work_outline,
              title: 'Nombramiento',
              children: [
                const ReadOnlyLine(
                  label: 'Institución y sede',
                  value: Workplace.full,
                ),
                DropdownButtonFormField<String>(
                  initialValue: Positions.university.contains(d.position)
                      ? d.position
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Puesto *'),
                  items: [
                    for (final p in Positions.university)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  validator: (v) =>
                      v == null ? 'Este campo es obligatorio.' : null,
                  onChanged: editable
                      ? (v) => state.edit((d) => d.position = v ?? '')
                      : null,
                ),
                const SizedBox(height: 16),
                // The validity is the period's: the rules require it.
                if (d.periodName != null)
                  ReadOnlyLine(label: 'Período', value: d.periodName!),
                ReadOnlyLine(
                  label: 'Vigencia',
                  value:
                      '${formatDate(d.validFrom)} – ${formatDate(d.validTo)}',
                ),
              ],
            ),
            _CoursesSection(state: state),
            _CoursesSection(state: state),
            _ProjectsSection(state: state),
            _ExternalJobsSection(state: state),
            SectionCard(
              icon: Icons.calendar_view_week_outlined,
              title: 'Horario semanal',
              subtitle:
                  'Ubicado: ${TimeRules.hoursOf(d.totalMinutes, d.universityMinutes + d.externalMinutes)}',
              children: [
                IgnorePointer(
                  ignoring: !editable,
                  child: const ScheduleEditor(),
                ),
                const SizedBox(height: 8),
              ],
            ),
            _ObservationsSection(state: state),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        secondaryLabel: 'Guardar borrador',
        onSecondary: state.saving || !editable ? null : _saveDraft,
        primaryLabel: 'Ver resumen',
        onPrimary: state.saving ? null : _openSummary,
      ),
    );
  }
}

/// A list of items with edit and delete, and an add button below.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.addLabel,
    required this.onAdd,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String empty;
  final String addLabel;
  final VoidCallback? onAdd;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) => SectionCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    children: [
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            empty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ...items,
      if (onAdd != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
    ],
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.title,
    required this.detail,
    this.onEdit,
    this.onRemove,
  });

  final String title;
  final String detail;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 14, right: 4),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(detail),
        onTap: onEdit,
        trailing: onRemove == null
            ? null
            : IconButton(
                tooltip: 'Quitar $title',
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
      ),
    );
  }
}

/// The courses of the period, as the career coordination assigned them
/// (Proyecto 1): shown with their hours, never edited here.
class _CoursesSection extends StatelessWidget {
  const _CoursesSection({required this.state});

  final DeclarationFormState state;

  @override
  Widget build(BuildContext context) {
    final d = state.declaration;
    final label = WorkloadCatalog.labelFor(d.coursesMinutes);
    return _ItemsCard(
      icon: Icons.menu_book_outlined,
      title: 'Cursos de carrera',
      subtitle: d.courses.isEmpty
          ? 'Los asigna la Coordinación de su carrera'
          : 'Asignados por la Coordinación · '
                '${label ?? TimeRules.hoursLabel(d.coursesMinutes)}',
      empty: 'La Coordinación aún no le asignó cursos en este período.',
      addLabel: '',
      onAdd: null,
      items: [
        for (final c in d.courses)
          _ItemTile(
            title: c.code.isEmpty ? c.name : '${c.code} · ${c.name}',
            detail:
                '${WorkloadCatalog.labelFor(c.workloadMinutes) ?? TimeRules.hoursLabel(c.workloadMinutes)}: '
                '${TimeRules.hoursLabel(c.lessonMinutes)} clase, '
                '${TimeRules.hoursLabel(c.attentionMinutes)} atención, '
                '${TimeRules.hoursLabel(c.planningMinutes)} planificación',
          ),
      ],
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.state});

  final DeclarationFormState state;

  int _free({int? except}) {
    final d = state.declaration;
    final own = except == null ? 0 : d.projects[except].weeklyMinutes;
    return WorkloadCatalog.maxUniversityMinutes - d.universityMinutes + own;
  }

  @override
  Widget build(BuildContext context) {
    final d = state.declaration;
    final editable = state.editable;
    return _ItemsCard(
      icon: Icons.science_outlined,
      title: 'Proyectos',
      subtitle: 'Investigación, acción social u otros, dentro de la UCR',
      empty: 'Sin proyectos.',
      addLabel: 'Agregar proyecto',
      onAdd: !editable
          ? null
          : () => showProjectDialog(
              context,
              freeMinutes: _free(),
              onSave: state.saveProject,
            ),
      items: [
        for (final (i, p) in d.projects.indexed)
          _ItemTile(
            title: p.name,
            detail: '${TimeRules.hoursLabel(p.weeklyMinutes)} por semana',
            onEdit: !editable
                ? null
                : () => showProjectDialog(
                    context,
                    initial: p,
                    freeMinutes: _free(except: i),
                    onSave: (project) => state.saveProject(project, index: i),
                  ),
            onRemove: !editable ? null : () => state.removeProject(i),
          ),
      ],
    );
  }
}

class _ExternalJobsSection extends StatelessWidget {
  const _ExternalJobsSection({required this.state});

  final DeclarationFormState state;

  int _free({int? except}) {
    final d = state.declaration;
    final own = except == null ? 0 : d.externalJobs[except].weeklyMinutes;
    return WorkloadCatalog.maxExternalMinutes - d.externalMinutes + own;
  }

  @override
  Widget build(BuildContext context) {
    final d = state.declaration;
    final editable = state.editable;
    return _ItemsCard(
      icon: Icons.apartment_outlined,
      title: 'Otras instituciones',
      subtitle: 'Opcional: si labora en otra institución',
      empty: 'No declara horas en otras instituciones.',
      addLabel: 'Agregar institución',
      onAdd: !editable
          ? null
          : () => showExternalJobDialog(
              context,
              freeMinutes: _free(),
              onSave: state.saveExternalJob,
            ),
      items: [
        for (final (i, j) in d.externalJobs.indexed)
          _ItemTile(
            title: j.institution,
            detail:
                '${j.type.label} · ${j.position} · '
                '${WorkloadCatalog.labelFor(j.weeklyMinutes) ?? ''} '
                '(${TimeRules.hoursLabel(j.weeklyMinutes)})',
            onEdit: !editable
                ? null
                : () => showExternalJobDialog(
                    context,
                    initial: j,
                    freeMinutes: _free(except: i),
                    onSave: (job) => state.saveExternalJob(job, index: i),
                  ),
            onRemove: !editable ? null : () => state.removeExternalJob(i),
          ),
      ],
    );
  }
}

/// The observations written from the schedule (read only), plus the notes
/// the person may add.
class _ObservationsSection extends StatelessWidget {
  const _ObservationsSection({required this.state});

  final DeclarationFormState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generated = ScheduleObservations.summary(state.declaration);
    return SectionCard(
      icon: Icons.notes_outlined,
      title: 'Observaciones',
      subtitle: 'Se escriben solas a partir del horario',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            generated.isEmpty ? 'Aún no hay horas en el horario.' : generated,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: generated.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : UcrColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.declaration.notes,
          decoration: const InputDecoration(
            labelText: 'Otras observaciones (opcional)',
          ),
          minLines: 1,
          maxLines: 4,
          maxLength: FieldRules.notesMaxLength,
          readOnly: !state.editable,
          onChanged: (v) => state.edit((d) => d.notes = v),
        ),
      ],
    );
  }
}

/// "5 de 7 datos obligatorios" with a bar, under the app bar title.
class _ProgressHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ProgressHeader({required this.total, required this.missing});

  final int total;
  final int missing;

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    final done = total - missing;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 1 : done / total,
                minHeight: 6,
                color: missing == 0 ? UcrColors.green : UcrColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done de $total datos obligatorios',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Why the declaration cannot be edited in the phone, and, when it was
/// returned, the reviewer's or HR's observation.
class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.declaration});

  final Declaration declaration;

  @override
  Widget build(BuildContext context) {
    final returned = declaration.status == DeclarationStatus.returned;
    return InfoBanner(
      icon: returned ? Icons.assignment_return_outlined : Icons.lock_outline,
      tone: returned ? BannerTone.error : BannerTone.info,
      title: returned
          ? 'Su declaración fue devuelta.'
          : 'Esta declaración ya no se edita desde el teléfono.',
      lines: [
        if (returned && (declaration.pendingObservation ?? '').isNotEmpty)
          'Observación: ${declaration.pendingObservation}',
        returned
            ? 'Corríjala en el sistema web: allí se crea la versión nueva.'
            : 'Las firmas, la revisión y Recursos Humanos se atienden en el '
                  'sistema web.',
      ],
    );
  }
}
