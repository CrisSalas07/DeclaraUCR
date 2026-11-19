import 'dart:typed_data';

import 'package:declara_ucr/data/proyecto1/declaration_document_reader.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/pdf/declaration_pdf.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

/// App bar action that opens the PDF of the saved declaration [id] in
/// [status]; nothing while there is no PDF yet (not saved, a draft or
/// returned: validate it first).
class DeclarationPdfAction extends StatelessWidget {
  const DeclarationPdfAction({
    super.key,
    required this.id,
    required this.status,
  });

  final String? id;
  final DeclarationStatus status;

  @override
  Widget build(BuildContext context) {
    final saved = id;
    if (saved == null || DeclarationDocument.kindFor(status) == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: 'Ver PDF',
      // The red of PDF files, so it stands out on the light app bar
      // (5.2:1 against it).
      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFC62828)),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DeclarationPdfScreen(declarationId: saved),
        ),
      ),
    );
  }
}

/// The PDF of a validated declaration, as the web prints it: a "BORRADOR"
/// preview before signing, a copy "EN REVISIÓN" while it is reviewed, or the
/// final document. Shown on screen, with the system's actions to save,
/// share or print it.
class DeclarationPdfScreen extends StatefulWidget {
  const DeclarationPdfScreen({super.key, required this.declarationId});

  final String declarationId;

  @override
  State<DeclarationPdfScreen> createState() => _DeclarationPdfScreenState();
}

class _DeclarationPdfScreenState extends State<DeclarationPdfScreen> {
  late Future<(DeclarationDocument, Uint8List)> _pdf = _build();

  Future<(DeclarationDocument, Uint8List)> _build() async {
    final document = await context.read<DeclarationDocumentReader>().read(
      widget.declarationId,
    );
    if (document.kind == null) {
      throw const DocumentUnavailableException(
        'El PDF está disponible después de validar la declaración.',
      );
    }
    return (document, await DeclarationPdf.build(document));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PDF de la declaración')),
    body: FutureBuilder(
      future: _pdf,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = snapshot.error;
        if (error != null) {
          if (error is! DocumentUnavailableException) {
            debugPrint('Building the PDF failed: $error');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoBanner(
                icon: Icons.error_outline,
                title: error is DocumentUnavailableException
                    ? error.message
                    : 'No se pudo generar el PDF. Intente de nuevo.',
                tone: BannerTone.error,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _pdf = _build()),
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
              ),
            ],
          );
        }
        final (document, bytes) = snapshot.data!;
        return PdfPreview.builder(
          build: (_) async => bytes,
          initialPageFormat: PdfPageFormat.letter.landscape,
          pdfFileName: document.fileName,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          // Sharp enough to read at the largest zoom (the default follows
          // the screen width, and a landscape page on a phone is tiny).
          dpi: 220,
          pagesBuilder: (context, pages) => _ZoomablePages(pages: pages),
        );
      },
    ),
  );
}

/// The pages, one below the other, zoomed with two fingers and moved with
/// one, right away (the package's own view only zooms after a double tap,
/// which nobody finds). A double tap goes back to the whole page.
class _ZoomablePages extends StatefulWidget {
  const _ZoomablePages({required this.pages});

  final List<PdfPreviewPageData> pages;

  @override
  State<_ZoomablePages> createState() => _ZoomablePagesState();
}

class _ZoomablePagesState extends State<_ZoomablePages> {
  final _transform = TransformationController();

  static const double _gap = 12;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final width = viewport.maxWidth - 2 * _gap;
              return GestureDetector(
                onDoubleTap: () => _transform.value = Matrix4.identity(),
                child: InteractiveViewer(
                  transformationController: _transform,
                  // The content keeps its own size (it may be taller than
                  // the screen) and is moved around instead of squeezed.
                  constrained: false,
                  minScale: 1,
                  maxScale: 6,
                  // At least as big as the screen: the viewer never lets
                  // the content get smaller than the screen, so a page
                  // shorter than it could be zoomed in but not out again.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: viewport.maxWidth,
                      maxWidth: viewport.maxWidth,
                      minHeight: viewport.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(_gap),
                      child: Column(
                        children: [
                          for (final (i, page) in pages.indexed) ...[
                            if (i > 0) const SizedBox(height: _gap),
                            DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Image(
                                image: page.image,
                                width: width,
                                height: width / page.aspectRatio,
                                fit: BoxFit.contain,
                                semanticLabel:
                                    'Página ${i + 1} de ${pages.length}',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
