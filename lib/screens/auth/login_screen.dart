import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/screens/auth/register_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the app switches screens by itself (session stream).
      await context.read<AuthRepository>().signIn(
        email: _email.text,
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final auth = context.read<AuthRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text),
    );
    if (email == null) return;
    try {
      await auth.sendPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Si existe una cuenta con ese correo, le enviamos un enlace para '
            'restablecer la contraseña.',
          ),
        ),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Bienvenido',
    subtitle:
        'Declaraciones juradas de horario y jornada de trabajo de la '
        'Universidad de Costa Rica.',
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                hintText: 'nombre.apellido@ucr.ac.cr',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: AuthRules.emailError,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'Contraseña',
              // Sign-in only checks presence: old passwords may predate
              // the current strength rules.
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Ingrese su contraseña.' : null,
              onSubmitted: _submit,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: const Text('¿Olvidó su contraseña?'),
              ),
            ),
            if (_error != null) ...[
              InfoBanner(
                icon: Icons.error_outline,
                title: _error!,
                tone: BannerTone.error,
              ),
              const SizedBox(height: 16),
            ],
            BusyButton(
              label: 'Iniciar sesión',
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '¿Primera vez aquí?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Restablecer contraseña'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Le enviaremos un enlace a su correo institucional.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo institucional',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: AuthRules.emailError,
            onFieldSubmitted: (_) => _send(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _send, child: const Text('Enviar enlace')),
    ],
  );
}
