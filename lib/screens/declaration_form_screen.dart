import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/screens/summary_screen.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// R2 (form) and R3 (weekly schedule) on a single scrolling screen.
class DeclarationFormScreen extends StatelessWidget {
  const DeclarationFormScreen({super.key, this.initial});

  final Declaration? initial;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => DeclarationFormState(
      repository: context.read<DeclarationRepository>(),
      initial: initial,
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

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Este campo es obligatorio.' : null;

  String? _identification(String? v) =>
      _required(v) ??
      (FieldRules.isValidIdentification(v!)
          ? null
          : 'Use de 5 a ${FieldRules.identificationMaxLength} números, '
                'letras o guiones.');

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
              : 'Borrador guardado. Faltan $missing campos obligatorios.',
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

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeclarationFormState>();
    final d = state.declaration;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.id == null ? 'Nueva declaración' : 'Editar declaración'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Align(alignment: Alignment.centerLeft, child: StatusChip(d.status)),
            const SectionTitle('Persona declarante'),
            TextFormField(
              initialValue: d.declarantName,
              decoration: const InputDecoration(labelText: 'Nombre completo *'),
              textCapitalization: TextCapitalization.words,
              maxLength: FieldRules.nameMaxLength,
              validator: _required,
              onChanged: (v) => state.edit((d) => d.declarantName = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: d.identification,
              decoration: const InputDecoration(
                labelText: 'Identificación *',
                hintText: 'Ej.: 1-2345-6789',
              ),
              maxLength: FieldRules.identificationMaxLength,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  FieldRules.identificationChars,
                ),
              ],
              validator: _identification,
              onChanged: (v) => state.edit((d) => d.identification = v),
            ),
            const SectionTitle('Información laboral'),
            TextFormField(
              initialValue: d.institution,
              decoration: const InputDecoration(labelText: 'Institución *'),
              maxLength: FieldRules.institutionMaxLength,
              validator: _required,
              onChanged: (v) => state.edit((d) => d.institution = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: d.position,
              decoration: const InputDecoration(labelText: 'Puesto *'),
              maxLength: FieldRules.positionMaxLength,
              validator: _required,
              onChanged: (v) => state.edit((d) => d.position = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: d.workdayType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de jornada o nombramiento *',
              ),
              items: workdayTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              validator: (v) => v == null ? 'Seleccione una opción.' : null,
              onChanged: (v) => state.edit((d) => d.workdayType = v),
            ),
            const SectionTitle('Período de vigencia'),
            _DateField(
              label: 'Inicio *',
              value: d.validFrom,
              onTap: () async {
                final picked = await _pickDate(d.validFrom);
                if (picked != null) state.edit((d) => d.validFrom = picked);
              },
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Fin *',
              value: d.validTo,
              onTap: () async {
                final picked = await _pickDate(d.validTo ?? d.validFrom);
                if (picked != null) state.edit((d) => d.validTo = picked);
              },
            ),
            const SectionTitle('Otras instituciones y observaciones'),
            TextFormField(
              initialValue: d.additionalInstitutions,
              decoration: const InputDecoration(
                labelText: 'Instituciones adicionales',
                helperText: 'Una por línea, si labora en otras.',
              ),
              minLines: 1,
              maxLines: 4,
              maxLength: FieldRules.additionalInstitutionsMaxLength,
              onChanged: (v) => state.edit((d) => d.additionalInstitutions = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: d.observations,
              decoration: const InputDecoration(labelText: 'Observaciones'),
              minLines: 2,
              maxLines: 6,
              maxLength: FieldRules.observationsMaxLength,
              onChanged: (v) => state.edit((d) => d.observations = v),
            ),
            const SectionTitle('Horario semanal'),
            for (final interval in d.intervals)
              _IntervalCard(key: ValueKey(interval.id), interval: interval),
            OutlinedButton.icon(
              onPressed: d.intervals.length < FieldRules.maxIntervals
                  ? state.addInterval
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Agregar intervalo'),
            ),
            const SizedBox(height: 12),
            Text(
              'Total registrado: ${TimeRules.hoursLabel(d.totalMinutes)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.saving ? null : _saveDraft,
                  child: const Text('Guardar borrador'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: state.saving ? null : _openSummary,
                  child: const Text('Ver resumen'),
                ),
              ),
            ],
          ),
        ),
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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: field.errorText,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(formatDate(value)),
      ),
    ),
  );
}

/// One interval: day, start, end, institution, duration and its problems.
class _IntervalCard extends StatelessWidget {
  const _IntervalCard({super.key, required this.interval});

  final ScheduleInterval interval;

  Future<int?> _pickTime(BuildContext context, int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<DeclarationFormState>();
    final theme = Theme.of(context);
    final problems = context.watch<DeclarationFormState>().issuesFor(
      interval.id,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: problems.isEmpty
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.error, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Weekday>(
                    initialValue: interval.day,
                    decoration: const InputDecoration(labelText: 'Día'),
                    items: Weekday.values
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.title)),
                        )
                        .toList(),
                    onChanged: (w) => state.edit((_) => interval.day = w!),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar intervalo',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => state.removeInterval(interval.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final m = await _pickTime(context, interval.startMinutes);
                      if (m != null) {
                        state.edit((_) => interval.startMinutes = m);
                      }
                    },
                    child: Text('Inicio: ${clockLabel(interval.startMinutes)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final m = await _pickTime(context, interval.endMinutes);
                      if (m != null) state.edit((_) => interval.endMinutes = m);
                    },
                    child: Text('Fin: ${clockLabel(interval.endMinutes)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: interval.institution,
              decoration: const InputDecoration(
                labelText: 'Institución o nombramiento',
              ),
              maxLength: FieldRules.institutionMaxLength,
              onChanged: (v) => state.edit((_) => interval.institution = v),
            ),
            const SizedBox(height: 8),
            Text('Duración: ${TimeRules.hoursLabel(interval.durationMinutes)}'),
            for (final p in problems)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.message,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
