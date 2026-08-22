import 'package:flutter/material.dart';

import '/design_system/ds_l10n.dart';
import '/support_contact.dart';
import 'legal_entity.dart';
import 'legal_page.dart';

/// `/confidentialite` — the RGPD notice for the data this app really handles.
///
/// The inventory is taken from the code, not from a template: the quote form's
/// fields, the bordereau upload, the server-side OpenAI extraction behind the
/// AI estimate, Stripe for card payment, Firebase for accounts and files, and
/// Vercel for hosting. A privacy policy that omits the AI step would be
/// describing a different product.
class ConfidentialiteWidget extends StatelessWidget {
  const ConfidentialiteWidget({super.key});

  static const String routeName = 'Confidentialite';
  static const String routePath = '/confidentialite';

  @override
  Widget build(BuildContext context) {
    String t(String fr, String en) => xpdT(context, fr, en);

    return LegalPageScaffold(
      doc: LegalDoc.confidentialite,
      eyebrow: t('DONNÉES PERSONNELLES', 'PERSONAL DATA'),
      title: t('Politique de confidentialité', 'Privacy policy'),
      lead: t(
        'Ce que nous collectons quand vous demandez un devis, pourquoi, avec '
            'qui nous le partageons, et combien de temps nous le gardons.',
        'What we collect when you request a quote, why, who we share it with, '
            'and how long we keep it.',
      ),
      updated: LegalEntity.privacyUpdated,
      sections: [
        LegalSection(
          heading: t('Responsable de traitement', 'Data controller'),
          paragraphs: [
            t(
              "L'éditeur du site, identifié sur la page des mentions légales, "
                  'est responsable des traitements décrits ici. Pour toute '
                  'question ou pour exercer vos droits : ${SupportContact.email}.',
              'The site publisher, identified on the legal notice page, is the '
                  'controller for the processing described here. For any '
                  'question, or to exercise your rights: '
                  '${SupportContact.email}.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Données collectées', 'Data we collect'),
          paragraphs: [
            t(
              'Nous ne collectons que ce dont la prestation a besoin :',
              'We collect only what the service needs:',
            ),
          ],
          bullets: [
            t(
              'Identité et contact — nom, prénom, adresse e-mail, numéro de '
                  'téléphone.',
              'Identity and contact — first name, surname, email address, '
                  'phone number.',
            ),
            t(
              "Adresses — l'adresse d'enlèvement (maison de ventes ou lieu de "
                  "retrait) et l'adresse de livraison, avec leurs codes "
                  'postaux, villes et éventuels contacts sur place.',
              'Addresses — the pickup address (auction house or collection '
                  'point) and the delivery address, with postcodes, towns and '
                  'any on-site contacts.',
            ),
            t(
              'Bordereau — le fichier PDF ou image que vous déposez, et les '
                  "informations qui en sont extraites : numéro de bordereau, "
                  'date de vente, montant adjugé, maison de ventes.',
              'Sale slip — the PDF or image you upload, and the details read '
                  'from it: slip number, sale date, hammer price, auction '
                  'house.',
            ),
            t(
              'Description du lot — nature, dimensions, poids, fragilité, '
                  'commentaires libres.',
              'Lot description — nature, dimensions, weight, fragility, free '
                  'comments.',
            ),
            t(
              'Compte — identifiants de connexion gérés par notre fournisseur '
                  "d'authentification ; nous ne stockons pas votre mot de "
                  'passe en clair.',
              'Account — sign-in credentials handled by our authentication '
                  'provider; we do not store your password in clear text.',
            ),
            t(
              'Paiement — le statut, le montant et la référence de la '
                  'transaction. Les numéros de carte sont saisis chez Stripe '
                  'et ne nous parviennent jamais.',
              'Payment — the status, amount and reference of the transaction. '
                  'Card numbers are entered on Stripe and never reach us.',
            ),
            t(
              'Échanges — les messages envoyés au chat support et les e-mails '
                  'de suivi de devis.',
              'Correspondence — messages sent to the support chat and quote '
                  'follow-up emails.',
            ),
            t(
              'Données techniques — journaux de connexion, mesures de '
                  'performance de l’application, type d’appareil.',
              'Technical data — connection logs, application performance '
                  'measurements, device type.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Finalités et bases légales', 'Purposes and legal bases'),
          rows: [
            LegalRow(
              t('Établir et exécuter un devis', 'Issue and perform a quote'),
              t(
                'Exécution du contrat ou de mesures précontractuelles '
                    '(art. 6.1.b RGPD).',
                'Performance of the contract or pre-contractual steps '
                    '(art. 6.1.b GDPR).',
              ),
            ),
            LegalRow(
              t('Organiser l’enlèvement et la livraison', 'Arrange pickup and delivery'),
              t(
                'Exécution du contrat (art. 6.1.b RGPD).',
                'Performance of the contract (art. 6.1.b GDPR).',
              ),
            ),
            LegalRow(
              t('Encaisser le paiement', 'Take payment'),
              t(
                'Exécution du contrat et obligation légale comptable '
                    '(art. 6.1.b et 6.1.c RGPD).',
                'Performance of the contract and accounting obligation '
                    '(art. 6.1.b and 6.1.c GDPR).',
              ),
            ),
            LegalRow(
              t('Répondre au support', 'Answer support requests'),
              t(
                'Intérêt légitime à traiter les demandes (art. 6.1.f RGPD).',
                'Legitimate interest in handling requests (art. 6.1.f GDPR).',
              ),
            ),
            LegalRow(
              t('Sécurité et prévention de la fraude', 'Security and fraud prevention'),
              t(
                'Intérêt légitime (art. 6.1.f RGPD).',
                'Legitimate interest (art. 6.1.f GDPR).',
              ),
            ),
            LegalRow(
              t('Obligations comptables et fiscales', 'Accounting and tax obligations'),
              t(
                'Obligation légale (art. 6.1.c RGPD).',
                'Legal obligation (art. 6.1.c GDPR).',
              ),
            ),
          ],
        ),
        LegalSection(
          heading: t(
            'Analyse automatisée du bordereau',
            'Automated reading of the sale slip',
          ),
          paragraphs: [
            t(
              'Pour vous éviter de ressaisir votre bordereau et pour proposer '
                  'une estimation de prix, le document que vous déposez est '
                  'analysé par un service d’intelligence artificielle tiers '
                  '(OpenAI), appelé depuis nos serveurs. Le résultat de cette '
                  'analyse est conservé avec votre devis.',
              'So that you do not have to retype your sale slip, and to '
                  'suggest a price estimate, the document you upload is '
                  'analysed by a third-party artificial-intelligence service '
                  '(OpenAI), called from our servers. The result of that '
                  'analysis is stored with your quote.',
            ),
            t(
              "Cette analyse ne produit aucune décision automatisée ayant un "
                  'effet juridique : le prix final est fixé par un opérateur, '
                  'et vous restez libre de refuser le devis.',
              'This analysis produces no automated decision with legal effect: '
                  'the final price is set by an operator, and you remain free '
                  'to decline the quote.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Destinataires', 'Recipients'),
          paragraphs: [
            t(
              'Vos données ne sont ni vendues ni louées. Elles sont '
                  'communiquées uniquement à :',
              'Your data is neither sold nor rented. It is disclosed only to:',
            ),
          ],
          bullets: [
            t(
              '${LegalEntity.groupSibling}, société du même groupe, qui héberge '
                  'la plateforme sur laquelle les courses sont proposées aux '
                  'transporteurs.',
              '${LegalEntity.groupSibling}, a company in the same group, which '
                  'hosts the platform where jobs are offered to carriers.',
            ),
            t(
              'Le transporteur retenu, qui reçoit ce qui lui est nécessaire '
                  "pour enlever et livrer : adresses, contacts sur place, "
                  'description du lot.',
              'The selected carrier, who receives what is needed to collect '
                  'and deliver: addresses, on-site contacts, lot description.',
            ),
            t(
              'Stripe, pour le paiement par carte.',
              'Stripe, for card payment.',
            ),
            t(
              'Google (Firebase), pour les comptes, le stockage des fichiers '
                  'et la mesure de performance de l’application.',
              'Google (Firebase), for accounts, file storage and application '
                  'performance measurement.',
            ),
            t(
              'OpenAI, pour l’analyse du bordereau décrite ci-dessus.',
              'OpenAI, for the sale-slip analysis described above.',
            ),
            t(
              '${LegalEntity.hostName}, pour l’hébergement du site et de ses '
                  'interfaces de programmation.',
              '${LegalEntity.hostName}, for hosting the site and its '
                  'programming interfaces.',
            ),
            t(
              'Les autorités, lorsque la loi nous y oblige.',
              'The authorities, where the law requires it.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Transferts hors Union européenne', 'Transfers outside the EU'),
          paragraphs: [
            t(
              'Certains prestataires ci-dessus sont établis aux États-Unis. '
                  'Ces transferts sont encadrés par les garanties prévues au '
                  'chapitre V du RGPD — clauses contractuelles types de la '
                  'Commission européenne ou certification au cadre de '
                  'protection des données UE–États-Unis, selon le prestataire. '
                  'Le détail des garanties applicables est communiqué sur '
                  'demande.',
              'Some of the providers above are established in the United '
                  'States. Those transfers are covered by the safeguards in '
                  'chapter V of the GDPR — European Commission standard '
                  'contractual clauses or certification under the EU–US Data '
                  'Privacy Framework, depending on the provider. Details of '
                  'the applicable safeguards are available on request.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Durées de conservation', 'Retention periods'),
          rows: [
            LegalRow(
              t('Devis sans suite', 'Quotes not taken up'),
              t('3 ans à compter du dernier contact.',
                  '3 years from the last contact.'),
            ),
            LegalRow(
              t('Devis exécutés et bordereaux', 'Completed quotes and sale slips'),
              t(
                '5 ans à compter de la livraison, durée de la prescription '
                    'commerciale.',
                '5 years from delivery, the commercial limitation period.',
              ),
            ),
            LegalRow(
              t('Pièces comptables', 'Accounting records'),
              t(
                '10 ans, article L.123-22 du code de commerce.',
                '10 years, article L.123-22 of the French commercial code.',
              ),
            ),
            LegalRow(
              t('Compte client', 'Client account'),
              t(
                "Jusqu'à sa suppression, puis 3 ans d'inactivité.",
                'Until it is deleted, then 3 years of inactivity.',
              ),
            ),
            LegalRow(
              t('Journaux techniques', 'Technical logs'),
              t('12 mois.', '12 months.'),
            ),
          ],
        ),
        LegalSection(
          heading: t('Sécurité', 'Security'),
          paragraphs: [
            t(
              'Les échanges avec le site et ses interfaces sont chiffrés en '
                  "transit. L'accès aux devis est restreint aux opérateurs "
                  'habilités, et les fichiers déposés sont stockés sur un '
                  'espace dont les règles d’accès sont limitées à leur '
                  'propriétaire et à ces opérateurs.',
              'Exchanges with the site and its interfaces are encrypted in '
                  'transit. Access to quotes is restricted to authorised '
                  'operators, and uploaded files are stored in a space whose '
                  'access rules are limited to their owner and those '
                  'operators.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Vos droits', 'Your rights'),
          paragraphs: [
            t(
              'Vous disposez des droits d’accès, de rectification, '
                  'd’effacement, de limitation, d’opposition et de '
                  'portabilité, ainsi que du droit de définir des directives '
                  'sur le sort de vos données après votre décès.',
              'You have rights of access, rectification, erasure, restriction, '
                  'objection and portability, and the right to give directions '
                  'on what happens to your data after your death.',
            ),
            t(
              'Écrivez à ${SupportContact.email}. Nous répondons dans un délai '
                  "d'un mois. Certains éléments ne peuvent pas être effacés "
                  'avant la fin des durées légales de conservation, en '
                  'particulier les pièces comptables.',
              'Write to ${SupportContact.email}. We reply within one month. '
                  'Some items cannot be erased before the end of statutory '
                  'retention periods, in particular accounting records.',
            ),
            t(
              'Vous pouvez également introduire une réclamation auprès de la '
                  'CNIL, 3 place de Fontenoy, 75007 Paris, cnil.fr.',
              'You may also lodge a complaint with the CNIL, 3 place de '
                  'Fontenoy, 75007 Paris, France, cnil.fr.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Cookies et stockage local', 'Cookies and local storage'),
          paragraphs: [
            t(
              'Ce que le site dépose sur votre appareil est décrit en détail '
                  'sur la page cookies, liée en bas de cette page.',
              'What the site places on your device is described in detail on '
                  'the cookies page, linked at the bottom of this page.',
            ),
          ],
        ),
      ],
    );
  }
}
