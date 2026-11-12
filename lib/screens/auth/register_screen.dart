import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/domain/field_rules.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _id, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the session stream rebuilds the app on the home
      // screen; this route goes away with it.
      await context.read<AuthRepository>().register(
        name: _name.text,
        identification: _id.text,
        email: _email.text,
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Crear cuenta',
    subtitle: 'Regístrese con su correo institucional @ucr.ac.cr.',
    showBack: true,
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthRules.passwordError,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                'Mínimo ${AuthRules.passwordMinLength} caracteres, con letras '
                'y números.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirm,
              label: 'Confirmar contraseña',
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) =>
                  v != _password.text ? 'Las contraseñas no coinciden.' : null,
              onSubmitted: _submit,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              InfoBanner(
                icon: Icons.error_outline,
                title: _error!,
                tone: BannerTone.error,
              ),
              const SizedBox(height: 16),
            ],
            BusyButton(label: 'Crear cuenta', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    ),
  );
}

/// Cédula: 9 digits only, validated with [FieldRules.identificationError].
/// Shared by sign-up and the profile completion.
class IdentificationField extends StatelessWidget {
  const IdentificationField({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    textInputAction: onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(9),
    ],
    decoration: const InputDecoration(
      labelText: 'Número de cédula',
      helperText: '9 dígitos con los ceros, sin guiones (ej. 105430987)',
      prefixIcon: Icon(Icons.pin_outlined),
    ),
    validator: FieldRules.identificationError,
    onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
  );
}
