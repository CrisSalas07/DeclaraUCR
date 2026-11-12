import 'package:declara_ucr/domain/schedule_grid.dart';
import 'package:declara_ucr/domain/schedule_requirements.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Weekly schedule editor (R3), the grid concept of DeclaraHorario adapted
/// to a phone: one day at a time in full-width half-hour rows.
///
/// - Choose what to place (a "brush": lessons, attention or planning of a
///   course, a project or another institution), then tap a half hour to
///   place it; tapping one that already has it frees it. Each brush shows
///   how many of its hours are placed, and never takes more.
/// - Long-press and slide to place (or free) a whole range; a long press
///   does not fight with the page scroll the way a plain drag would.
/// - "Copiar a otros días" repeats the day, e.g. Monday to Friday.
///
/// The lunch hour is closed and no day passes 10 hours
/// ([DeclarationFormState.paint] enforces it).
class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({super.key});

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  static const double _rowHeight = 40;
  static const double _timeWidth = 52;

  /// Distinct, readable on white with dark-ink labels over their tint.
  static const List<Color> _palette = [
    UcrColors.blue,
    Color(0xFF2E7D32),
    Color(0xFFE07B00),
    Color(0xFF7B4FB8),
    Color(0xFF00838F),
    Color(0xFFC2185B),
  ];

  Weekday _day = Weekday.monday;
  ScheduleTask? _brush;

  /// Rows of the long-press range being chosen.
  int? _anchorRow;
  int? _currentRow;

  List<int> get _rows => ScheduleGrid.rowStarts;

  /// What can be placed: every task the declaration needs, plus any task
  /// still on the schedule that is no longer declared (so it can be freed).
  static List<ScheduleTask> _brushes(Declaration d) => {
    ...ScheduleRequirements.requiredMinutes(d).keys,
    ...d.intervals.map((i) => i.task),
  }.toList();

  /// "IF0009 · Atención", "Proyecto · Huertas", "Colegio X".
  static String _name(ScheduleTask task, Declaration d) {
    if (task.kind.isCourse) {
      final course = d.courses.where((c) => c.name == task.name);
      final name = course.isEmpty ? task.name : course.first.shortName;
      return '$name · ${task.kind.label}';
    }
    return task.kind == TaskKind.project
        ? 'Proyecto · ${task.name}'
        : task.name;
  }

  /// One color per course, project or institution: the three kinds of
  /// hours of a course share it.
  Color _colorOf(ScheduleTask task, List<ScheduleTask> brushes) {
    final owners = <String>[];
    for (final b in brushes) {
      if (!owners.contains(_owner(b))) owners.add(_owner(b));
    }
    final i = owners.indexOf(_owner(task));
    return _palette[(i < 0 ? 0 : i) % _palette.length];
  }

  static String _owner(ScheduleTask task) =>
      task.kind.isCourse ? 'course|${task.name}' : task.key;

  void _report(String? error) {
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  int _rowAt(double dy) =>
      (dy ~/ _rowHeight).clamp(0, _rows.length - 1).toInt();

  void _tap(int row, ScheduleTask brush) {
    final state = context.read<DeclarationFormState>();
    final cell = GridCell(_day, _rows[row]);
    if (ScheduleGrid.isLunch(cell.startMinutes)) return;
    final current = ScheduleGrid.cellsOf(state.declaration.intervals)[cell];
    _report(state.paint([cell], current == brush.key ? null : brush));
  }

  void _endRange(ScheduleTask brush) {
    final a = _anchorRow, b = _currentRow;
    setState(() => _anchorRow = _currentRow = null);
    if (a == null || b == null) return;
    final state = context.read<DeclarationFormState>();
    final cells = ScheduleGrid.cellsOf(state.declaration.intervals);
    // Starting on the chosen brush frees the range; otherwise fills it.
    final erase = cells[GridCell(_day, _rows[a])] == brush.key;
    final range = [
      for (var r = a < b ? a : b; r <= (a < b ? b : a); r++)
        GridCell(_day, _rows[r]),
    ];
    _report(state.paint(range, erase ? null : brush));
  }

  Future<void> _copyDay() async {
    final state = context.read<DeclarationFormState>();
    final targets = await showModalBottomSheet<Set<Weekday>>(
      context: context,
      builder: (_) => _CopyDaySheet(from: _day),
    );
    if (targets == null || targets.isEmpty || !mounted) return;
    final error = state.copyDay(_day, targets);
    _report(
      error ??
          'Horario del ${_day.label} copiado a ${targets.length} '
              '${targets.length == 1 ? 'día' : 'días'}.',
    );
  }

  void _clearDay() {
    final state = context.read<DeclarationFormState>();
    _report(state.paint([for (final s in _rows) GridCell(_day, s)], null));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeclarationFormState>();
    final d = state.declaration;
    final theme = Theme.of(context);
    final brushes = _brushes(d);
    if (brushes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Agregue sus cursos, proyectos u otras instituciones: aquí '
          'aparecerán sus horas para ubicarlas en el horario.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final brush = brushes.contains(_brush) ? _brush! : brushes.first;
    final required = ScheduleRequirements.requiredMinutes(d);
    final cells = ScheduleGrid.cellsOf(d.intervals);
    final dayMinutes = ScheduleGrid.minutesOn(_day, cells);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayTabs(
          selected: _day,
          minutesOf: (day) => ScheduleGrid.minutesOn(day, cells),
          onSelect: (day) => setState(() => _day = day),
        ),
        const SizedBox(height: 16),
        Text(
          'Qué va a ubicar',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final task in brushes)
              _BrushChip(
                label: _name(task, d),
                placed: ScheduleRequirements.placedMinutes(d, task),
                required: required[task],
                color: _colorOf(task, brushes),
                selected: task == brush,
                onTap: () => setState(() => _brush = task),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Toque una media hora para marcarla. Mantenga presionado y deslice '
          'para marcar varias seguidas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _dayGrid(d, cells, brush, brushes, theme),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: dayMinutes == 0 ? null : _copyDay,
                icon: const Icon(Icons.copy_all_outlined, size: 20),
                label: const Text('Copiar a otros días'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Limpiar el ${_day.label}',
              onPressed: dayMinutes == 0 ? null : _clearDay,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dayGrid(
    Declaration d,
    Map<GridCell, String> cells,
    ScheduleTask brush,
    List<ScheduleTask> brushes,
    ThemeData theme,
  ) {
    final scheme = theme.colorScheme;
    final runs = _runsOf(cells);
    final a = _anchorRow, b = _currentRow;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: UcrColors.white,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _timeWidth,
              child: Column(
                children: [
                  for (final start in _rows)
                    Container(
                      height: _rowHeight,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 4),
                      color: scheme.surfaceContainerLow,
                      child: Text(
                        TimeRules.shortClock(start),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: start % 60 == 0
                              ? scheme.onSurfaceVariant
                              : scheme.outline,
                          fontWeight: start % 60 == 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tap(_rowAt(d.localPosition.dy), brush),
                onLongPressStart: (d) {
                  HapticFeedback.selectionClick();
                  final row = _rowAt(d.localPosition.dy);
                  setState(() => _anchorRow = _currentRow = row);
                },
                onLongPressMoveUpdate: (d) {
                  final row = _rowAt(d.localPosition.dy);
                  if (row != _currentRow) setState(() => _currentRow = row);
                },
                onLongPressEnd: (_) => _endRange(brush),
                onLongPressCancel: () =>
                    setState(() => _anchorRow = _currentRow = null),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        for (final start in _rows)
                          _row(GridCell(_day, start), scheme, theme),
                      ],
                    ),
                    for (final run in runs)
                      Positioned(
                        top: run.first * _rowHeight + 2,
                        height: run.length * _rowHeight - 4,
                        left: 4,
                        right: 4,
                        child: IgnorePointer(
                          child: _block(
                            run,
                            _name(run.task, d),
                            _colorOf(run.task, brushes),
                            theme,
                          ),
                        ),
                      ),
                    if (a != null && b != null)
                      Positioned(
                        top: (a < b ? a : b) * _rowHeight,
                        height: ((a - b).abs() + 1) * _rowHeight,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _colorOf(
                                brush,
                                brushes,
                              ).withValues(alpha: 0.18),
                              border: Border.all(
                                color: _colorOf(brush, brushes),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${TimeRules.shortClock(_rows[a < b ? a : b])} – '
                              '${TimeRules.shortClock(_rows[a < b ? b : a] + ScheduleGrid.stepMinutes)}',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(GridCell cell, ColorScheme scheme, ThemeData theme) {
    final lunch = ScheduleGrid.isLunch(cell.startMinutes);
    final onHour = cell.startMinutes % 60 == 0;
    return Container(
      key: ValueKey('cell-${cell.day.number}-${cell.startMinutes}'),
      height: _rowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lunch ? scheme.surfaceContainerHigh : null,
        border: Border(
          top: BorderSide(
            color: onHour
                ? scheme.outlineVariant
                : scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: lunch && onHour
          ? Text(
              'Almuerzo',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          : null,
    );
  }

  Widget _block(_Run run, String name, Color color, ThemeData theme) {
    final range =
        '${TimeRules.shortClock(run.start)} – ${TimeRules.shortClock(run.end)}';
    return Semantics(
      label: '$name, $range',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.16),
            UcrColors.white,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: run.length > 1 ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: UcrColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              run.length > 1
                  ? '$range\n${TimeRules.hoursLabel(run.end - run.start)}'
                  : range,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Consecutive rows of the day with the same institution, as blocks.
  List<_Run> _runsOf(Map<GridCell, String> cells) {
    final runs = <_Run>[];
    for (var i = 0; i < _rows.length; i++) {
      final label = cells[GridCell(_day, _rows[i])];
      if (label == null) continue;
      final task = ScheduleTask.fromKey(label);
      final last = runs.isEmpty ? null : runs.last;
      if (last != null && last.first + last.length == i && last.task == task) {
        last.length++;
      } else {
        runs.add(_Run(first: i, start: _rows[i], task: task));
      }
    }
    return runs;
  }
}

class _Run {
  _Run({required this.first, required this.start, required this.task});

  final int first;
  final int start;
  final ScheduleTask task;
  int length = 1;

  int get end => start + length * ScheduleGrid.stepMinutes;
}

/// Monday to Saturday with the hours of each day; the chosen one is filled.
class _DayTabs extends StatelessWidget {
  const _DayTabs({
    required this.selected,
    required this.minutesOf,
    required this.onSelect,
  });

  final Weekday selected;
  final int Function(Weekday) minutesOf;
  final ValueChanged<Weekday> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final day in ScheduleGrid.days) ...[
          if (day != ScheduleGrid.days.first) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: day == selected,
              label: '${day.title}: ${TimeRules.hoursLabel(minutesOf(day))}',
              excludeSemantics: true,
              child: Material(
                color: day == selected
                    ? UcrColors.blue
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(day),
                  child: SizedBox(
                    height: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.title.substring(0, 3),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: day == selected
                                ? UcrColors.white
                                : UcrColors.ink,
                          ),
                        ),
                        Text(
                          minutesOf(day) == 0
                              ? '—'
                              : TimeRules.hoursLabel(minutesOf(day)),
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: day == selected
                                ? UcrColors.white.withValues(alpha: 0.85)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BrushChip extends StatelessWidget {
  const _BrushChip({
    required this.label,
    required this.placed,
    required this.required,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int placed;

  /// `null` for a task no longer declared: its hours are only to free.
  final int? required;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(color.withValues(alpha: 0.14), UcrColors.white)
            : UcrColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, maxWidth: 260),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    required == placed
                        ? Icons.check_circle
                        : selected
                        ? Icons.radio_button_checked
                        : Icons.circle,
                    size: selected ? 18 : 12,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        Text(
                          required == null
                              ? '${TimeRules.hoursLabel(placed)} · quitar'
                              : TimeRules.hoursOf(placed, required!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: required == placed
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                      ],
                    ),
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

/// Picks the days that receive a copy of [from]; Monday to Friday are
/// preselected, the usual case.
class _CopyDaySheet extends StatefulWidget {
  const _CopyDaySheet({required this.from});

  final Weekday from;

  @override
  State<_CopyDaySheet> createState() => _CopyDaySheetState();
}

class _CopyDaySheetState extends State<_CopyDaySheet> {
  late final Set<Weekday> _days = {
    for (final d in ScheduleGrid.days)
      if (d != widget.from && d != Weekday.saturday) d,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Copiar el ${widget.from.label} a…', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Reemplaza el horario de los días elegidos.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in ScheduleGrid.days)
                  if (day != widget.from)
                    FilterChip(
                      label: Text(day.title),
                      selected: _days.contains(day),
                      onSelected: (on) => setState(
                        () => on ? _days.add(day) : _days.remove(day),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _days.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_days),
              child: const Text('Copiar'),
            ),
          ],
        ),
      ),
    );
  }
}
