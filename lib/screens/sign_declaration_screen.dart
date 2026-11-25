import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/proyecto1/declaration_document_reader.dart';
import 'package:declara_ucr/data/proyecto1/declaration_signer.dart';
import 'package:declara_ucr/domain/oath_text.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/screens/declaration_pdf_screen.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the signing screen of the validated declaration [id]. Returns
/// `true` once it was signed and sent.
Future<bool> openSigning(BuildContext context, String id) async =>
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignDeclarationScreen(declarationId: id),
      ),
    ) ??
    false;

/// "Firmar declaración", as in the web of the Proyecto 1: the person reads
/// the sworn declaration filled with their data (and the PDF if they want),
/// accepts it and signs. The declaration goes to their reviewer and, from
/// then on, is read only.
///
/// The text shown is exactly the one stored with the signature, and it is
/// read from the server, as the PDF.
class SignDeclarationScreen extends StatefulWidget {
  const SignDeclarationScreen({super.key, required this.declarationId});

  final String declarationId;

  @override
  State<SignDeclarationScreen> createState() => _SignDeclarationScreenState();
}

class _SignDeclarationScreenState extends State<SignDeclarationScreen> {
  late Future<DeclarationDocument> _document = _read();
  bool _accepted = false;
  bool _signing = false;

  Future<DeclarationDocument> _read() =>
      context.read<DeclarationDocumentReader>().read(widget.declarationId);

  Future<void> _sign(String oathText) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _signing = true);
    try {
      await context.read<DeclarationSigner>().signAndSend(
        widget.declarationId,
        oathText: oathText,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Declaración firmada y enviada a su superior.'),
        ),
      );
      navigator.pop(true);
    } on DeclarationSaveException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on OfflineException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión: no se firmó. Revise la conexión e intente de '
            'nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Firmar declaración'),
      actions: [
        // The validated content, as it will be signed.
        DeclarationPdfAction(
          id: widget.declarationId,
          status: DeclarationStatus.validated,
        ),
      ],
    ),
    body: FutureBuilder(
      future: _document,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = snapshot.error;
        final document = snapshot.data;
        if (error != null || document == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoBanner(
                icon: Icons.error_outline,
                title: error is DocumentUnavailableException
                    ? error.message
                    : 'No se pudo cargar la declaración. Intente de nuevo.',
                tone: BannerTone.error,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _document = _read()),
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
              ),
            ],
          );
        }
        if (document.kind != DocumentKind.preview) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: InfoBanner(
              icon: Icons.info_outline,
              title: 'Esta declaración no está lista para firmar.',
              lines: [
                'Se firma después de validarla, y una sola vez por versión.',
              ],
            ),
          );
        }
        final oath = OathText.of(document);
        return _Body(
          oath: oath,
          versionNumber: document.versionNumber,
          accepted: _accepted,
          signing: _signing,
          onAccepted: (value) => setState(() => _accepted = value),
          onSign: () => _sign(oath),
        );
      },
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.oath,
    required this.versionNumber,
    required this.accepted,
    required this.signing,
    required this.onAccepted,
    required this.onSign,
  });

  final String oath;
  final int versionNumber;
  final bool accepted;
  final bool signing;
  final ValueChanged<bool> onAccepted;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const InfoBanner(
          icon: Icons.verified_outlined,
          title: 'La declaración pasó la validación.',
          lines: [
            'Revísela (puede ver el PDF arriba), acepte la declaración jurada '
                'y fírmela: se enviará a su superior y ya no podrá cambiarla.',
          ],
          tone: BannerTone.success,
        ),
        const SizedBox(height: 16),
        SectionCard(
          icon: Icons.gavel_outlined,
          title: 'Declaración jurada',
          subtitle: 'Versión $versionNumber',
          children: [
            SelectableText(oath),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: accepted,
              onChanged: signing ? null : (v) => onAccepted(v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Acepto la declaración jurada y confirmo que la información '
                'es verdadera y completa.',
              ),
            ),
          ],
        ),
        Text(
          'Firma electrónica interna del sistema: queda registrada con su '
          'nombre, la fecha y la huella del contenido. No equivale a una '
          'firma digital certificada.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          key: const ValueKey('sign-and-send'),
          onPressed: accepted && !signing ? onSign : null,
          icon: signing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.draw_outlined),
          label: const Text('Firmar y enviar a mi superior'),
        ),
      ),
    ),
  );
}
