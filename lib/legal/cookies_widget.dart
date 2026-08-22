import 'package:flutter/material.dart';

import '/design_system/ds_l10n.dart';
import '/support_contact.dart';
import 'legal_entity.dart';
import 'legal_page.dart';

/// `/cookies` — what this app actually writes to a visitor's device.
///
/// Which is mostly not cookies: the Flutter client keeps its session token,
/// its locale, its theme and an unsent quote draft in `SharedPreferences`,
/// which is `localStorage` on the web. Naming only "cookies" would understate
/// it, so the page lists the storage keys by name — they are readable in any
/// browser's dev tools anyway, and a reader who wants to clear one should be
/// able to find it.
class CookiesWidget extends StatelessWidget {
  const CookiesWidget({super.key});

  static const String routeName = 'Cookies';
  static const String routePath = '/cookies';

  @override
  Widget build(BuildContext context) {
    String t(String fr, String en) => xpdT(context, fr, en);

    return LegalPageScaffold(
      doc: LegalDoc.cookies,
      eyebrow: t('COOKIES ET STOCKAGE', 'COOKIES AND STORAGE'),
      title: t('Cookies', 'Cookies'),
      lead: t(
        'Ce que ${LegalEntity.domain} conserve sur votre appareil, à quoi cela '
            'sert, et comment vous en débarrasser.',
        'What ${LegalEntity.domain} keeps on your device, what it is for, and '
            'how to get rid of it.',
      ),
      updated: LegalEntity.cookiesUpdated,
      sections: [
        LegalSection(
          heading: t('De quoi parle-t-on', 'What this covers'),
          paragraphs: [
            t(
              'Un cookie est un petit fichier déposé par un site sur votre '
                  'navigateur. Cette application utilise en réalité surtout du '
                  '« stockage local » : le même principe, dans un espace lu '
                  "uniquement par le site qui l'a écrit. Cette page couvre les "
                  'deux.',
              'A cookie is a small file a site places in your browser. This '
                  'application mostly uses "local storage" instead: the same '
                  'idea, in a space only the site that wrote it can read. This '
                  'page covers both.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Ce que nous déposons', 'What we store'),
          paragraphs: [
            t(
              'Rien de ce qui suit ne sert à la publicité, et rien n’est '
                  'partagé avec des régies ou des courtiers en données.',
              'None of the following is used for advertising, and none of it '
                  'is shared with ad networks or data brokers.',
            ),
          ],
          rows: [
            LegalRow(
              '__expeditoo_session_token__',
              t(
                'Votre jeton de session, qui vous maintient connecté d’un '
                    'écran à l’autre. Supprimé à la déconnexion.',
                'Your session token, which keeps you signed in from one screen '
                    'to the next. Removed when you log out.',
              ),
            ),
            LegalRow(
              '__expeditoo_session_user__',
              t(
                'Votre nom et votre adresse e-mail, afin d’afficher votre '
                    'espace sans un aller-retour serveur à chaque ouverture.',
                'Your name and email address, so your account area can be '
                    'shown without a server round-trip on every launch.',
              ),
            ),
            LegalRow(
              'expedion.quoteFormDraft.<compte>',
              t(
                'Le brouillon d’une demande de devis non envoyée, pour que le '
                    'formulaire ne soit pas perdu si vous fermez l’onglet. '
                    'Effacé dès la demande envoyée ou abandonnée, et au plus '
                    'tard 30 jours après son enregistrement.',
                'The draft of an unsent quote request, so the form is not lost '
                    'if you close the tab. Removed as soon as the request is '
                    'sent or abandoned, and at the latest 30 days after it was '
                    'saved.',
              ),
            ),
            LegalRow(
              'expedion.landingQuoteDraft',
              t(
                'Ce que vous avez saisi dans le formulaire de la page '
                    'd’accueil — adresses, e-mail, téléphone, prix '
                    'd’adjudication — le temps d’arriver au formulaire de '
                    'devis. Périmé au bout de 30 minutes, et effacé à la '
                    'déconnexion.',
                'What you typed into the form on the landing page — addresses, '
                    'email, phone, hammer price — for the walk to the quote '
                    'form. Expires after 30 minutes, and is cleared on '
                    'sign-out.',
              ),
            ),
            LegalRow(
              '__locale_key__',
              t(
                'La langue choisie avec le sélecteur FR/EN.',
                'The language chosen with the FR/EN switch.',
              ),
            ),
            LegalRow(
              '__theme_mode__',
              t(
                'Le thème clair ou sombre que vous avez retenu.',
                'The light or dark theme you selected.',
              ),
            ),
            LegalRow(
              t('Stripe', 'Stripe'),
              t(
                'Lors du paiement, Stripe dépose ses propres cookies sur sa '
                    'page de paiement, à des fins de sécurité et de prévention '
                    'de la fraude.',
                'During payment, Stripe sets its own cookies on its checkout '
                    'page, for security and fraud prevention.',
              ),
            ),
            LegalRow(
              t('Google (Firebase)', 'Google (Firebase)'),
              t(
                'Authentification et mesure de performance de l’application : '
                    'temps de chargement et erreurs, agrégés, sans profilage '
                    'publicitaire.',
                'Authentication and application performance measurement: load '
                    'times and errors, aggregated, with no advertising '
                    'profiling.',
              ),
            ),
          ],
        ),
        LegalSection(
          heading: t('Pourquoi il n’y a pas de bandeau', 'Why there is no banner'),
          paragraphs: [
            t(
              'Le consentement préalable est requis pour les traceurs qui ne '
                  'sont pas strictement nécessaires au service — publicité, '
                  'ciblage, mesure d’audience détaillée. Les éléments listés '
                  'ci-dessus relèvent du fonctionnement du service ou de vos '
                  'propres préférences, et entrent dans l’exemption prévue par '
                  "l'article 82 de la loi Informatique et Libertés.",
              'Prior consent is required for trackers that are not strictly '
                  'necessary to the service — advertising, targeting, detailed '
                  'audience measurement. The items listed above serve the '
                  'operation of the service or your own preferences, and fall '
                  'within the exemption in article 82 of the French Data '
                  'Protection Act.',
            ),
            t(
              'Si un traceur soumis à consentement était introduit, un bandeau '
                  'apparaîtrait avant tout dépôt et cette page serait mise à '
                  'jour.',
              'If a tracker requiring consent were introduced, a banner would '
                  'appear before anything was stored and this page would be '
                  'updated.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Combien de temps', 'How long'),
          paragraphs: [
            t(
              'Le jeton de session et le profil mis en cache durent le temps '
                  'de la session et disparaissent à la déconnexion, tout comme '
                  'le brouillon de la page d’accueil — qui se périme de toute '
                  'façon au bout de 30 minutes. Le brouillon du formulaire de '
                  'devis, lui, est remplacé à chaque enregistrement, effacé '
                  'quand la demande part ou que vous l’abandonnez, et expire '
                  'au bout de 30 jours. La langue et le thème restent jusqu’à '
                  'ce que vous les changiez ou que vous vidiez le stockage du '
                  'navigateur.',
              'The session token and cached profile last for the session and '
                  'disappear on sign-out, as does the landing-page draft — '
                  'which expires after 30 minutes in any case. The quote-form '
                  'draft is replaced on each save, removed when the request is '
                  'sent or abandoned, and expires after 30 days. Language and '
                  'theme stay until you change them or clear browser storage.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Comment les supprimer', 'How to remove them'),
          bullets: [
            t(
              'Se déconnecter efface le jeton de session, le profil en cache '
                  'et le brouillon de la page d’accueil. Le brouillon du '
                  'formulaire de devis, lui, est rattaché à votre compte : '
                  'envoyez ou abandonnez la demande pour le supprimer tout de '
                  'suite.',
              'Signing out clears the session token, the cached profile and '
                  'the landing-page draft. The quote-form draft belongs to '
                  'your account: send or abandon the request to remove it '
                  'straight away.',
            ),
            t(
              'Vider les données de site dans votre navigateur supprime '
                  'également la langue et le thème : le site repartira en '
                  'français, en thème système, et vous demandera de vous '
                  'reconnecter.',
              'Clearing site data in your browser also removes the language '
                  'and theme: the site will start again in French, in system '
                  'theme, and ask you to sign in again.',
            ),
            t(
              'Sur mobile, désinstaller l’application supprime tout le '
                  'stockage local associé.',
              'On mobile, uninstalling the application removes all associated '
                  'local storage.',
            ),
            t(
              'La navigation privée conserve ces éléments le temps de la '
                  'fenêtre seulement — un brouillon de devis n’y survivra pas.',
              'Private browsing keeps these items only for the life of the '
                  'window — a quote draft will not survive it.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Questions', 'Questions'),
          paragraphs: [
            t(
              'Pour toute question sur ce qui est stocké, écrivez à '
                  '${SupportContact.email}. Le traitement des données '
                  'personnelles est décrit dans la politique de '
                  'confidentialité, liée ci-dessous.',
              'For any question about what is stored, write to '
                  '${SupportContact.email}. Processing of personal data is '
                  'described in the privacy policy, linked below.',
            ),
          ],
        ),
      ],
    );
  }
}
