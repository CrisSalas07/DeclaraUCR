import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';

/// First-use tour (U-06, also U-01): the four steps of a declaration, one
/// per page. Shown once per phone and again from the profile ("Cómo
/// funciona").
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _Step {
  const _Step(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _TutorialScreenState extends State<TutorialScreen> {
  static const _steps = [
    _Step(
      Icons.home_outlined,
      'Inicio',
      'Aquí ve su declaración más reciente y en qué paso del proceso va. '
          'Si aún no tiene, toque «Nueva declaración».',
    ),
    _Step(
      Icons.post_add_rounded,
      'Su declaración',
      'Sus cursos ya vienen asignados por la Coordinación de su carrera, con '
          'sus clases en el horario. Usted elige su puesto y agrega, si los '
          'tiene, proyectos u otras instituciones.',
    ),
    _Step(
      Icons.calendar_view_week_outlined,
      'El horario',
      '1. Elija qué va a ubicar: atención a estudiantes, planificación, un '
          'proyecto…\n2. Toque las medias horas del horario donde las hace. '
          'Para varias seguidas, mantenga presionado y deslice.',
    ),
    _Step(
      Icons.draw_outlined,
      'Validar y firmar',
      'En «Ver resumen» revise las horas y toque «Validar». Luego toque '
          '«Firmar y enviar»: la declaración va a su superior.',
    ),
  ];

  final _pages = PageController();
  int _page = 0;

  bool get _last => _page == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
      return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    _pages.animateToPage(
      _page + 1,
      duration: reduce ? const Duration(milliseconds: 1) : Durations.medium2,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: UcrColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const BrandMark(onDark: false),
                  const Spacer(),
                  if (!_last)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Saltar'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (i, step) in _steps.indexed)
                    _StepPage(
                      step: step,
                      number: i + 1,
                      total: _steps.length,
                      text: text,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: Durations.short4,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? UcrColors.blue
                            : UcrColors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_last ? 'Empezar' : 'Siguiente'),
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

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.number,
    required this.total,
    required this.text,
  });

  final _Step step;
  final int number;
  final int total;
  final TextTheme text;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: UcrColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(step.icon, size: 36, color: UcrColors.blue),
        ),
        const SizedBox(height: 28),
        Text(
          'Paso $number de $total',
          style: text.labelLarge?.copyWith(color: UcrColors.blue),
        ),
        const SizedBox(height: 6),
        Text(step.title, style: text.headlineSmall),
        const SizedBox(height: 12),
        Text(step.body, style: text.bodyLarge),
      ],
    ),
  );
}
