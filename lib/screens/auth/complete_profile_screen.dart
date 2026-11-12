import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/screens/auth/register_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Asked once to accounts created before the cédula was part of sign-up:
/// it is loaded into every declaration and cannot be typed there.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  bool _busy = false;
  late String? _error = context.read<AuthRepository>().takeSignUpNotice();

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppUser?>()!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The profile stream then opens the app.
      await context.read<ProfileRepository>().save(
        user.uid,
        UserProfile(
          name: user.displayName.isEmpty ? user.firstName : user.displayName,
          identification: _id.text,
        ),
      );
    } on IdentificationTakenException {
      if (mounted) {
        setState(() => _error = IdentificationTakenException.message);
      }
    } catch (e) {
      debugPrint('Saving profile failed: $e');
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Intente de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Complete su perfil',
    subtitle:
        'Su cédula se carga en cada declaración. Solo se registra una vez.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IdentificationField(controller: _id, onSubmitted: _submit),
          const SizedBox(height: 24),
          if (_error != null) ...[
            InfoBanner(
              icon: Icons.error_outline,
              title: _error!,
              tone: BannerTone.error,
            ),
            const SizedBox(height: 16),
          ],
          BusyButton(label: 'Guardar', busy: _busy, onPressed: _submit),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<AuthRepository>().signOut(),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    ),
  );
}
