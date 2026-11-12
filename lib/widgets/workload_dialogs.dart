import 'package:declara_ucr/domain/course_rules.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialogs to add or edit a course, a project or a job at another
/// institution. Everything but names is picked from a list, so it is always
/// in the same format. [onSave] stores the item and returns why it could
/// not (in Spanish); the dialog closes only when it returns `null`.
Future<void> showCourseDialog(
  BuildContext context, {
  CourseLoad? initial,
  required int freeMinutes,
  required String? Function(CourseLoad) onSave,
}) => showDialog<void>(
  context: context,
  builder: (_) =>
      _CourseDialog(initial: initial, freeMinutes: freeMinutes, onSave: onSave),
);

Future<void> showProjectDialog(
  BuildContext context, {
  ProjectHours? initial,
  required int freeMinutes,
  required String? Function(ProjectHours) onSave,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ProjectDialog(
    initial: initial,
    freeMinutes: freeMinutes,
    onSave: onSave,
  ),
);

Future<void> showExternalJobDialog(
  BuildContext context, {
  ExternalJob? initial,
  required int freeMinutes,
  required String? Function(ExternalJob) onSave,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ExternalJobDialog(
    initial: initial,
    freeMinutes: freeMinutes,
    onSave: onSave,
  ),
);

/// Shared frame: title, fields, the last problem and the two buttons.
class _ItemDialog extends StatelessWidget {
  const _ItemDialog({
    required this.title,
    required this.children,
    required this.problem,
    required this.onAccept,
  });

  final String title;
  final List<Widget> children;
  final String? problem;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            if (problem != null) ...[
              const SizedBox(height: 8),
              Text(
                problem!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: onAccept, child: const Text('Aceptar')),
    ],
  );
}

class _CourseDialog extends StatefulWidget {
  const _CourseDialog({
    this.initial,
    required this.freeMinutes,
    required this.onSave,
  });

  final CourseLoad? initial;
  final int freeMinutes;
  final String? Function(CourseLoad) onSave;

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _code = TextEditingController(text: widget.initial?.code);
  late int? _workload = widget.initial?.workloadMinutes;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _accept() {
    if (_name.text.trim().isEmpty) {
      return setState(() => _problem = 'Escriba el nombre del curso.');
    }
    if (_workload == null) {
      return setState(() => _problem = 'Elija la jornada del curso.');
    }
    final problem = widget.onSave(
      CourseLoad(
        name: _name.text.trim(),
        code: _code.text.trim(),
        workloadMinutes: _workload!,
      ),
    );
    if (problem == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _problem = problem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = WorkloadCatalog.fitting(
      WorkloadCatalog.maxUniversityMinutes - widget.freeMinutes,
      WorkloadCatalog.maxUniversityMinutes,
    );
    final preview = _workload == null
        ? null
        : CourseLoad(name: '', code: '', workloadMinutes: _workload!);
    return _ItemDialog(
      title: widget.initial == null ? 'Agregar curso' : 'Editar curso',
      problem: _problem,
      onAccept: _accept,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.initial == null,
          maxLength: CourseRules.nameMaxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre del curso *'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _code,
          maxLength: CourseRules.codeMaxLength,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            const _UpperCase(),
          ],
          decoration: const InputDecoration(
            labelText: 'Sigla',
            hintText: 'Ej.: IF0009',
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _workload,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Jornada del curso *'),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.weeklyMinutes, child: Text(o.title)),
          ],
          onChanged: (v) => setState(() => _workload = v),
        ),
        if (options.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Ya completó el tiempo completo (40 h).'),
          ),
        if (preview != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Clases: ${TimeRules.hoursLabel(preview.lessonMinutes)} · '
              'Atención: ${TimeRules.hoursLabel(preview.attentionMinutes)} · '
              'Planificación: ${TimeRules.hoursLabel(preview.planningMinutes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({
    this.initial,
    required this.freeMinutes,
    required this.onSave,
  });

  final ProjectHours? initial;
  final int freeMinutes;
  final String? Function(ProjectHours) onSave;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late int? _minutes = widget.initial?.weeklyMinutes;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _accept() {
    if (_name.text.trim().isEmpty) {
      return setState(() => _problem = 'Escriba el nombre del proyecto.');
    }
    if (_minutes == null) {
      return setState(() => _problem = 'Elija las horas semanales.');
    }
    final problem = widget.onSave(
      ProjectHours(name: _name.text.trim(), weeklyMinutes: _minutes!),
    );
    if (problem == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _problem = problem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [for (var m = 30; m <= widget.freeMinutes; m += 30) m];
    return _ItemDialog(
      title: widget.initial == null ? 'Agregar proyecto' : 'Editar proyecto',
      problem: _problem,
      onAccept: _accept,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.initial == null,
          maxLength: CourseRules.nameMaxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre o código del proyecto *',
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _minutes,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Horas por semana *'),
          items: [
            for (final m in options)
              DropdownMenuItem(value: m, child: Text(TimeRules.hoursLabel(m))),
          ],
          onChanged: (v) => setState(() => _minutes = v),
        ),
        if (options.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Ya completó el tiempo completo (40 h).'),
          ),
      ],
    );
  }
}

class _ExternalJobDialog extends StatefulWidget {
  const _ExternalJobDialog({
    this.initial,
    required this.freeMinutes,
    required this.onSave,
  });

  final ExternalJob? initial;
  final int freeMinutes;
  final String? Function(ExternalJob) onSave;

  @override
  State<_ExternalJobDialog> createState() => _ExternalJobDialogState();
}

class _ExternalJobDialogState extends State<_ExternalJobDialog> {
  late final _name = TextEditingController(text: widget.initial?.institution);
  late InstitutionType? _type = widget.initial?.type;
  late String? _position = widget.initial?.position;
  late int? _minutes = widget.initial?.weeklyMinutes;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _accept() {
    final problem = _name.text.trim().isEmpty
        ? 'Escriba el nombre de la institución.'
        : _type == null
        ? 'Elija el tipo de institución.'
        : _position == null
        ? 'Elija el puesto.'
        : _minutes == null
        ? 'Elija la jornada.'
        : widget.onSave(
            ExternalJob(
              institution: _name.text.trim(),
              type: _type!,
              position: _position!,
              weeklyMinutes: _minutes!,
            ),
          );
    if (problem == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _problem = problem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = WorkloadCatalog.fitting(
      WorkloadCatalog.maxExternalMinutes - widget.freeMinutes,
      WorkloadCatalog.maxExternalMinutes,
    );
    return _ItemDialog(
      title: widget.initial == null
          ? 'Agregar horas en otra institución'
          : 'Horas en otra institución',
      problem: _problem,
      onAccept: _accept,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.initial == null,
          maxLength: CourseRules.nameMaxLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Institución *'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<InstitutionType>(
          initialValue: _type,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo *'),
          items: [
            for (final t in InstitutionType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: Positions.otherInstitution.contains(_position)
              ? _position
              : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Puesto *'),
          items: [
            for (final p in Positions.otherInstitution)
              DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) => setState(() => _position = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _minutes,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Jornada *'),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.weeklyMinutes, child: Text(o.title)),
          ],
          onChanged: (v) => setState(() => _minutes = v),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Hasta ½ TC (20 h) en otras instituciones. Después ubique sus '
            'horas en el horario.',
          ),
        ),
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  const _UpperCase();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
