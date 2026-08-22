import 'package:flutter/material.dart';

import '/design_system/ds_l10n.dart';
import '/support_contact.dart';
import 'legal_entity.dart';
import 'legal_page.dart';

/// `/cgv` — the conditions the quote flow actually implements.
///
/// Written against this app rather than from a template: the two insurance
/// levels are the AD valorem / Standard pair the validation screen offers, the
/// bordereau acquitté is the document the pickup genuinely depends on, and the
/// payment step is the Stripe checkout the confirmation screen opens. A term
/// the product does not honour is worse than no term at all.
class CgvWidget extends StatelessWidget {
  const CgvWidget({super.key});

  static const String routeName = 'CGV';
  static const String routePath = '/cgv';

  @override
  Widget build(BuildContext context) {
    String t(String fr, String en) => xpdT(context, fr, en);

    return LegalPageScaffold(
      doc: LegalDoc.cgv,
      eyebrow: t('CONDITIONS GÉNÉRALES', 'TERMS AND CONDITIONS'),
      title: t('Conditions générales de vente', 'Terms and conditions of sale'),
      lead: t(
        "Ce qui s'applique quand vous nous confiez un lot : le devis, le prix, "
            "l'enlèvement, la livraison et les recours.",
        'What applies when you entrust a lot to us: the quote, the price, the '
            'pickup, the delivery and your remedies.',
      ),
      updated: LegalEntity.cgvUpdated,
      sections: [
        LegalSection(
          heading: t('Objet', 'Purpose'),
          paragraphs: [
            t(
              'Les présentes conditions régissent les prestations '
                  "d'organisation de transport proposées par "
                  '${LegalEntity.tradeName} sur ${LegalEntity.domain} et dans '
                  "son application : l'enlèvement d'un lot acheté en vente aux "
                  'enchères, son emballage lorsqu’il est demandé, et sa '
                  'livraison à l’adresse indiquée.',
              'These terms govern the transport-organisation services offered '
                  'by ${LegalEntity.tradeName} on ${LegalEntity.domain} and in '
                  'its application: collecting a lot bought at auction, '
                  'packing it where requested, and delivering it to the '
                  'address given.',
            ),
            t(
              'Passer une demande de devis vaut acceptation des présentes. '
                  'Elles prévalent sur tout autre document, sauf accord écrit '
                  'contraire.',
              'Submitting a quote request constitutes acceptance of these '
                  'terms. They prevail over any other document, save written '
                  'agreement to the contrary.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Définitions', 'Definitions'),
          rows: [
            LegalRow(
              t('Client', 'Client'),
              t(
                'La personne qui demande la prestation, particulier ou '
                    'professionnel.',
                'The person requesting the service, consumer or business.',
              ),
            ),
            LegalRow(
              t('Lot', 'Lot'),
              t(
                "L'objet ou l'ensemble d'objets adjugés à enlever.",
                'The item or set of items awarded at auction to be collected.',
              ),
            ),
            LegalRow(
              t('Bordereau', 'Sale slip'),
              t(
                "Le bordereau d'adjudication émis par la maison de ventes, "
                    'qui identifie le lot, son prix et le vendeur.',
                'The sale slip issued by the auction house identifying the '
                    'lot, its price and the seller.',
              ),
            ),
            LegalRow(
              t('Bordereau acquitté', 'Paid sale slip'),
              t(
                'Le même document une fois le lot payé à la maison de ventes, '
                    "seule pièce qui autorise sa remise au transporteur.",
                'The same document once the lot has been paid for to the '
                    'auction house — the only document that authorises its '
                    'release to the carrier.',
              ),
            ),
            LegalRow(
              t('Devis', 'Quote'),
              t(
                "L'offre chiffrée que nous émettons pour une demande donnée.",
                'The priced offer we issue for a given request.',
              ),
            ),
            LegalRow(
              t('Transporteur', 'Carrier'),
              t(
                "Le professionnel qui exécute l'enlèvement et la livraison, "
                    'référencé via ${LegalEntity.groupSibling}.',
                'The professional performing the pickup and delivery, sourced '
                    'through ${LegalEntity.groupSibling}.',
              ),
            ),
          ],
        ),
        LegalSection(
          heading: t('Demande de devis', 'Quote request'),
          paragraphs: [
            t(
              'La demande se fait en ligne. Elle comporte les adresses '
                  "d'enlèvement et de livraison, la description du lot et, "
                  'lorsque la vente a déjà eu lieu, le bordereau. Les '
                  'informations transmises engagent le Client : des '
                  'dimensions, un poids ou une accessibilité inexacts peuvent '
                  'entraîner un devis rectificatif avant enlèvement.',
              'Requests are made online. They include the pickup and delivery '
                  'addresses, a description of the lot and, where the sale has '
                  'already taken place, the sale slip. The information '
                  'supplied binds the Client: inaccurate dimensions, weight or '
                  'access may lead to a revised quote before pickup.',
            ),
            t(
              'Nous répondons sous 48 heures ouvrées. Sauf mention contraire, '
                  'un devis est valable 15 jours à compter de son émission.',
              'We reply within 48 business hours. Unless stated otherwise, a '
                  'quote is valid for 15 days from issue.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Formation du contrat', 'Formation of the contract'),
          paragraphs: [
            t(
              "Le contrat est formé lorsque le Client accepte le devis et "
                  'règle le prix. Tant que le paiement n’est pas encaissé, '
                  "aucun enlèvement n'est programmé et aucune date n'est "
                  'réservée.',
              'The contract is formed when the Client accepts the quote and '
                  'pays the price. Until payment is received, no pickup is '
                  'scheduled and no date is reserved.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Prix et assurance', 'Price and insurance'),
          paragraphs: [
            t(
              'Les prix sont exprimés en euros toutes taxes comprises. Le '
                  "devis indique ce qu'il couvre : l'enlèvement, la "
                  "manutention, l'emballage lorsqu'il est retenu, le transport "
                  'et la livraison.',
              'Prices are in euros including tax. The quote states what it '
                  'covers: pickup, handling, packing where selected, carriage '
                  'and delivery.',
            ),
            t(
              'Deux niveaux de couverture sont proposés au moment de valider '
                  'le devis :',
              'Two levels of cover are offered when the quote is confirmed:',
            ),
          ],
          bullets: [
            t(
              'Assurance Standard — indemnisation forfaitaire, dans les '
                  'limites légales applicables au transport.',
              'Standard insurance — flat-rate compensation, within the legal '
                  'limits applicable to carriage.',
            ),
            t(
              'Assurance AD valorem — indemnisation à hauteur de la valeur '
                  'déclarée du lot, telle que retenue au devis.',
              'AD valorem insurance — compensation up to the declared value of '
                  'the lot, as recorded on the quote.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Paiement', 'Payment'),
          paragraphs: [
            t(
              'Le paiement s’effectue en ligne par carte bancaire, via notre '
                  'prestataire Stripe. Les données de carte sont saisies chez '
                  "lui et ne transitent pas par nos serveurs — nous n'en "
                  'conservons aucune.',
              'Payment is made online by card through our provider Stripe. '
                  'Card details are entered on their side and do not pass '
                  'through our servers — we store none of them.',
            ),
            t(
              'Le règlement du lot à la maison de ventes est distinct et reste '
                  'à la charge du Client : nous ne réglons pas l’adjudication.',
              'Payment for the lot to the auction house is separate and '
                  'remains the Client’s responsibility: we do not settle the '
                  'hammer price.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Enlèvement', 'Pickup'),
          paragraphs: [
            t(
              "L'enlèvement suppose que le lot soit payé et libéré par la "
                  'maison de ventes. Le bordereau acquitté doit nous être '
                  'transmis avant la date d’enlèvement ; à défaut, le '
                  'transporteur peut se voir refuser la remise du lot et le '
                  'déplacement reste dû.',
              'Pickup assumes the lot has been paid for and released by the '
                  'auction house. The paid sale slip must reach us before the '
                  'pickup date; failing that, the carrier may be refused the '
                  'lot and the journey remains payable.',
            ),
            t(
              'Le Client s’assure que le lot est accessible aux jours et '
                  'heures convenus et signale toute contrainte particulière : '
                  'étage sans ascenseur, accès poids lourds, créneau imposé '
                  'par la maison de ventes.',
              'The Client ensures the lot is accessible on the agreed days and '
                  'times and reports any particular constraint: floor without '
                  'a lift, heavy-goods access, a slot imposed by the auction '
                  'house.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Emballage et objets exclus', 'Packing and excluded items'),
          paragraphs: [
            t(
              "L'emballage, lorsqu'il est retenu au devis, est réalisé par le "
                  'transporteur avec des matériaux adaptés à la nature du lot. '
                  "Lorsque le Client emballe lui-même, la protection relève de "
                  'sa responsabilité.',
              'Packing, where included in the quote, is done by the carrier '
                  'with materials suited to the lot. Where the Client packs '
                  'the lot themselves, protection is their responsibility.',
            ),
            t(
              'Sont exclus du transport les biens dont la circulation est '
                  'réglementée ou interdite, les matières dangereuses, les '
                  'espèces et valeurs, ainsi que les lots dont la nature n’a '
                  'pas été déclarée lors de la demande.',
              'Excluded from carriage are goods whose movement is regulated or '
                  'prohibited, dangerous materials, cash and valuables, and '
                  'lots whose nature was not declared in the request.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Délais', 'Timescales'),
          paragraphs: [
            t(
              'Les délais annoncés sont donnés à titre indicatif et courent à '
                  'compter de la mise à disposition effective du lot. Un '
                  'retard n’ouvre pas droit à annulation ni à indemnité, sauf '
                  'délai expressément garanti par écrit.',
              'Stated timescales are indicative and run from the date the lot '
                  'is actually made available. A delay does not give rise to '
                  'cancellation or compensation, unless a timescale was '
                  'expressly guaranteed in writing.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Livraison et réserves', 'Delivery and reservations'),
          paragraphs: [
            t(
              'La livraison est faite à l’adresse indiquée, au destinataire ou '
                  'à toute personne présente sur place. Le Client vérifie '
                  "l'état du lot à la réception.",
              'Delivery is made to the address given, to the recipient or any '
                  'person present. The Client checks the condition of the lot '
                  'on receipt.',
            ),
            t(
              'En cas d’avarie ou de perte partielle, des réserves précises et '
                  'motivées doivent être portées sur le document de livraison, '
                  'puis confirmées au transporteur et à nous-mêmes par écrit '
                  'dans les trois jours suivant la réception, conformément à '
                  "l'article L.133-3 du code de commerce. Des réserves "
                  'générales du type « sous réserve de déballage » ne sont pas '
                  'opposables.',
              'In the event of damage or partial loss, precise and reasoned '
                  'reservations must be recorded on the delivery document, '
                  'then confirmed in writing to the carrier and to us within '
                  'three days of receipt, in accordance with article L.133-3 '
                  'of the French commercial code. General reservations such as '
                  '"subject to unpacking" are not enforceable.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Responsabilité', 'Liability'),
          paragraphs: [
            t(
              'Notre responsabilité au titre des dommages au lot est engagée '
                  'dans les limites de la couverture retenue au devis. Elle ne '
                  's’étend pas aux dommages indirects, ni aux vices propres du '
                  'lot, à sa fragilité non déclarée ou à un emballage réalisé '
                  'par le Client.',
              'Our liability for damage to the lot is engaged within the '
                  'limits of the cover selected on the quote. It does not '
                  'extend to indirect loss, inherent defects of the lot, '
                  'undeclared fragility, or packing carried out by the Client.',
            ),
            t(
              'Aucune stipulation des présentes ne limite les droits que le '
                  'Client consommateur tient des dispositions impératives du '
                  'droit français.',
              'Nothing in these terms limits the rights a consumer Client '
                  'holds under mandatory provisions of French law.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Annulation et rétractation', 'Cancellation and withdrawal'),
          paragraphs: [
            t(
              'Le Client peut annuler sans frais tant que le transporteur ne '
                  's’est pas déplacé. Passé ce point, les frais réellement '
                  'engagés restent dus.',
              'The Client may cancel free of charge as long as the carrier has '
                  'not travelled. After that, costs actually incurred remain '
                  'payable.',
            ),
            t(
              "Le droit de rétractation de quatorze jours prévu à l'article "
                  'L.221-18 du code de la consommation ne s’applique pas aux '
                  'prestations de transport de biens fournies à une date ou '
                  'selon une périodicité déterminée (article L.221-28, 12°). '
                  'Lorsque la prestation n’est rattachée à aucune date '
                  'convenue, le droit de rétractation s’applique dans les '
                  'conditions de droit commun.',
              'The fourteen-day right of withdrawal under article L.221-18 of '
                  'the French consumer code does not apply to services for the '
                  'carriage of goods supplied on a specific date or period '
                  '(article L.221-28, 12°). Where the service is not tied to '
                  'an agreed date, the right of withdrawal applies under the '
                  'ordinary rules.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Réclamations et médiation', 'Complaints and mediation'),
          paragraphs: [
            t(
              'Toute réclamation est adressée à ${SupportContact.email} ou au '
                  '${SupportContact.phone}, en indiquant la référence du '
                  'devis. Nous accusons réception et répondons sous quinze '
                  'jours.',
              'Any complaint should be sent to ${SupportContact.email} or '
                  'called in on ${SupportContact.phone}, quoting the quote '
                  'reference. We acknowledge receipt and reply within fifteen '
                  'days.',
            ),
            t(
              "À défaut de solution, le Client consommateur peut recourir "
                  'gratuitement à un médiateur de la consommation. Les '
                  'coordonnées du médiateur compétent sont communiquées sur '
                  'demande à ${SupportContact.email}.',
              'Failing a resolution, a consumer Client may refer the matter '
                  'free of charge to a consumer mediator. The competent '
                  "mediator's details are provided on request at "
                  '${SupportContact.email}.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Données personnelles', 'Personal data'),
          paragraphs: [
            t(
              'Les données transmises lors d’une demande de devis sont '
                  'traitées pour exécuter la prestation, dans les conditions '
                  'décrites par la politique de confidentialité, liée en bas '
                  'de cette page.',
              'Data supplied with a quote request is processed to perform the '
                  'service, on the terms described in the privacy policy, '
                  'linked at the bottom of this page.',
            ),
          ],
        ),
        LegalSection(
          heading: t('Droit applicable', 'Governing law'),
          paragraphs: [
            t(
              'Les présentes sont soumises au droit français. À défaut '
                  'd’accord amiable, le litige est porté devant la juridiction '
                  'compétente selon les règles de droit commun ; le Client '
                  'consommateur peut saisir la juridiction de son lieu de '
                  'résidence.',
              'These terms are governed by French law. Failing an amicable '
                  'settlement, disputes are brought before the court having '
                  'jurisdiction under the ordinary rules; a consumer Client '
                  'may bring proceedings where they reside.',
            ),
          ],
        ),
      ],
    );
  }
}
