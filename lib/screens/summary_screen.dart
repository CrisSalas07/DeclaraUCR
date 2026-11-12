import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
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
    final theme = Theme.of(context);
    final missing = state.missingFields;
    final issues = state.issues;
    final sorted = d.sortedIntervals;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de la declaración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Text('Estado: ', style: theme.textTheme.titleMedium),
              Flexible(child: StatusChip(d.status)),
            ],
          ),
          const SectionTitle('Datos generales'),
          _Line('Nombre', d.declarantName),
          _Line('Identificación', d.identification),
          const SectionTitle('Información laboral'),
          _Line('Institución', d.institution),
          _Line('Puesto', d.position),
          _Line('Jornada o nombramiento', d.workdayType ?? ''),
          _Line(
            'Vigencia',
            '${formatDate(d.validFrom)} – ${formatDate(d.validTo)}',
          ),
          _Line('Instituciones adicionales', d.additionalInstitutions),
          _Line('Observaciones', d.observations),
          const SectionTitle('Horario semanal'),
          if (sorted.isEmpty) const Text('Sin intervalos registrados.'),
          for (final i in sorted) _IntervalLine(i),
          const Divider(height: 24),
          Text(
            'Total de horas: ${TimeRules.hoursLabel(d.totalMinutes)}',
            style: theme.textTheme.titleMedium,
          ),
          const SectionTitle('Resultado de la validación'),
          if (missing.isEmpty && issues.isEmpty)
            _Result(
              icon: Icons.check_circle_outline,
              color: theme.colorScheme.primary,
              text: 'Sin problemas: la declaración puede validarse.',
            ),
          for (final field in missing)
            _Result(
              icon: Icons.edit_note,
              color: theme.colorScheme.error,
              text: 'Falta: $field.',
            ),
          for (final issue in issues)
            _Result(
              icon: Icons.error_outline,
              color: theme.colorScheme.error,
              text: issue.message,
            ),
          const SizedBox(height: 16),
          // Lab scope limit: no signature is simulated.
          Text(
            'La firma digital, la aprobación del superior y la recepción en '
            'Recursos Humanos no forman parte de esta aplicación.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Corregir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: state.canValidate && !state.saving
                      ? () => _validate(context)
                      : null,
                  child: const Text('Validar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value.trim().isEmpty ? '—' : value),
      ],
    ),
  );
}

class _IntervalLine extends StatelessWidget {
  const _IntervalLine(this.interval);

  final ScheduleInterval interval;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      '${interval.day.title}: ${clockLabel(interval.startMinutes)} a '
      '${clockLabel(interval.endMinutes)} · '
      '${interval.institution.isEmpty ? 'Sin institución' : interval.institution} · '
      '${TimeRules.hoursLabel(interval.durationMinutes)}',
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
