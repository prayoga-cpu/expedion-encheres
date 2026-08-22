import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// How a client reaches a human.
///
/// The details were written out in three places and had already diverged: the
/// landing page carries `01 84 80 12 40`, the old FlutterFlow contact page
/// carries `07 74 31 96 74`, and a form placeholder carries the textbook dummy
/// `06 12 34 56 78`. The landing page pair is the curated one, so it is the
/// pair here — and now there is a single place to correct if that is wrong.
class SupportContact {
  const SupportContact._();

  static const String email = 'contact@expedion-encheres.com';

  /// Display form. [phoneDialable] is what `tel:` needs.
  static const String phone = '01 84 80 12 40';
  static String get phoneDialable => '+33${phone.replaceAll(' ', '').substring(1)}';

  /// Opens the sheet offering every way to get in touch.
  ///
  /// A sheet rather than a straight `tel:` link because the right channel
  /// depends on the client: a phone is useless to someone browsing on a desktop
  /// at midnight, and an email is slow for someone whose lot is being collected
  /// tomorrow. Offering both, plus the chat, lets them pick.
  ///
  /// The third channel used to read "Formulaire de contact — réponse sous 24 h",
  /// which was a promise the form could not keep: it posted into Airtable and
  /// the sender was never told whether anyone had read it. It now names what
  /// the destination actually became — the support thread on `/contact`, which
  /// an operator answers from Expeditoo's own inbox.
  static Future<void> open(
    BuildContext context, {
    String? aboutReference,
  }) {
    return showDSSheet<void>(
      context: context,
      title: xpdT(context, 'Nous contacter', 'Contact us'),
      builder: (sheetContext) {
        final theme = FlutterFlowTheme.of(sheetContext);
        final subject = aboutReference == null
            ? xpdT(context, 'Ma demande de devis', 'My quote request')
            : '${xpdT(context, 'Devis', 'Quote')} $aboutReference';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                aboutReference == null
                    ? xpdT(
                        context,
                        'Notre équipe vous répond du lundi au vendredi, 9h–18h.',
                        'Our team answers Monday to Friday, 9am–6pm.',
                      )
                    : xpdT(
                        context,
                        'Indiquez la référence $aboutReference pour que nous '
                            'retrouvions votre demande tout de suite.',
                        'Mention reference $aboutReference so we can find your '
                            'request straight away.',
                      ),
                style: theme.labelMedium.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 16.0),
              _Channel(
                icon: Icons.call_rounded,
                label: xpdT(context, 'Appeler', 'Call'),
                value: phone,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  launchURL('tel:$phoneDialable');
                },
              ),
              const SizedBox(height: 8.0),
              _Channel(
                icon: Icons.mail_outline_rounded,
                label: xpdT(context, 'Envoyer un e-mail', 'Send an email'),
                value: email,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  launchURL(
                    'mailto:$email?subject=${Uri.encodeComponent(subject)}',
                  );
                },
              ),
              const SizedBox(height: 8.0),
              _Channel(
                // Same headset the contact page and Expeditoo's admin console
                // use, so the three views of one inbox look like one thing.
                icon: Icons.headset_mic_outlined,
                label: xpdT(context, 'Chat support', 'Support chat'),
                value: xpdT(
                  context,
                  'Discutez avec un conseiller',
                  'Chat with an advisor',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  // Carry the reference through. The sheet has just told the
                  // client to "mention reference X" — sending them to a blank
                  // composer and making them do it by hand is the instruction
                  // and the tooling disagreeing.
                  context.pushNamed(
                    ContactWidget.routeName,
                    queryParameters: {
                      if (aboutReference != null)
                        'numDevis':
                            serializeParam(aboutReference, ParamType.String)!,
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Channel extends StatelessWidget {
  const _Channel({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return DSCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: theme.primary),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: theme.labelSmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20.0,
            color: theme.secondaryText,
          ),
        ],
      ),
    );
  }
}
