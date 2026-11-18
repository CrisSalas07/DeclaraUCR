import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/screens/auth/auth_layout.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Complete su perfil", second part: the campus and, for a declarant, the
/// career. Chosen once, as in the web system: afterwards only
/// administration can change them. A campus already set by administration
/// is shown and not asked again.
class WorkplaceScreen extends StatefulWidget {
  const WorkplaceScreen({super.key});

  @override
  State<WorkplaceScreen> createState() => _WorkplaceScreenState();
}

class _WorkplaceScreenState extends State<WorkplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileRepository _profiles = context.read<ProfileRepository>();
  late Future<List<OrgUnit>> _campuses = _profiles.activeCampuses();
  Future<List<OrgUnit>>? _careers;
  String? _campusId;
  String? _unitId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _campusId = context.read<UserProfile?>()?.campusId;
    _loadCareers();
  }

  void _loadCareers() {
    final profile = context.read<UserProfile?>();
    final campus = _campusId;
    _careers = profile != null && profile.needsCareer && campus != null
        ? _profiles.activeCareers(campus)
        : null;
  }

  void _retry() => setState(() {
    _campuses = _profiles.activeCampuses();
    _loadCareers();
  });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppUser?>()!;
    final profile = context.read<UserProfile?>()!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The profile stream then opens the app.
      await _profiles.chooseWorkplace(
        user.uid,
        profile,
        campusId: _campusId,
        unitId: _unitId,
      );
    } catch (e) {
      debugPrint('Saving workplace failed: $e');
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
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfile?>()!;
    return AuthLayout(
      title: 'Complete su perfil',
      subtitle:
          'Elija su sede y su carrera. Solo se eligen una vez; después, '
          'solo Administración puede cambiarlas.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Choice(
              future: _campuses,
              label: 'Sede',
              icon: Icons.location_city_outlined,
              value: _campusId,
              locked: !profile.needsCampus,
              emptyMessage:
                  'Administración aún no registró sedes. Intente más tarde.',
              onRetry: _retry,
              onChanged: (id) => setState(() {
                _campusId = id;
                _unitId = null;
                _loadCareers();
              }),
            ),
            if (profile.needsCareer) ...[
              const SizedBox(height: 16),
              if (_careers == null)
                const InfoBanner(
                  icon: Icons.info_outline,
                  title: 'Elija primero la sede para ver sus carreras.',
                )
              else
                _Choice(
                  key: ValueKey(_campusId),
                  future: _careers!,
                  label: 'Carrera',
                  icon: Icons.school_outlined,
                  value: _unitId,
                  emptyMessage:
                      'Esta sede aún no tiene carreras registradas. '
                      'Consulte a Administración.',
                  onRetry: _retry,
                  onChanged: (id) => setState(() => _unitId = id),
                ),
            ],
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
}

/// A required list choice loaded from Firestore, with its loading, empty
/// and error states. [locked] shows the stored value without letting it
/// change.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.future,
    required this.label,
    required this.icon,
    required this.value,
    required this.emptyMessage,
    required this.onRetry,
    required this.onChanged,
    this.locked = false,
  });

  final Future<List<OrgUnit>> future;
  final String label;
  final IconData icon;
  final String? value;
  final String emptyMessage;
  final VoidCallback onRetry;
  final ValueChanged<String?> onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<OrgUnit>>(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snap.hasError) {
        debugPrint('Loading $label failed: ${snap.error}');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoBanner(
              icon: Icons.cloud_off_outlined,
              title: 'No se pudo cargar la lista de ${label.toLowerCase()}s.',
              tone: BannerTone.error,
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        );
      }
      final items = snap.data!;
      if (items.isEmpty && !locked) {
        return InfoBanner(icon: Icons.info_outline, title: emptyMessage);
      }
      // A stored value that is no longer offered (e.g. an inactive campus)
      // is still shown by its id rather than left blank.
      final options = [
        ...items,
        if (value != null && items.every((i) => i.id != value))
          OrgUnit(id: value!, name: value!),
      ];
      return DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: locked ? 'Asignada por Administración' : null,
        ),
        items: [
          for (final item in options)
            DropdownMenuItem(
              value: item.id,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: locked ? null : onChanged,
        validator: (v) => v == null ? 'Elija una opción.' : null,
      );
    },
  );
}
