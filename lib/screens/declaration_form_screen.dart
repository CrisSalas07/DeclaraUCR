import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/period_rules.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration.dart';
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

  Future<DateTime?> _pickDate(DateTime? current, {DateTime? first}) {
    final firstDate = first ?? DateTime(2020);
    final initial = current == null || current.isBefore(firstDate)
        ? firstDate.isAfter(DateTime.now())
              ? firstDate
              : DateTime.now()
        : current;
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2035),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeclarationFormState>();
    final d = state.declaration;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.id == null ? 'Nueva declaración' : 'Editar declaración'),
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
                  onChanged: (v) => state.edit((d) => d.position = v ?? ''),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: appointmentTypes.contains(d.appointmentType)
                      ? d.appointmentType
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de nombramiento *',
                  ),
                  items: [
                    for (final t in appointmentTypes)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  validator: (v) =>
                      v == null ? 'Este campo es obligatorio.' : null,
                  onChanged: (v) => state.edit((d) => d.appointmentType = v),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Inicio de vigencia *',
                        value: d.validFrom,
                        onTap: () async {
                          final picked = await _pickDate(d.validFrom);
                          if (picked == null) return;
                          state.edit((d) {
                            d.validFrom = picked;
                            // Keeps the end valid: at least one month later.
                            if (d.validTo != null &&
                                !PeriodRules.lastsOneMonth(
                                  picked,
                                  d.validTo!,
                                )) {
                              d.validTo = PeriodRules.minEnd(picked);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Fin de vigencia *',
                        value: d.validTo,
                        onTap: () async {
                          final picked = await _pickDate(
                            d.validTo,
                            first: d.validFrom == null
                                ? null
                                : PeriodRules.minEnd(d.validFrom!),
                          );
                          if (picked != null) {
                            state.edit((d) => d.validTo = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                  child: Text(
                    'El período dura al menos un mes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            _CoursesSection(state: state),
            _ProjectsSection(state: state),
            _ExternalJobsSection(state: state),
            SectionCard(
              icon: Icons.calendar_view_week_outlined,
              title: 'Horario semanal',
              subtitle:
                  'Ubicado: ${TimeRules.hoursOf(d.totalMinutes, d.universityMinutes + d.externalMinutes)}',
              children: const [ScheduleEditor(), SizedBox(height: 8)],
            ),
            _ObservationsSection(state: state),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        secondaryLabel: 'Guardar borrador',
        onSecondary: state.saving ? null : _saveDraft,
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
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String detail;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

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
        trailing: IconButton(
          tooltip: 'Quitar $title',
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _CoursesSection extends StatelessWidget {
  const _CoursesSection({required this.state});

  final DeclarationFormState state;

  int _free({int? except}) {
    final d = state.declaration;
    final own = except == null ? 0 : d.courses[except].workloadMinutes;
    return WorkloadCatalog.maxUniversityMinutes - d.universityMinutes + own;
  }

  @override
  Widget build(BuildContext context) {
    final d = state.declaration;
    final label = WorkloadCatalog.labelFor(d.coursesMinutes);
    return _ItemsCard(
      icon: Icons.menu_book_outlined,
      title: 'Cursos de carrera',
      subtitle: d.courses.isEmpty
          ? 'La jornada de cada curso fija sus horas'
          : 'Jornada en cursos: ${label ?? TimeRules.hoursLabel(d.coursesMinutes)}',
      empty: 'Aún no agrega cursos.',
      addLabel: 'Agregar curso',
      onAdd: () => showCourseDialog(
        context,
        freeMinutes: _free(),
        onSave: state.saveCourse,
      ),
      items: [
        for (final (i, c) in d.courses.indexed)
          _ItemTile(
            title: c.code.isEmpty ? c.name : '${c.code} · ${c.name}',
            detail:
                '${WorkloadCatalog.labelFor(c.workloadMinutes)}: '
                '${TimeRules.hoursLabel(c.lessonMinutes)} clase, '
                '${TimeRules.hoursLabel(c.attentionMinutes)} atención, '
                '${TimeRules.hoursLabel(c.planningMinutes)} planificación',
            onEdit: () => showCourseDialog(
              context,
              initial: c,
              freeMinutes: _free(except: i),
              onSave: (course) => state.saveCourse(course, index: i),
            ),
            onRemove: () => state.removeCourse(i),
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
    return _ItemsCard(
      icon: Icons.science_outlined,
      title: 'Proyectos',
      subtitle: 'Investigación, acción social u otros, dentro de la UCR',
      empty: 'Sin proyectos.',
      addLabel: 'Agregar proyecto',
      onAdd: () => showProjectDialog(
        context,
        freeMinutes: _free(),
        onSave: state.saveProject,
      ),
      items: [
        for (final (i, p) in d.projects.indexed)
          _ItemTile(
            title: p.name,
            detail: '${TimeRules.hoursLabel(p.weeklyMinutes)} por semana',
            onEdit: () => showProjectDialog(
              context,
              initial: p,
              freeMinutes: _free(except: i),
              onSave: (project) => state.saveProject(project, index: i),
            ),
            onRemove: () => state.removeProject(i),
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
    return _ItemsCard(
      icon: Icons.apartment_outlined,
      title: 'Otras instituciones',
      subtitle: 'Opcional: si labora en otra institución',
      empty: 'No declara horas en otras instituciones.',
      addLabel: 'Agregar institución',
      onAdd: () => showExternalJobDialog(
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
            onEdit: () => showExternalJobDialog(
              context,
              initial: j,
              freeMinutes: _free(except: i),
              onSave: (job) => state.saveExternalJob(job, index: i),
            ),
            onRemove: () => state.removeExternalJob(i),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    // Rebuilt with the new value so validation sees it.
    key: ValueKey(value),
    initialValue: value,
    validator: (v) => v == null ? 'Seleccione una fecha.' : null,
    builder: (field) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: field.errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(formatDate(value)),
      ),
    ),
  );
}
