import 'package:flutter/material.dart';

import '/backend/bordereau_check.dart';
import '/backend/expedion_api/expedion_quote.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// The verdict panel under the bordereau upload on *Formulaire de devis par
/// bordereau*.
///
/// It renders one of four things, matching [BordereauCheck.status]: nothing at
/// all, a "reading your slip" progress row, the fields the model found, or the
/// reason the document was refused. The refusal case carries the link to
/// [showBordereauGuideDialog], which is the only place the standard is written
/// down for the client — a bare "invalid file" leaves them with nothing to act
/// on, which is how a rejected upload becomes an abandoned quote.
class BordereauReviewPanel extends StatelessWidget {
  const BordereauReviewPanel({
    super.key,
    required this.check,
    required this.onRetry,
  });

  final BordereauCheck check;

  /// Re-runs the extraction on the file already attached. Null when there is
  /// no attached file to re-read.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (check.status) {
      case BordereauCheckStatus.idle:
        return const SizedBox.shrink();
      case BordereauCheckStatus.checking:
        return const _CheckingRow();
      case BordereauCheckStatus.valid:
        return _ValidPanel(check: check);
      case BordereauCheckStatus.invalid:
        return _InvalidPanel(check: check, onRetry: onRetry);
      case BordereauCheckStatus.unavailable:
        return _UnavailablePanel(check: check, onRetry: onRetry);
    }
  }
}

// ========================================
// Nothing to review yet
// ========================================

/// Shown in place of [BordereauReviewPanel] when no slip is attached.
///
/// The bordereau was always marked required with an asterisk and never
/// enforced, so "Envoyer" on an empty form filed a devis with no document on
/// it. Now the button is disabled, and this says why — including the case
/// nobody could see before, where the file was picked but never reached
/// storage.
class BordereauMissingHint extends StatelessWidget {
  const BordereauMissingHint({super.key, required this.uploadFailed});

  /// A file was chosen but its upload did not produce a URL.
  final bool uploadFailed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _Frame(
      status: uploadFailed ? DSStatus.danger : DSStatus.neutral,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            uploadFailed ? Icons.error_outline : Icons.upload_file_outlined,
            size: 20.0,
            color: uploadFailed ? theme.error : theme.secondaryText,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uploadFailed
                      ? xpdT(
                          context,
                          "L'envoi du fichier a échoué. Sélectionnez-le à "
                          'nouveau.',
                          'That file did not upload. Pick it again.',
                        )
                      : xpdT(
                          context,
                          'Le bordereau est obligatoire pour envoyer votre '
                          'demande.',
                          'Your slip is required before the request can be '
                          'sent.',
                        ),
                  style: theme.bodySmall.copyWith(color: theme.primaryText),
                ),
                const SizedBox(height: 8.0),
                _LinkLabel(
                  icon: Icons.help_outline,
                  label: xpdT(
                    context,
                    "Qu'est-ce qu'un bordereau valide ?",
                    'What counts as a valid slip?',
                  ),
                  onTap: () => showBordereauGuideDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Checking
// ========================================

class _CheckingRow extends StatelessWidget {
  const _CheckingRow();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _Frame(
      status: DSStatus.info,
      child: Row(
        children: [
          SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              xpdT(
                context,
                'Lecture du bordereau en cours…',
                'Reading your slip…',
              ),
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Valid — the preview
// ========================================

class _ValidPanel extends StatelessWidget {
  const _ValidPanel({required this.check});

  final BordereauCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Sections whose fields the model found nothing for are dropped entirely
    // rather than shown as a column of dashes: "buyer: —, —, —" reads as a
    // fault, when in fact most slips simply do not repeat the buyer's address.
    final sections = [
      for (final section in kBordereauSections)
        if (section.fields.any(check.has)) section,
    ];

    final incomplete = [
      for (final field in kBordereauFields)
        if (!field.isRequired && !check.has(field)) field,
    ];

    return _Frame(
      status: DSStatus.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 20.0, color: theme.success),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  xpdT(
                    context,
                    'Bordereau reconnu',
                    'Slip recognised',
                  ),
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (check.confidence != null)
                DSBadge.status(
                  label: xpdT(
                    context,
                    'Fiabilité ${(check.confidence! * 100).round()} %',
                    '${(check.confidence! * 100).round()}% confidence',
                  ),
                  status: check.confidence! >= 0.75
                      ? DSStatus.success
                      : DSStatus.warning,
                ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            xpdT(
              context,
              'Vérifiez ce que nous avons lu. Vous pourrez tout corriger avant '
              'la validation du devis.',
              'Check what we read. You can correct all of it before the quote '
              'is confirmed.',
            ),
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 16.0),
          for (final section in sections) ...[
            _SectionTitle(section: section),
            for (final field in section.fields)
              if (check.has(field))
                _FieldRow(
                  label: xpdT(context, field.labelFr, field.labelEn),
                  value: _formatValue(context, field, check.valueOf(field)),
                ),
            const SizedBox(height: 12.0),
          ],
          if (incomplete.isNotEmpty)
            Text(
              xpdT(
                context,
                'À compléter à l’étape suivante : '
                '${incomplete.map((f) => f.labelFr.toLowerCase()).join(', ')}.',
                'To complete at the next step: '
                '${incomplete.map((f) => f.labelEn.toLowerCase()).join(', ')}.',
              ),
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.section});

  final BordereauSection section;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        xpdT(context, section.titleFr, section.titleEn).toUpperCase(),
        style: theme.labelSmall.copyWith(
          color: theme.secondaryText,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160.0,
            child: Text(
              label,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              value,
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Invalid — the refusal
// ========================================

class _InvalidPanel extends StatelessWidget {
  const _InvalidPanel({required this.check, required this.onRetry});

  final BordereauCheck check;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Three different failures, three different things to say. A file we never
    // sent has a reason of its own; a document with nothing recognisable on it
    // is the wrong file; anything else is a real bordereau missing fields, and
    // naming them is what lets the client find the right document.
    final String detail;
    if (check.reasonFr != null) {
      detail = xpdT(context, check.reasonFr!, check.reasonEn!);
    } else if (check.looksUnrelated) {
      detail = xpdT(
        context,
        "Ce document ne ressemble pas à un bordereau d'adjudication : nous "
        "n'y avons trouvé aucune des informations attendues.",
        'This document does not look like an auction slip: none of the '
        'expected information was found on it.',
      );
    } else {
      final missing = check.missing
          .map((f) => xpdT(context, f.labelFr, f.labelEn).toLowerCase())
          .join(', ');
      detail = xpdT(
        context,
        'Il manque sur ce bordereau : $missing.',
        'This slip is missing: $missing.',
      );
    }

    return _Frame(
      status: DSStatus.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20.0, color: theme.error),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  xpdT(
                    context,
                    'Document non valide',
                    'Invalid document',
                  ),
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            detail,
            style: theme.bodySmall.copyWith(color: theme.primaryText),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LinkLabel(
                icon: Icons.help_outline,
                label: xpdT(
                  context,
                  "Qu'est-ce qu'un bordereau valide ?",
                  'What counts as a valid slip?',
                ),
                onTap: () => showBordereauGuideDialog(context),
              ),
              if (onRetry != null)
                _LinkLabel(
                  icon: Icons.refresh,
                  label: xpdT(context, 'Réessayer la lecture', 'Read it again'),
                  onTap: onRetry!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// Unavailable — we could not check
// ========================================

class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({required this.check, required this.onRetry});

  final BordereauCheck check;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _Frame(
      status: DSStatus.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.0, color: theme.warning),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  xpdT(
                    context,
                    'Vérification automatique indisponible',
                    'Automatic check unavailable',
                  ),
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            '${xpdApiErrorMessage(
              context,
              check.errorCode,
              fallbackFr: "Nous n'avons pas pu lire votre bordereau.",
              fallbackEn: 'We could not read your slip.',
            )} ${xpdT(
              context,
              'Vous pouvez envoyer votre demande : nous vérifierons le document '
              'à la main.',
              'You can still send your request — we will check the document by '
              'hand.',
            )}',
            style: theme.bodySmall.copyWith(color: theme.primaryText),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LinkLabel(
                icon: Icons.help_outline,
                label: xpdT(
                  context,
                  "Qu'est-ce qu'un bordereau valide ?",
                  'What counts as a valid slip?',
                ),
                onTap: () => showBordereauGuideDialog(context),
              ),
              if (onRetry != null)
                _LinkLabel(
                  icon: Icons.refresh,
                  label: xpdT(context, 'Réessayer la lecture', 'Read it again'),
                  onTap: onRetry!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// The standard, written out
// ========================================

/// What we accept, and what it has to carry.
///
/// Derived from the same list the gate uses ([kBordereauRequiredFields]) rather
/// than restated, so the dialog cannot drift away from what actually blocks the
/// button.
Future<void> showBordereauGuideDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = FlutterFlowTheme.of(dialogContext);
      const maxMb = kBordereauMaxBytes ~/ (1024 * 1024);

      return AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSShape.card),
        ),
        title: Text(
          xpdT(
            dialogContext,
            'Le bordereau attendu',
            'The slip we need',
          ),
          style: theme.titleMedium.copyWith(color: theme.primaryText),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  xpdT(
                    dialogContext,
                    "Le bordereau d'adjudication est le document que la maison "
                    'de ventes vous remet après la vente. C’est lui qui nous '
                    'dit où retirer votre lot et ce qu’il vaut.',
                    'The auction slip is the document the auction house hands '
                    'you after the sale. It is what tells us where to collect '
                    'your lot and what it is worth.',
                  ),
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 16.0),
                _GuideHeading(
                  label: xpdT(
                    dialogContext,
                    'Il doit faire apparaître',
                    'It must show',
                  ),
                ),
                for (final field in kBordereauRequiredFields)
                  _GuideBullet(
                    icon: Icons.check,
                    color: theme.success,
                    label: xpdT(dialogContext, field.labelFr, field.labelEn),
                  ),
                const SizedBox(height: 16.0),
                _GuideHeading(
                  label: xpdT(
                    dialogContext,
                    'Utile, mais pas obligatoire',
                    'Helpful, but not required',
                  ),
                ),
                _GuideBullet(
                  icon: Icons.add,
                  color: theme.secondaryText,
                  label: xpdT(
                    dialogContext,
                    'Les dimensions et le poids du lot — sinon nous vous les '
                    'demanderons à l’étape suivante',
                    'The lot’s dimensions and weight — otherwise we will ask '
                    'for them at the next step',
                  ),
                ),
                _GuideBullet(
                  icon: Icons.add,
                  color: theme.secondaryText,
                  label: xpdT(
                    dialogContext,
                    'Vos coordonnées d’acheteur',
                    'Your buyer details',
                  ),
                ),
                const SizedBox(height: 16.0),
                _GuideHeading(
                  label: xpdT(
                    dialogContext,
                    'Format du fichier',
                    'File format',
                  ),
                ),
                _GuideBullet(
                  icon: Icons.picture_as_pdf_outlined,
                  color: theme.primary,
                  label: xpdT(
                    dialogContext,
                    'PDF, ou une photo nette (JPG, PNG, WEBP)',
                    'PDF, or a sharp photo (JPG, PNG, WEBP)',
                  ),
                ),
                _GuideBullet(
                  icon: Icons.straighten,
                  color: theme.primary,
                  label: xpdT(
                    dialogContext,
                    '$maxMb Mo maximum',
                    '$maxMb MB maximum',
                  ),
                ),
                _GuideBullet(
                  icon: Icons.crop_free,
                  color: theme.primary,
                  label: xpdT(
                    dialogContext,
                    'Le document entier doit être visible, en-tête et total '
                    'compris — pas de coin coupé ni de reflet',
                    'The whole document must be visible, header and total '
                    'included — no cropped corner, no glare',
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  xpdT(
                    dialogContext,
                    'Votre bordereau est conforme et refusé quand même ? '
                    'Envoyez-le nous par la page Contact, nous le traiterons à '
                    'la main.',
                    'Slip looks right but still refused? Send it through the '
                    'Contact page and we will handle it by hand.',
                  ),
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
        ),
        actions: [
          DSButton(
            label: xpdT(dialogContext, "J'ai compris", 'Got it'),
            variant: DSButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

class _GuideHeading extends StatelessWidget {
  const _GuideHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label.toUpperCase(),
        style: theme.labelSmall.copyWith(
          color: theme.secondaryText,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 16.0, color: color),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              label,
              style: theme.bodySmall.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Shared chrome
// ========================================

/// A tinted, bordered block in the status colour — the same
/// `bg-{status}/10 border-{status}/20` treatment [DSBadge] uses, at panel size.
class _Frame extends StatelessWidget {
  const _Frame({required this.status, required this.child});

  final DSStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: status.background(context),
          borderRadius: BorderRadius.circular(DSShape.card),
          border: Border.all(color: status.border(context)),
        ),
        child: child,
      );
}

/// The clickable "info label" — underlined, in the primary colour, so it reads
/// as something to press rather than as more of the error text.
class _LinkLabel extends StatelessWidget {
  const _LinkLabel({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.0, color: theme.primary),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: theme.bodySmall.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Formatting
// ========================================

String _formatValue(BuildContext context, BordereauField field, Object? value) {
  if (value == null) return '—';
  switch (field.kind) {
    case BordereauValueKind.euros:
      // The app's own formatter, so a total read off a bordereau is written
      // exactly like the same total on the devis and the payments page.
      final amount = value is num ? value : num.tryParse(value.toString());
      return amount == null
          ? value.toString()
          : formatCents((amount * 100).round());
    case BordereauValueKind.centimetres:
      return '$value cm';
    case BordereauValueKind.kilograms:
      return '$value kg';
    case BordereauValueKind.date:
      final date = DateTime.tryParse(value.toString());
      if (date == null) return value.toString();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    case BordereauValueKind.text:
      return value.toString();
  }
}
