import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/domain/schedule_requirements.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// R6: summary with data, schedule, total, validation results and status.
/// Lets the user go back to fix things and, with no problems, mark the
/// declaration as VALIDADA.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  Future<void> _validate(BuildContext context) async {
    final state = context.read<DeclarationFormState>();
    final ok = await state.validateAndSave();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Declaración validada y guardada.'
              : state.error ?? 'Corrija los problemas antes de validar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeclarationFormState>();
    final d = state.declaration;
    final problems = [
      for (final field in state.missingFields) 'Falta: $field.',
      for (final issue in state.issues) issue.message,
    ];
    final sorted = d.sortedIntervals;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de la declaración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Hero(declaration: d),
          const SizedBox(height: 16),
          if (problems.isEmpty)
            const InfoBanner(
              icon: Icons.check_circle_outline,
              title: 'Sin problemas: la declaración puede validarse.',
              tone: BannerTone.success,
            )
          else
            InfoBanner(
              icon: Icons.error_outline,
              title: problems.length == 1
                  ? 'Hay 1 punto por corregir'
                  : 'Hay ${problems.length} puntos por corregir',
              lines: problems,
              tone: BannerTone.error,
            ),
          const SizedBox(height: 16),
          _HoursCard(declaration: d),
          SectionCard(
            icon: Icons.calendar_view_week_outlined,
            title: 'Horario semanal',
            children: [
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Sin intervalos registrados.'),
                )
              else ...[
                WeekOverview(intervals: sorted),
                const SizedBox(height: 16),
                const Divider(),
                for (final i in sorted)
                  _IntervalLine(i, ScheduleRequirements.describe(i.task, d)),
              ],
            ],
          ),
          SectionCard(
            icon: Icons.badge_outlined,
            title: 'Datos generales',
            children: [
              ReadOnlyLine(label: 'Nombre', value: d.declarantName),
              ReadOnlyLine(label: 'Cédula', value: d.identification),
            ],
          ),
          SectionCard(
            icon: Icons.work_outline,
            title: 'Información laboral',
            children: [
              ReadOnlyLine(label: 'Institución y sede', value: d.institution),
              ReadOnlyLine(label: 'Puesto', value: d.position),
              ReadOnlyLine(
                label: 'Tipo de nombramiento',
                value: d.appointmentType ?? '',
              ),
              ReadOnlyLine(
                label: 'Vigencia',
                value: '${formatDate(d.validFrom)} – ${formatDate(d.validTo)}',
              ),
              ReadOnlyLine(
                label: 'Cursos',
                value: d.courses
                    .map((c) => c.code.isEmpty ? c.name : '${c.code} ${c.name}')
                    .join('\n'),
              ),
              ReadOnlyLine(
                label: 'Proyectos',
                value: d.projects
                    .map(
                      (p) =>
                          '${p.name} (${TimeRules.hoursLabel(p.weeklyMinutes)})',
                    )
                    .join('\n'),
              ),
              ReadOnlyLine(
                label: 'Otras instituciones',
                value: d.externalJobs
                    .map(
                      (j) =>
                          '${j.institution} · ${j.position} '
                          '(${TimeRules.hoursLabel(j.weeklyMinutes)})',
                    )
                    .join('\n'),
              ),
              ReadOnlyLine(
                label: 'Observaciones',
                value: ScheduleObservations.compose(d),
              ),
            ],
          ),
          // Lab scope limit: no signature is simulated.
          const InfoBanner(
            icon: Icons.info_outline,
            title: 'Alcance de esta aplicación',
            lines: [
              'La firma digital, la aprobación del superior y la recepción en '
                  'Recursos Humanos no forman parte de esta aplicación.',
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        secondaryLabel: 'Corregir',
        onSecondary: () => Navigator.of(context).pop(),
        primaryLabel: 'Validar',
        onPrimary: state.canValidate && !state.saving
            ? () => _validate(context)
            : null,
      ),
    );
  }
}

/// Gradient card: who declares, current status and total hours.
class _Hero extends StatelessWidget {
  const _Hero({required this.declaration});

  final Declaration declaration;

  @override
  Widget build(BuildContext context) {
    final d = declaration;
    final text = Theme.of(context).textTheme;
    final soft = UcrColors.white.withValues(alpha: 0.82);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: UcrColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Estado', style: text.labelLarge?.copyWith(color: soft)),
              const SizedBox(width: 10),
              Flexible(child: StatusChip(d.status, onDark: true)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            d.declarantName.trim().isEmpty
                ? 'Declaración sin nombre'
                : d.declarantName,
            style: text.titleLarge?.copyWith(color: UcrColors.white),
          ),
          if (d.position.isNotEmpty || d.institution.isNotEmpty)
            Text(
              [
                d.position,
                ?WorkloadCatalog.labelFor(d.coursesMinutes),
                d.institution,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: text.bodyMedium?.copyWith(color: soft),
            ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TimeRules.hoursLabel(d.totalMinutes),
                style: text.displaySmall?.copyWith(
                  color: UcrColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'por semana',
                  style: text.bodyMedium?.copyWith(color: soft),
                ),
              ),
            ],
          ),
          // Exact wording kept for screen readers and tests.
          Text(
            'Total de horas: ${TimeRules.hoursLabel(d.totalMinutes)}',
            style: text.labelMedium?.copyWith(color: soft),
          ),
        ],
      ),
    );
  }
}

/// Expected versus placed hours: each kind of course hours (HC, AE, PyE),
/// projects and other institutions.
class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.declaration});

  final Declaration declaration;

  @override
  Widget build(BuildContext context) {
    final d = declaration;
    final required = ScheduleRequirements.requiredMinutes(d);
    int expected(bool Function(ScheduleTask) where) => required.entries
        .where((e) => where(e.key))
        .fold(0, (total, e) => total + e.value);
    int placed(bool Function(ScheduleTask) where) => d.intervals
        .where((i) => where(i.task))
        .fold(0, (total, i) => total + i.durationMinutes);
    final rows = <(String, bool Function(ScheduleTask))>[
      ('Clases (HC)', (t) => t.kind == TaskKind.lesson),
      ('Atención a estudiantes (AE)', (t) => t.kind == TaskKind.attention),
      ('Planificación y evaluación (PyE)', (t) => t.kind == TaskKind.planning),
      ('Proyectos', (t) => t.kind == TaskKind.project),
      ('Otras instituciones', (t) => t.kind == TaskKind.external),
    ];
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.pie_chart_outline,
      title: 'Horas por categoría',
      subtitle: 'Ubicadas de las que corresponden',
      children: [
        for (final (label, where) in rows)
          if (expected(where) > 0 || placed(where) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    expected(where) == placed(where)
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 20,
                    color: expected(where) == placed(where)
                        ? UcrColors.blue
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label)),
                  Text(
                    TimeRules.hoursOf(placed(where), expected(where)),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
        if (required.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sin cursos, proyectos ni otras instituciones.'),
          ),
      ],
    );
  }
}

class _IntervalLine extends StatelessWidget {
  const _IntervalLine(this.interval, this.label);

  final ScheduleInterval interval;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 8, color: UcrColors.skyBlue),
        ),
        Expanded(
          child: Text(
            '${interval.day.title}: ${clockLabel(interval.startMinutes)} a '
            '${clockLabel(interval.endMinutes)} · $label · '
            '${TimeRules.hoursLabel(interval.durationMinutes)}',
          ),
        ),
      ],
    ),
  );
}
