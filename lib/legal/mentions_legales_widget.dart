import 'package:flutter/material.dart';

import '/design_system/ds_l10n.dart';
import '/support_contact.dart';
import 'legal_entity.dart';
import 'legal_page.dart';

/// `/mentions-legales` — the publisher and host identification the LCEN
/// (loi n° 2004-575, art. 6-III) requires of every site open to the public.
///
/// The registry facts it must carry are not in this repository, so they live
/// as nullable constants in [LegalEntity] and render as visible "à compléter"
/// rows. That is deliberate: a legal notice with an invented SIREN on it is
/// worse than one that says which line is still missing.
class MentionsLegalesWidget extends StatelessWidget {
  const MentionsLegalesWidget({super.key});

  static const String routeName = 'MentionsLegales';
  static const String routePath = '/mentions-legales';

  @override
  Widget build(BuildContext context) {
    String t(String fr, String en) => xpdT(context, fr, en);
    final missing = LegalEntity.missingPublisherFields;

    return LegalPageScaffold(
      doc: LegalDoc.mentions,
      eyebrow: t('INFORMATIONS LÉGALES', 'LEGAL INFORMATION'),
      title: t('Mentions légales', 'Legal notice'),
      lead: t(
        "Qui édite ${LegalEntity.domain}, qui l'héberge, et comment nous "
            'joindre.',
        'Who publishes ${LegalEntity.domain}, who hosts it, and how to reach '
            'us.',
      ),
      updated: LegalEntity.mentionsUpdated,
      notice: missing.isEmpty
          ? null
          : t(
              "Certaines informations d'immatriculation ne sont pas encore "
                  'publiées ici '
                  '(${missing.map((f) => f.fr).join(', ')}). Elles sont '
                  "communiquées sur simple demande à ${SupportContact.email} "
                  'et seront ajoutées à cette page.',
              'Some registration details are not yet published here '
                  '(${missing.map((f) => f.en).join(', ')}). They are '
                  'available on request at ${SupportContact.email} and will be '
                  'added to this page.',
            ),
      sections: [
        LegalSection(
          heading: t('Éditeur du site', 'Site publisher'),
          paragraphs: [
            t(
              'Le site ${LegalEntity.siteUrl} et le service '
                  "${LegalEntity.tradeName} sont édités par :",
              'The site ${LegalEntity.siteUrl} and the '
                  '${LegalEntity.tradeName} service are published by:',
            ),
          ],
          rows: [
            LegalRow(
              t('Raison sociale', 'Registered name'),
              LegalEntity.legalName,
            ),
            LegalRow(
              t('Forme juridique et capital', 'Legal form and capital'),
              LegalEntity.legalForm,
            ),
            LegalRow(
              t('Siège social', 'Registered office'),
              LegalEntity.registeredOffice,
            ),
            LegalRow(
              t('Immatriculation', 'Registration'),
              LegalEntity.registration,
            ),
            LegalRow(
              t('TVA intracommunautaire', 'VAT number'),
              LegalEntity.vatNumber,
            ),
            LegalRow(
              t('Directeur de la publication', 'Publication director'),
              LegalEntity.publicationDirector,
            ),
            LegalRow(t('Adresse e-mail', 'Email'), SupportContact.email),
            LegalRow(t('Téléphone', 'Telephone'), SupportContact.phone),
          ],
        ),
        LegalSection(
          heading: t('Hébergeur', 'Hosting provider'),
          paragraphs: [
            t(
              "Le site et ses interfaces de programmation sont hébergés par "
                  '${LegalEntity.hostName}, ${LegalEntity.hostAddress} '
                  '(${LegalEntity.hostUrl}).',
              'The site and its programming interfaces are hosted by '
                  '${LegalEntity.hostName}, ${LegalEntity.hostAddress} '
                  '(${LegalEntity.hostUrl}).',
            ),
            t(
              "Les comptes, les fichiers déposés et les données de devis sont "
                  'traités par les prestataires listés dans la politique de '
                  'confidentialité.',
              'Accounts, uploaded files and quote data are processed by the '
                  'providers listed in the privacy policy.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Activité', 'Activity'),
          paragraphs: [
            t(
              '${LegalEntity.tradeName} organise l’enlèvement, l’emballage et '
                  'la livraison des lots achetés en ventes aux enchères, en '
                  'France métropolitaine. Le transport est exécuté par des '
                  'transporteurs professionnels référencés via '
                  '${LegalEntity.groupSibling}, société du même groupe.',
              '${LegalEntity.tradeName} arranges pickup, packing and delivery '
                  'of lots bought at auction, across mainland France. Carriage '
                  'is performed by professional carriers sourced through '
                  '${LegalEntity.groupSibling}, a company in the same group.',
            ),
            t(
              'Les conditions commerciales applicables à ces prestations sont '
                  'détaillées dans les conditions générales de vente.',
              'The commercial terms for those services are set out in the '
                  'terms and conditions of sale.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Propriété intellectuelle', 'Intellectual property'),
          paragraphs: [
            t(
              'La structure du site, ses textes, sa charte graphique, ses '
                  'logos et ses illustrations sont protégés. Toute '
                  'reproduction ou représentation, totale ou partielle, sans '
                  'autorisation écrite préalable est interdite.',
              'The structure of the site, its texts, visual identity, logos '
                  'and illustrations are protected. Any reproduction or '
                  'representation, whole or partial, without prior written '
                  'permission is prohibited.',
            ),
            t(
              'Les marques ${LegalEntity.tradeName} et '
                  '${LegalEntity.groupSibling}, ainsi que leurs logos, ne '
                  'peuvent être utilisés sans accord préalable.',
              'The ${LegalEntity.tradeName} and ${LegalEntity.groupSibling} '
                  'marks, and their logos, may not be used without prior '
                  'agreement.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Responsabilité', 'Liability'),
          paragraphs: [
            t(
              'Les informations publiées sur le site sont fournies à titre '
                  'indicatif et peuvent évoluer. Les prix affichés avant '
                  'devis, notamment les fourchettes tarifaires, ne valent pas '
                  "offre : seul le devis chiffré et accepté engage les "
                  'parties.',
              'The information published on the site is indicative and may '
                  'change. Prices shown before a quote, in particular price '
                  'ranges, are not an offer: only a priced and accepted quote '
                  'binds the parties.',
            ),
            t(
              'Le site peut renvoyer vers des sites tiers, notamment '
                  '${LegalEntity.groupSibling}. Ces sites ont leurs propres '
                  'conditions et nous ne répondons pas de leur contenu.',
              'The site may link to third-party sites, in particular '
                  '${LegalEntity.groupSibling}. Those sites have their own '
                  'terms and we are not responsible for their content.',
            ),
          ],
        ),
        LegalSection(
          heading: t(
            'Données personnelles et cookies',
            'Personal data and cookies',
          ),
          paragraphs: [
            t(
              "Le traitement des données personnelles est décrit dans la "
                  'politique de confidentialité, et le stockage déposé sur '
                  'votre appareil dans la page cookies. Les deux sont liées en '
                  'bas de cette page.',
              'Processing of personal data is described in the privacy policy, '
                  'and the storage placed on your device in the cookies page. '
                  'Both are linked at the bottom of this page.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Nous contacter', 'Contact us'),
          paragraphs: [
            t(
              'Pour toute question sur le site ou le service : '
                  '${SupportContact.email}, ou ${SupportContact.phone} du '
                  'lundi au vendredi de 9h à 18h.',
              'For any question about the site or the service: '
                  '${SupportContact.email}, or ${SupportContact.phone} Monday '
                  'to Friday, 9am to 6pm.',
            ),
          ],
        ),
      ],
    );
  }
}
