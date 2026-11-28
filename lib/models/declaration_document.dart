import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';

/// A declaration exactly as the Proyecto 1 stored it, to print it: the
/// current version with the person's data copied into it, the appointments,
/// the other institutions, the signatures and the oath. The PDF is built
/// from this and not from the form's [Declaration], so the phone prints the
/// same document as the web.
class DeclarationDocument {
  const DeclarationDocument({
    required this.status,
    required this.versionNumber,
    required this.person,
    required this.periodName,
    required this.observations,
    required this.appointments,
    required this.externalJobs,
    required this.signatures,
    required this.oathTemplate,
    this.contentHash,
    this.createdAt,
  });

  final DeclarationStatus status;
  final int versionNumber;

  /// `declarantSnapshot` of the version: the data as it was declared.
  final DocumentPerson person;
  final String periodName;
  final String observations;
  final List<DocumentJob> appointments;
  final List<DocumentJob> externalJobs;
  final List<DocumentSignature> signatures;

  /// The administrator's template (`config/oath`), or `null` for the
  /// default one. Only used while the declarant has not signed.
  final String? oathTemplate;

  /// Fingerprint of the signed content, once there is one.
  final String? contentHash;
  final DateTime? createdAt;

  /// The signature of [type], if it was recorded.
  DocumentSignature? signatureOf(SignatureType type) {
    for (final signature in signatures) {
      if (signature.type == type) return signature;
    }
    return null;
  }

  /// What the PDF is, by status, as in DeclaraHorario (`PdfState`):
  /// a preview before the declarant signs, a copy for review while it is
  /// being signed and reviewed, the final document once finished. `null`
  /// while it is still a draft or was returned (validate it first), and for
  /// an annulled one, which is no longer in review.
  DocumentKind? get kind => kindFor(status);

  static DocumentKind? kindFor(DeclarationStatus status) => switch (status) {
    DeclarationStatus.draft ||
    DeclarationStatus.returned ||
    DeclarationStatus.annulled => null,
    DeclarationStatus.validated ||
    DeclarationStatus.pendingDeclarantSignature => DocumentKind.preview,
    DeclarationStatus.closed => DocumentKind.finalDocument,
    _ => DocumentKind.review,
  };

  /// Name of the file, as the web names it.
  String get fileName => switch (kind) {
    DocumentKind.finalDocument => 'declaracion-final-v$versionNumber.pdf',
    DocumentKind.review => 'declaracion-en-revision-v$versionNumber.pdf',
    _ => 'vista-previa-declaracion-v$versionNumber.pdf',
  };
}

/// Which PDF a declaration gives, by how far its signing went.
enum DocumentKind {
  /// "BORRADOR": validated, not signed yet; no signatures are printed.
  preview,

  /// "EN REVISIÓN": the signatures recorded so far.
  review,

  /// The final document, with the three signatures.
  finalDocument,
}

/// The person's data copied into the version.
class DocumentPerson {
  const DocumentPerson({
    required this.fullName,
    required this.identification,
    required this.phone,
    required this.email,
    required this.unitName,
    required this.campusName,
  });

  final String fullName;
  final String identification;
  final String phone;
  final String email;
  final String unitName;
  final String campusName;
}

/// An appointment at the university or a job at another institution: one
/// group of rows of the form.
class DocumentJob {
  const DocumentJob({
    required this.workplace,
    required this.position,
    required this.workload,
    required this.from,
    required this.to,
    required this.blocks,
    this.weeklyMinutes,
  });

  final String workplace;
  final String position;

  /// The workday as stored, e.g. "1/2 TC".
  final String workload;
  final DateTime from;
  final DateTime to;
  final List<DocumentBlock> blocks;

  /// Weekly minutes of an external job, when stored.
  final int? weeklyMinutes;
}

/// One block of the schedule.
class DocumentBlock {
  const DocumentBlock(this.day, this.startMinutes, this.endMinutes);

  final Weekday day;
  final int startMinutes;
  final int endMinutes;
}

/// Who signs, in order; [value] is the type stored by the Proyecto 1.
enum SignatureType {
  declarant('declarant'),
  superior('superior'),
  hr('hr');

  const SignatureType(this.value);

  final String value;

  static SignatureType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// A recorded internal electronic signature (not a certified digital one).
class DocumentSignature {
  const DocumentSignature({
    required this.type,
    required this.fullName,
    this.signedAt,
    this.oathText,
    this.contentHash,
  });

  final SignatureType type;
  final String fullName;
  final DateTime? signedAt;

  /// The exact oath the declarant accepted (declarant signature only).
  final String? oathText;
  final String? contentHash;
}
