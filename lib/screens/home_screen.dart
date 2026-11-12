import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/shell_screen.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Inicio: identifies the system (R1), greets the person, shows their
/// profile, the latest declaration with its hours, and shortcuts to the
/// other sections.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches to another section ([Sections]).
  final ValueChanged<int> onNavigate;

  void _showProfile(BuildContext context, AppUser user, UserProfile? p) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => _ProfileSheet(
          user: user,
          profile: p,
          onSignOut: () {
            Navigator.of(sheetContext).pop();
            context.read<AuthRepository>().signOut();
          },
        ),
      );

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
    final theme = Theme.of(context);

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
                _LatestCard(declaration: latest),
              Text('Accesos rápidos', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _Shortcut(
                icon: Icons.add_circle_outline,
                title: 'Nueva declaración',
                subtitle: 'Cursos, proyectos y horario semanal',
                onTap: () => openDeclaration(context, null),
              ),
              _Shortcut(
                icon: Icons.description_outlined,
                title: 'Mis declaraciones',
                subtitle: 'Borradores y validadas',
                onTap: () => onNavigate(Sections.declarations),
              ),
              _Shortcut(
                icon: Icons.directions_car_outlined,
                title: 'Zonaje',
                subtitle: 'Solicitud por traslado de domicilio',
                onTap: () => onNavigate(Sections.zonaje),
              ),
              _Shortcut(
                icon: Icons.history,
                title: 'Historial',
                subtitle: 'Declaraciones y solicitudes por año',
                onTap: () => onNavigate(Sections.history),
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
                  const BrandMark(size: 34),
                  const Spacer(),
                  Semantics(
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

/// The most recent declaration: status, workday and hours by category.
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
      trailing: StatusChip(d.status),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in [
              TaskKind.lesson,
              TaskKind.attention,
              TaskKind.planning,
            ])
              Chip(label: Text('${kind.code}: ${hours(kind)}')),
            Chip(label: Text('Total: ${TimeRules.hoursLabel(d.totalMinutes)}')),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => openDeclaration(context, d.id),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              d.status == DeclarationStatus.draft ? 'Continuar' : 'Abrir',
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(icon, color: UcrColors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.user,
    required this.profile,
    required this.onSignOut,
  });

  final AppUser user;
  final UserProfile? profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
