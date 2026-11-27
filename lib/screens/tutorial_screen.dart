import 'dart:async';
import 'dart:ui';

import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/demo_session.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/screens/declaration_form_screen.dart';
import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/history_screen.dart';
import 'package:declara_ucr/screens/shell_screen.dart';
import 'package:declara_ucr/screens/summary_screen.dart';
import 'package:declara_ucr/screens/zonaje_screen.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/tour_anchor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Guided tour (U-06, also U-01): the real screens, filled with a made-up
/// teacher, with one part in focus at a time and what it is for. Shown once
/// per phone and again from the profile ("Cómo funciona"). A tap anywhere
/// goes on; nothing in the screens behind can be touched or saved.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

/// One part in focus. [anchor] is a [TourAnchor] id of the stage's screen;
/// `null` dims the whole screen. [align] is where the part ends when the
/// screen scrolls to it (0 top, 1 bottom), leaving room for the card.
class _Stop {
  const _Stop(this.anchor, this.title, this.body, {this.align = 0.3});

  final String? anchor;
  final String title;
  final String body;
  final double align;
}

/// A screen of the app and the parts of it the tour explains.
class _Stage {
  const _Stage(this.screen, this.stops);

  final Widget screen;
  final List<_Stop> stops;
}

final _stages = [
  const _Stage(ShellScreen(), [
    _Stop(
      null,
      'Bienvenido a DeclaraUCR',
      'Le mostramos la aplicación con una docente de ejemplo, Ana Lucía. '
          'Sus datos son ficticios: nada de lo que vea se guarda.',
    ),
    _Stop(
      'home.latest',
      'Su declaración del ciclo',
      'Aquí ve su declaración más reciente: en qué paso del proceso va, sus '
          'horas por tipo y el botón para continuarla.',
    ),
    _Stop(
      'home.profile',
      'Su cuenta',
      'Toque su inicial para corregir sus datos, volver a ver este recorrido '
          'o cerrar sesión.',
    ),
    _Stop(
      'shell.nav',
      'Las secciones',
      'Inicio, Declaraciones, Zonaje e Historial. Toque una para cambiar de '
          'sección.',
    ),
  ]),
  const _Stage(DeclarationsScreen(), [
    _Stop(
      'declarations.filters',
      'Sus declaraciones por estado',
      'Cuántas tiene en total, en borrador y validadas. Toque una para ver '
          'solo esas.',
    ),
    _Stop(
      'declarations.card.0',
      'Cada declaración',
      'Muestra el período, el estado y las horas. Tóquela para abrirla y '
          'seguir donde la dejó.',
    ),
    _Stop(
      'declarations.new',
      'Nueva declaración',
      'Elija el período: sus cursos y sus clases llegan solos, asignados por '
          'la Coordinación de su carrera.',
    ),
  ]),
  _Stage(DeclarationFormScreen(initial: _draft), const [
    _Stop(
      'form.declarant',
      'Sus datos',
      'Su nombre y su cédula salen de su cuenta: aquí no se escriben.',
    ),
    _Stop(
      'form.position',
      'Puesto',
      'Elija su nombramiento en la Universidad. Ana Lucía es «Adjunto».',
    ),
    _Stop(
      'form.courses',
      'Cursos',
      'Los asigna la Coordinación de su carrera, con sus horas de clases, '
          'atención a estudiantes y planificación.',
    ),
    _Stop(
      'form.projects',
      'Proyectos',
      'Si participa en un proyecto de acción social, investigación u otro, '
          'agréguelo con sus horas por semana.',
    ),
    _Stop(
      'form.external',
      'Otras instituciones',
      'Si también trabaja fuera de la UCR, anote dónde, su puesto y cuántas '
          'horas por semana.',
    ),
    _Stop(
      'schedule.days',
      'Horario: el día',
      'Elija el día que va a llenar. Debajo de cada día ve cuántas horas '
          'lleva.',
      align: 0.15,
    ),
    _Stop(
      'schedule.brushes',
      'Horario: qué va a ubicar',
      'Toque lo que va a poner: atención, planificación, su proyecto… Cada '
          'uno dice cuántas horas lleva de las que le tocan.',
      align: 0.15,
    ),
    _Stop(
      'schedule.grid',
      'Horario: las medias horas',
      'Toque cada media hora donde lo hace. Para varias seguidas, mantenga '
          'presionado y deslice. Las clases ya vienen puestas.',
      align: 0.05,
    ),
    _Stop(
      'form.observations',
      'Observaciones',
      'Algo que su superior deba saber de su horario. Es opcional.',
    ),
    _Stop(
      'form.actions',
      'Guardar y revisar',
      '«Guardar borrador» la guarda para seguir luego. «Ver resumen» la '
          'revisa antes de validarla.',
    ),
  ]),
  _Stage(const _SummaryStage(), const [
    _Stop(
      'summary.hero',
      'El resumen',
      'El estado de su declaración y el total de horas por semana.',
    ),
    _Stop(
      'summary.check',
      'Revisión automática',
      'Si falta algo o dos tareas chocan en el horario, aquí dice qué '
          'corregir. Si no hay nada, se puede validar.',
    ),
    _Stop(
      'summary.hours',
      'Sus horas',
      'Las horas de cada curso, proyecto e institución, para compararlas con '
          'su nombramiento.',
    ),
    _Stop(
      'summary.actions',
      'Validar, firmar y enviar',
      'Toque «Validar». Luego aparece «Firmar y enviar»: acepta la '
          'declaración jurada y la recibe su superior.',
    ),
  ]),
  const _Stage(ZonajeScreen(), [
    _Stop(
      'zonaje.card.0',
      'Zonaje',
      'El estado de sus solicitudes de zonaje y la respuesta de Recursos '
          'Humanos. La solicitud se hace en el sistema web.',
      align: 0.2,
    ),
  ]),
  const _Stage(HistoryScreen(), [
    _Stop(
      'history.years',
      'Historial',
      'Sus declaraciones y solicitudes de zonaje de otros ciclos. Toque un '
          'año para ver solo ese.',
      align: 0.1,
    ),
    _Stop(
      null,
      'Listo',
      'Ya conoce la aplicación. Puede volver a ver este recorrido cuando '
          'quiera desde su perfil, en «Cómo funciona».',
    ),
  ]),
];

final _draft = DemoSession.declaration(DeclarationStatus.draft);

/// The summary right after validating, so it offers "Firmar y enviar".
class _SummaryStage extends StatelessWidget {
  const _SummaryStage();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => DeclarationFormState(
      repository: context.read<DeclarationRepository>(),
      initial: DemoSession.declaration(DeclarationStatus.validated),
    ),
    child: const SummaryScreen(),
  );
}

class _TutorialScreenState extends State<TutorialScreen> {
  /// Every stop, in order, with the stage it belongs to.
  static final _stops = [
    for (final (i, stage) in _stages.indexed)
      for (final stop in stage.stops) (stage: i, stop: stop),
  ];

  late final List<SingleChildWidget> _demo = DemoSession.providers();

  /// One set of anchors per stage: two stages are mounted while they fade.
  final _anchors = [for (final _ in _stages) <String, GlobalKey>{}];
  final _screens = [for (final _ in _stages) GlobalKey()];
  final _stack = GlobalKey();

  int _index = 0;
  Rect? _hole;

  /// False while the screen scrolls to the next part: the card waits.
  bool _settled = false;
  int _focusRun = 0;

  bool get _last => _index == _stops.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus());
  }

  void _go(int index) {
    if (index < 0) return;
    if (index >= _stops.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index = index;
      _settled = false;
    });
    _focus();
  }

  /// Scrolls the part of this stop into view and moves the focus onto it.
  Future<void> _focus() async {
    final run = ++_focusRun;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final (:stage, :stop) = _stops[_index];
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || run != _focusRun) return;
    final target = stop.anchor == null
        ? null
        : await _built(stage, stop.anchor!, reduce: reduce);
    if (!mounted || run != _focusRun) return;
    assert(
      stop.anchor == null || target != null,
      'No TourAnchor "${stop.anchor}" in stage $stage',
    );
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        alignment: stop.align,
        duration: reduce ? Duration.zero : Durations.medium2,
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || run != _focusRun) return;
    setState(() {
      _hole = target == null || !target.mounted ? null : _rectOf(target);
      _settled = true;
    });
  }

  /// The anchor [id] of [stage]. Lists build only what is near the screen,
  /// so the screen's list scrolls down until the anchor is built.
  Future<BuildContext?> _built(
    int stage,
    String id, {
    required bool reduce,
  }) async {
    BuildContext? anchor() => _anchors[stage][id]?.currentContext;
    final list = _verticalList(_screens[stage].currentContext);
    while (anchor() == null && list != null && list.mounted) {
      final position = list.position;
      if (position.pixels >= position.maxScrollExtent) break;
      final next = (position.pixels + position.viewportDimension)
          .clamp(0, position.maxScrollExtent)
          .toDouble();
      if (reduce) {
        position.jumpTo(next);
      } else {
        await position.animateTo(
          next,
          duration: Durations.short4,
          curve: Curves.linear,
        );
      }
      await WidgetsBinding.instance.endOfFrame;
    }
    return anchor();
  }

  /// The first vertical scrollable of a screen: its main list.
  static ScrollableState? _verticalList(BuildContext? screen) {
    ScrollableState? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement &&
          e.state is ScrollableState &&
          (e.state as ScrollableState).position.axis == Axis.vertical) {
        found = e.state as ScrollableState;
        return;
      }
      e.visitChildElements(visit);
    }

    (screen as Element?)?.visitChildElements(visit);
    return found;
  }

  /// The box inside the outer padding of [node], if it has one: a card's
  /// margin is not part of what the tour points at.
  static RenderObject? _content(RenderObject? node) {
    for (var n = node; n is RenderObjectWithChildMixin<RenderBox>;) {
      if (n is RenderPadding) return n.child ?? node;
      n = n.child;
    }
    return node;
  }

  /// Where [target] is on the screen, cut to the visible part.
  Rect? _rectOf(BuildContext target) {
    final box = _content(target.findRenderObject());
    final stack = _stack.currentContext?.findRenderObject();
    if (box is! RenderBox || stack is! RenderBox || !box.attached) return null;
    Rect onStack(RenderBox b) =>
        b.localToGlobal(Offset.zero, ancestor: stack) & b.size;
    var rect = onStack(box).intersect(Offset.zero & stack.size);
    // A part taller than its list shows only inside the list, not under
    // the app bar.
    final list = Scrollable.maybeOf(target)?.context.findRenderObject();
    if (list is RenderBox && list.attached) {
      rect = rect.intersect(onStack(list));
    }
    return rect.isEmpty ? null : rect;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final (:stage, :stop) = _stops[_index];
    // A tap anywhere goes on, the card included; "Atrás" and "Saltar" win
    // their own taps.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(_index + 1),
      child: Material(
        color: UcrColors.navy,
        child: Stack(
          key: _stack,
          fit: StackFit.expand,
          children: [
            // The real screen, with the demo data, out of reach of taps and of
            // TalkBack: the card says what it shows.
            ExcludeSemantics(
              child: IgnorePointer(
                child: HeroMode(
                  enabled: false,
                  child: MultiProvider(
                    providers: _demo,
                    child: AnimatedSwitcher(
                      duration: reduce ? Duration.zero : Durations.medium2,
                      child: TourScope(
                        key: ValueKey(stage),
                        keys: _anchors[stage],
                        child: KeyedSubtree(
                          key: _screens[stage],
                          child: _stages[stage].screen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder<Rect?>(
              // No part in focus: the hole closes on the middle.
              tween: RectTween(
                end:
                    _hole ??
                    Rect.fromCenter(
                      center: MediaQuery.sizeOf(context).center(Offset.zero),
                      width: 0,
                      height: 0,
                    ),
              ),
              duration: reduce ? Duration.zero : Durations.medium2,
              curve: Curves.easeOutCubic,
              builder: (_, hole, _) => _Veil(hole: hole),
            ),
            Semantics(
              button: true,
              label: _last ? 'Terminar el recorrido' : 'Continuar',
              onTap: () => _go(_index + 1),
              child: const SizedBox.expand(),
            ),
            _TopBar(
              progress: (_index + 1) / _stops.length,
              onSkip: _last ? null : () => Navigator.of(context).pop(),
            ),
            _CardSlot(
              hole: _hole,
              child: AnimatedSwitcher(
                duration: reduce ? Duration.zero : Durations.short4,
                child: !_settled
                    ? const SizedBox.shrink()
                    : _StopCard(
                        key: ValueKey(_index),
                        stop: stop,
                        number: _index + 1,
                        total: _stops.length,
                        last: _last,
                        onBack: _index == 0 ? null : () => _go(_index - 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims and blurs everything but [hole], which gets a light ring.
class _Veil extends StatelessWidget {
  const _Veil({required this.hole});

  final Rect? hole;

  static const _radius = Radius.circular(16);

  @override
  Widget build(BuildContext context) {
    final open = this.hole;
    final hole = open == null || open.isEmpty ? null : open.inflate(6);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _Outside(hole, _radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColoredBox(color: UcrColors.navy.withValues(alpha: 0.62)),
            ),
          ),
          if (hole != null)
            Positioned.fromRect(
              rect: hole,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(_radius),
                  border: Border.all(color: UcrColors.skyBlue, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Outside extends CustomClipper<Path> {
  const _Outside(this.hole, this.radius);

  final Rect? hole;
  final Radius radius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (hole != null) path.addRRect(RRect.fromRectAndRadius(hole!, radius));
    return path;
  }

  @override
  bool shouldReclip(_Outside oldClipper) =>
      oldClipper.hole != hole || oldClipper.radius != radius;
}

/// The progress of the tour and "Saltar", over the veil.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.progress, required this.onSkip});

  final double progress;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: Durations.medium2,
                  builder: (_, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    color: UcrColors.skyBlue,
                    backgroundColor: UcrColors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Keeps its place on the last stop, so nothing jumps.
            Visibility.maintain(
              visible: onSkip != null,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: UcrColors.white),
                child: const Text('Saltar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Puts the card on the side of the focus with more room, or over the
/// bottom of a part taller than the screen.
class _CardSlot extends StatelessWidget {
  const _CardSlot({required this.hole, required this.child});

  final Rect? hole;
  final Widget child;

  static const _roomNeeded = 230.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pad = MediaQuery.paddingOf(context);
      final height = constraints.maxHeight;
      final hole = this.hole;
      const side = 16.0, gap = 20.0, topBar = 56.0;
      if (hole == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: side),
            child: child,
          ),
        );
      }
      final above = hole.top - pad.top - topBar;
      final below = height - hole.bottom - pad.bottom;
      final (top, bottom) = below >= above && below >= _roomNeeded
          ? (hole.bottom + gap, null)
          : above >= _roomNeeded
          ? (null, height - hole.top + gap)
          : (null, pad.bottom + side);
      return Stack(
        children: [
          Positioned(
            left: side,
            right: side,
            top: top,
            bottom: bottom,
            child: Align(
              alignment: top != null
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    super.key,
    required this.stop,
    required this.number,
    required this.total,
    required this.last,
    required this.onBack,
  });

  final _Stop stop;
  final int number;
  final int total;
  final bool last;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: UcrColors.white,
      elevation: 8,
      shadowColor: UcrColors.navy.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$number de $total',
                style: text.labelLarge?.copyWith(color: UcrColors.blue),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(stop.title, style: text.titleLarge),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(stop.body, style: text.bodyLarge),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Atrás'),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TapHint(last: last),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Toque para continuar", breathing slowly so it reads as an invitation.
class _TapHint extends StatefulWidget {
  const _TapHint({required this.last});

  final bool last;

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    lowerBound: 0.55,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _pulse,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined, size: 18, color: UcrColors.blue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.last ? 'Toque para empezar' : 'Toque para continuar',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: UcrColors.blue),
            ),
          ),
        ],
      ),
    ),
  );
}
