import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Why an account cannot use the mobile app, which is for declarants: the
/// account is disabled, or its roles (assigned by administration in the web
/// system) do not include declarant. Only offers to sign out.
class AccountNoticeScreen extends StatelessWidget {
  const AccountNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfile?>()!;
    final (title, detail) = !profile.active
        ? (
            'Su cuenta está desactivada.',
            'Consulte a Administración de su sede para reactivarla.',
          )
        : (
            'Esta aplicación es para personas declarantes.',
            'Su cuenta tiene el rol de '
                '${profile.roles.map((r) => r.label).join(' y ')}. Use el '
                'sistema web de declaraciones para sus funciones.',
          );
    return AuthLayout(
      title: 'No puede continuar',
      subtitle: profile.fullName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(icon: Icons.info_outline, title: title, lines: [detail]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<AuthRepository>().signOut(),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
