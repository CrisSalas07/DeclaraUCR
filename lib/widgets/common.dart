import 'package:declara_ucr/models/declaration_status.dart';
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
  const StatusChip(this.status, {super.key});

  final DeclarationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.extension<StatusColors>()!.of(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.value,
        style: theme.textTheme.labelMedium?.copyWith(
          color: UcrColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Institutional header: the official signature if it is bundled in assets,
/// never distorted (5.2); otherwise the institution name as text.
class UcrHeader extends StatelessWidget {
  const UcrHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.secondary, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Image.asset(
        'assets/images/firma_ucr.png',
        height: 48,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        semanticLabel: 'Universidad de Costa Rica',
        errorBuilder: (_, _, _) => Text(
          'UNIVERSIDAD DE COSTA RICA · SEDE DEL SUR',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Section title of the form and the summary.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
