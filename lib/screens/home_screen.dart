import 'package:declara_ucr/config/build_info.dart';
import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/edit_profile_screen.dart';
import 'package:declara_ucr/screens/sign_declaration_screen.dart';
import 'package:declara_ucr/screens/tutorial_screen.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:declara_ucr/widgets/declaration_progress.dart';
import 'package:declara_ucr/widgets/tour_anchor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Inicio: identifies the system (R1), greets the person, shows their
/// profile and the latest declaration with its tracking and hours. The
/// other sections are in the bottom navigation bar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showProfile(BuildContext context, AppUser user, UserProfile? p) =>
      showModalBottomSheet<void>(
        context: context,
        // Taller than the default 9/16 of the screen on a small phone.
        isScrollControlled: true,
        builder: (sheetContext) => _ProfileSheet(
          user: user,
          profile: p,
          onEdit: p == null
              ? null
              : () =>
                    _replaceSheet(sheetContext, EditProfileScreen(profile: p)),
          onTour: () => _replaceSheet(sheetContext, const TutorialScreen()),
          onSignOut: () {
            Navigator.of(sheetContext).pop();
            context.read<AuthRepository>().signOut();
          },
        ),
      );

  /// Closes the profile sheet and opens [screen] in its place.
  static void _replaceSheet(BuildContext sheetContext, Widget screen) {
    final navigator = Navigator.of(sheetContext)..pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>()!;
    final profile = context.watch<UserProfile?>();
    final declarations =
        context.watch<Loadable<List<Declaration>>>().value ??
        const <Declaration>[];
    final latest = declarations.isEmpty ? null : declarations.first;
    int count(DeclarationStatus s) =>
        declarations.where((d) => d.status == s).length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(
          user: user,
          profile: profile,
          onProfile: () => _showProfile(context, user, profile),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The rules reject a new declaration without a superior, and
              // only administration assigns one (from the web).
              if (profile != null && !profile.hasSuperior) ...[
                const InfoBanner(
                  icon: Icons.supervisor_account_outlined,
                  title: 'Aún no tiene superior asignado.',
                  lines: [
                    'Administración debe asignarlo en el sistema web antes '
                        'de que pueda crear su declaración.',
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _Counter(
                    label: 'Borradores',
                    count: count(DeclarationStatus.draft),
                  ),
                  const SizedBox(width: 10),
                  _Counter(
                    label: 'Validadas',
                    count: count(DeclarationStatus.validated),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (latest == null)
                SectionCard(
                  icon: Icons.post_add_rounded,
                  title: 'Su primera declaración',
                  subtitle: 'Agregue sus cursos y ubíquelos en el horario.',
                  children: [
                    FilledButton.icon(
                      onPressed: () => openDeclaration(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva declaración'),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              else
                TourAnchor(
                  id: 'home.latest',
                  child: _LatestCard(declaration: latest),
                ),
              const SizedBox(height: 24),
              const Center(child: UcrSignature()),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.profile,
    required this.onProfile,
  });

  final AppUser user;
  final UserProfile? profile;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final soft = UcrColors.white.withValues(alpha: 0.82);
    return Container(
      decoration: const BoxDecoration(
        color: UcrColors.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(),
                  const Spacer(),
                  TourAnchor(
                    id: 'home.profile',
                    child: Semantics(
                      container: true,
                      button: true,
                      label: 'Perfil y cerrar sesión',
                      excludeSemantics: true,
                      child: InkResponse(
                        onTap: onProfile,
                        radius: 28,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: UcrColors.skyBlue,
                            child: Text(
                              user.initials,
                              style: text.labelLarge?.copyWith(
                                color: UcrColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Hola, ${user.firstName}',
                style: text.headlineSmall?.copyWith(color: UcrColors.white),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Sistema de Declaraciones Juradas de Horario y Jornada de '
                  'Trabajo',
                  style: text.bodyMedium?.copyWith(color: soft),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _HeaderFact(
                    Icons.pin_outlined,
                    profile?.identification ?? '—',
                  ),
                  const _HeaderFact(Icons.school_outlined, Workplace.full),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  const _HeaderFact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final soft = UcrColors.white.withValues(alpha: 0.9);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: soft),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: soft),
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '$label: $count',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// The most recent declaration: where it is in the process (as the web's
/// tracking), workday and hours by category.
class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.declaration});

  final Declaration declaration;

  @override
  Widget build(BuildContext context) {
    final d = declaration;
    final workday = WorkloadCatalog.labelFor(d.coursesMinutes);
    String hours(TaskKind kind) =>
        TimeRules.hoursLabel(d.placedMinutesOf(kind));
    return SectionCard(
      icon: Icons.description_outlined,
      title: 'Declaración más reciente',
      subtitle:
          '${formatDate(d.validFrom)} – ${formatDate(d.validTo)}'
          '${workday == null ? '' : ' · $workday'}',
      children: [
        DeclarationProgress(status: d.status),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in [
              TaskKind.lesson,
              TaskKind.attention,
              TaskKind.planning,
            ])
              _HoursChip('${kind.code}: ${hours(kind)}'),
            _HoursChip('Total: ${TimeRules.hoursLabel(d.totalMinutes)}'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // The next step of a validated declaration: sign and send it.
            if (d.id != null &&
                (d.status == DeclarationStatus.validated ||
                    d.status == DeclarationStatus.pendingDeclarantSignature))
              FilledButton.icon(
                onPressed: () => openSigning(context, d.id!),
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Firmar y enviar'),
              ),
            OutlinedButton.icon(
              onPressed: () => openDeclaration(context, d.id),
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                d.status == DeclarationStatus.draft ? 'Continuar' : 'Abrir',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.user,
    required this.profile,
    required this.onEdit,
    required this.onTour,
    required this.onSignOut,
  });

  final AppUser user;
  final UserProfile? profile;
  final VoidCallback? onEdit;
  final VoidCallback onTour;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: UcrColors.skyBlue,
              child: Text(
                user.initials,
                style: text.titleLarge?.copyWith(color: UcrColors.ink),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile?.name ?? user.displayName,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cédula ${profile?.identification ?? '—'} · ${Workplace.campus}',
              textAlign: TextAlign.center,
              style: text.labelMedium,
            ),
            Text(
              profile == null || profile!.phone.isEmpty
                  ? 'Sin teléfono'
                  : 'Teléfono ${profile!.phone}',
              textAlign: TextAlign.center,
              style: text.labelMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar mis datos'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTour,
                icon: const Icon(Icons.help_outline),
                label: const Text('Cómo funciona'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              BuildInfo.label,
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hours of a kind, as text: a plain [Chip] is read as an unchecked
/// checkbox by screen readers.
class _HoursChip extends StatelessWidget {
  const _HoursChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    label: text,
    excludeSemantics: true,
    child: Chip(label: Text(text)),
  );
}
