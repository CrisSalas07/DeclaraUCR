import 'dart:async';

import 'package:declara_ucr/data/network_status.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/domain/auth_rules.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/screens/auth/register_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The person's own name, cédula and phone (U-07). Email, campus and career
/// are Administración's; signed declarations keep the data they were signed
/// with.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _id = TextEditingController(text: widget.profile.identification);
  late final _phone = TextEditingController(text: widget.profile.phone);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _id, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AppUser?>()!.uid;
    final network = context.read<NetworkStatus>();
    final profiles = context.read<ProfileRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      if (!await network.isOnline()) throw const OfflineException();
      await profiles
          .updateOwn(
            uid,
            widget.profile,
            fullName: _name.text,
            identification: _id.text,
            phone: _phone.text,
          )
          .timeout(const Duration(seconds: 15));
    } on IdentificationTakenException {
      error = IdentificationTakenException.message;
    } on OfflineException {
      error = OfflineException.message;
    } on TimeoutException {
      error =
          'El servidor no respondió a tiempo. Revise la conexión e intente '
          'de nuevo.';
    } catch (e) {
      // Technical details go to the log, never to the user.
      debugPrint('Updating profile failed: $e');
      error = 'No se pudo guardar. Revise la conexión e intente de nuevo.';
    }
    if (!mounted) return;
    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sus datos se guardaron.')),
      );
      navigator.pop();
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis datos')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.info_outline,
            title: 'Se usan en sus próximas declaraciones.',
            lines: [
              'Las declaraciones ya firmadas conservan los datos con que se '
                  'firmaron. El correo, la sede y la carrera los cambia '
                  'Administración.',
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.error_outline,
              title: _error!,
              tone: BannerTone.error,
            ),
          ],
          const SizedBox(height: 24),
          BusyButton(label: 'Guardar', busy: _busy, onPressed: _submit),
        ],
      ),
    ),
  );
}
