import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/screens/auth/register_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shown to an account without a profile: its sign-up did not finish (for
/// example, the cédula belonged to another account). Name, cédula and phone
/// are asked once; the cédula is loaded into every declaration.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: context.read<AppUser?>()?.displayName,
  );
  final _id = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  late String? _error = context.read<AuthRepository>().takeSignUpNotice();

  @override
  void dispose() {
    for (final c in [_name, _id, _phone]) {
      c.dispose();
    }
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
      // The profile stream then moves on to the next step.
      await context.read<ProfileRepository>().create(
        user.uid,
        UserProfile(
          fullName: _name.text,
          identification: _id.text,
          phone: _phone.text,
          email: user.email,
        ),
      );
    } on IdentificationTakenException {
      if (mounted) {
        setState(() => _error = IdentificationTakenException.message);
      }
    } catch (e) {
      debugPrint('Saving profile failed: $e');
      if (mounted) {
        setState(
          () => _error =
              'No se pudo guardar. Revise la conexión e intente '
              'de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Complete su perfil',
    subtitle:
        'Su nombre y su cédula se cargan en cada declaración. Solo se '
        'registran una vez.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: AuthRules.nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
              counterText: '',
            ),
            validator: AuthRules.nameError,
          ),
          const SizedBox(height: 16),
          IdentificationField(controller: _id),
          const SizedBox(height: 16),
          PhoneField(controller: _phone),
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
