import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:flutter/material.dart';

/// "05/03/2026"; "—" when there is no date.
String formatDate(DateTime? date) => date == null
    ? '—'
    : '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Clock time as shown to the user: 480 -> "8:00 a. m.", 720 -> "12:00 m.".
String clockLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = (minutes % 60).toString().padLeft(2, '0');
  if (h == 12 && m == '00') return '12:00 m.';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m ${h < 12 ? 'a. m.' : 'p. m.'}';
}

/// Status with the exact name of the original system (R1).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.onDark = false});

  final DeclarationStatus status;

  /// On the brand gradient: solid background instead of a tint.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.extension<StatusColors>()!.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? color : color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: onDark ? UcrColors.ink : color,
              shape: BoxShape.circle,
              border: Border.all(color: UcrColors.ink.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: UcrColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// App mark: icon tile plus the product name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: UcrColors.white,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          Icons.fact_check_rounded,
          color: UcrColors.blue,
          size: size * 0.58,
        ),
      ),
      if (showName) ...[
        SizedBox(width: size * 0.3),
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'Declara'),
              TextSpan(
                text: 'UCR',
                style: TextStyle(color: UcrColors.skyBlue),
              ),
            ],
            style: TextStyle(
              color: UcrColors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    ],
  );
}

/// Official UCR signature (horizontal, two lines, color, for light
/// backgrounds), never distorted (manual p. 35); otherwise the institution
/// name as text.
///
/// Never smaller than [minHeight]: the base of the shield must measure at
/// least 1.5 cm (manual p. 37), about 94 dp, and in this signature the
/// shield is about 0.9 of its height.
class UcrSignature extends StatelessWidget {
  const UcrSignature({super.key});

  static const double minHeight = 106;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/firma_ucr.png',
    height: minHeight,
    fit: BoxFit.contain,
    semanticLabel: 'Universidad de Costa Rica',
    errorBuilder: (context, _, _) => Text(
      'UNIVERSIDAD DE COSTA RICA · SEDE DEL SUR',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// White card with an icon header: the building block of form and summary.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: UcrColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Hours per weekday as bars (Monday to Saturday). Days above the 10-hour
/// daily limit (rule 7.4) are drawn in the error color.
class WeekOverview extends StatelessWidget {
  const WeekOverview({super.key, required this.intervals});

  final List<ScheduleInterval> intervals;

  static const _dailyLimitMinutes = 10 * 60;
  static const _barMaxHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perDay = {
      for (final day in Weekday.values)
        day: intervals
            .where((i) => i.day == day)
            .fold(0, (sum, i) => sum + i.durationMinutes),
    };
    final scale = perDay.values.fold(
      _dailyLimitMinutes,
      (a, b) => a > b ? a : b,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final MapEntry(key: day, value: minutes) in perDay.entries)
          Expanded(
            child: Semantics(
              label: '${day.title}: ${TimeRules.hoursLabel(minutes)}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    minutes == 0 ? '—' : TimeRules.hoursLabel(minutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: _barMaxHeight,
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: _barMaxHeight * minutes / scale,
                      decoration: BoxDecoration(
                        gradient: minutes > _dailyLimitMinutes
                            ? null
                            : const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [UcrColors.blue, UcrColors.skyBlue],
                              ),
                        color: minutes > _dailyLimitMinutes
                            ? theme.colorScheme.error
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.title.substring(0, 3),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Colored notice: success, error or neutral information.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.lines = const [],
    this.tone = BannerTone.info,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      BannerTone.success => (
        UcrColors.green.withValues(alpha: 0.18),
        const Color(0xFF1E5A1B),
      ),
      BannerTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      BannerTone.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: TextStyle(color: foreground)),
                        Expanded(
                          child: Text(
                            line,
                            style: text.bodyMedium?.copyWith(color: foreground),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { success, error, info }

/// Two-button bar pinned at the bottom of form and summary.
class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: UcrColors.white,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Label and value that cannot be edited here (profile data, fixed
/// institution, summary lines).
class ReadOnlyLine extends StatelessWidget {
  const ReadOnlyLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
