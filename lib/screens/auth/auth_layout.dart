import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared frame of the auth screens, designed for phones: a white card
/// floating on flat UCR blue (the manual asks apps for flat color). The
/// official UCR signature goes inside the card, since its color version is
/// only allowed on light backgrounds.
///
/// On entry the card rises and fades in, then its content follows in a
/// short stagger; skipped when the system asks for reduced motion.
///
/// Pilot of the app-wide redesign: field labels always float on top, set
/// here with a local theme so the rest of the app is unchanged for now.
class AuthLayout extends StatefulWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// [child] fades in and rises slightly during [begin]..[end] of the
  /// entrance.
  Widget _reveal(double begin, double end, Widget child) {
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final card = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    final content = <Widget>[
      const Center(child: UcrSignature()),
      const SizedBox(height: 20),
      const BrandMark(fontSize: 18, onDark: false),
      const SizedBox(height: 4),
      Text(
        widget.title,
        style: text.headlineSmall?.copyWith(
          color: UcrColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        widget.subtitle,
        style: text.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            // Lighter than typed text, so an example never reads as a
            // filled-in value.
            hintStyle: text.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: widget.child,
      ),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: UcrColors.hero,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                // Centers the card on tall screens; scrolls on short ones.
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.showBack)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              tooltip: 'Volver',
                              color: UcrColors.white,
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        FadeTransition(
                          opacity: card,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero,
                            ).animate(card),
                            child: ScaleTransition(
                              scale: Tween(begin: 0.96, end: 1.0).animate(card),
                              child: _FloatingCard(
                                children: [
                                  for (final (i, item) in content.indexed)
                                    _reveal(
                                      0.2 + i * 0.04,
                                      0.6 + i * 0.04,
                                      item,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White card with a deep navy shadow, so it floats over the blue.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: UcrColors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: UcrColors.navy.withValues(alpha: 0.35),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _hidden,
    autofillHints: widget.autofillHints,
    textInputAction: widget.textInputAction,
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    validator: widget.validator,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    ),
  );
}

/// Primary button that shows a spinner while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: UcrColors.white,
            ),
          )
        : Text(label),
  );
}
