/// Who publishes the site, and on what infrastructure.
///
/// French law (LCEN art. 6-III) makes several of these mandatory on the
/// mentions légales page, and none of them are derivable from the codebase:
/// the company's legal form, its share capital, its RCS registration and its
/// registered office are facts only the company holds. Inventing plausible
/// ones would put a fabricated registration number on a public page, so the
/// unknown fields are [String?] and null, and the page renders them as an
/// explicit "à compléter" row rather than quietly omitting the requirement.
///
/// Filling these in is a one-file change with no other edits: every legal page
/// reads from here, and [missingPublisherFields] stops flagging what is set.
class LegalEntity {
  const LegalEntity._();

  /// The brand the site trades under, and its domain.
  static const String tradeName = 'Expedion Enchères';
  static const String domain = 'expedion-encheres.com';
  static const String siteUrl = 'https://expedion-encheres.com';

  /// The sister brand on the carrier side of the same group.
  static const String groupSibling = 'Expeditoo';

  // ---------------------------------------------------------------------
  // Registry facts — set these once, from the Kbis.
  // ---------------------------------------------------------------------

  /// Registered company name, e.g. `EXPEDION SAS`.
  static const String? legalName = null;

  /// Legal form and share capital, e.g. `SAS au capital de 10 000 €`.
  static const String? legalForm = null;

  /// Registered office, on one line.
  static const String? registeredOffice = null;

  /// `RCS Paris 000 000 000` — the registration and the registry that holds it.
  static const String? registration = null;

  /// Intra-community VAT number, e.g. `FR00000000000`.
  static const String? vatNumber = null;

  /// The person responsible for publication — a name, per LCEN art. 6-III-1.
  static const String? publicationDirector = null;

  /// Every mandatory publisher field still unset.
  ///
  /// The mentions légales page lists these so the gap is visible on the page
  /// itself rather than only to whoever reads this file. Returned as
  /// [LegalPublisherField] rather than as strings because the page renders in
  /// two languages: a `List<String>` of French labels read as
  /// "Some registration details are not yet published here (raison sociale,
  /// forme juridique…)" under the EN toggle.
  static List<LegalPublisherField> get missingPublisherFields =>
      <LegalPublisherField>[
        if (legalName == null) LegalPublisherField.legalName,
        if (legalForm == null) LegalPublisherField.legalForm,
        if (registeredOffice == null) LegalPublisherField.registeredOffice,
        if (registration == null) LegalPublisherField.registration,
        if (vatNumber == null) LegalPublisherField.vatNumber,
        if (publicationDirector == null)
          LegalPublisherField.publicationDirector,
      ];

  /// True once the page can stand on its own as a legal notice.
  static bool get isPublisherComplete => missingPublisherFields.isEmpty;

  // ---------------------------------------------------------------------
  // Infrastructure — these are facts about the deployment, so they are known.
  // ---------------------------------------------------------------------

  /// The site and its API endpoints are deployed to Vercel (`vercel.json`,
  /// `api/`), which LCEN requires be named with its address.
  static const String hostName = 'Vercel Inc.';
  static const String hostAddress =
      '340 S Lemon Ave #4133, Walnut, CA 91789, United States';
  static const String hostUrl = 'https://vercel.com';

  /// When each document was last reviewed. Bump the one you edit.
  static const String cgvUpdated = '2026-08-22';
  static const String mentionsUpdated = '2026-08-22';
  static const String privacyUpdated = '2026-08-22';
  static const String cookiesUpdated = '2026-08-22';
}

/// A publisher detail the mentions légales page is required to carry, with
/// its label in both languages.
enum LegalPublisherField {
  legalName('raison sociale', 'registered name'),
  legalForm('forme juridique et capital social', 'legal form and share capital'),
  registeredOffice('siège social', 'registered office'),
  registration('immatriculation RCS', 'company registration'),
  vatNumber('numéro de TVA intracommunautaire', 'VAT number'),
  publicationDirector('directeur de la publication', 'publication director');

  const LegalPublisherField(this.fr, this.en);

  final String fr;
  final String en;
}
