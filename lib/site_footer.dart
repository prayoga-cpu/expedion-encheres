import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/expedion_api/expedion_config.dart';
import '/design_system/ds_l10n.dart';
import '/design_system/ds_site_footer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// A section of the landing page a link can point at.
///
/// The marketing page's `#anchor`s, named once. The landing page holds a
/// [GlobalKey] per section and scrolls to it in place; every other page names
/// the same section in `/accueil?section=<slug>` and lets the landing page
/// scroll to it on arrival. Both routes go through this enum, so a renamed
/// section cannot leave one of the two spellings behind.
enum XpdSiteSection {
  flow('flow'),
  devis('devis'),
  tarifs('tarifs'),
  couverture('couverture'),
  app('app'),
  faq('faq'),
  contact('contact');

  const XpdSiteSection(this.slug);

  /// What appears in the URL — `/accueil?section=tarifs`.
  final String slug;

  /// Resolves a `?section=` value, or null when it names nothing.
  static XpdSiteSection? fromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    for (final section in XpdSiteSection.values) {
      if (section.slug == slug) return section;
    }
    return null;
  }
}

/// The site footer, wired to this app's routes.
///
/// `ds_site_footer.dart` draws the footer; this decides where each link goes,
/// the same way [XpdPage] wires `ds_app_shell.dart` to the app's routes. It
/// lives here rather than in the design system because it needs the router and
/// the Expeditoo base URL, which the design system deliberately does not know
/// about.
///
/// Every link resolves. The three columns used to be a mix: the Service column
/// only worked because it was built inside the landing page and closed over its
/// scroll keys, the Group column sent two different links to the same page, and
/// the whole Legal column rendered as plain text because the pages did not
/// exist. All eleven now lead somewhere.
class XpdSiteFooter extends StatelessWidget {
  const XpdSiteFooter({super.key, this.onSection, this.currentRouteName});

  /// Supplied by the landing page, which scrolls to the section in place.
  /// Left null everywhere else, which routes to the landing page instead.
  final void Function(XpdSiteSection section)? onSection;

  /// The route this footer is being drawn on, when it is one the footer links
  /// to. Tapping the page you are already reading pushes a second copy of it
  /// onto the navigator, so the reader has to press Back twice to leave — the
  /// same trap [XpdPage] avoids by making the selected header link a no-op.
  final String? currentRouteName;

  @override
  Widget build(BuildContext context) {
    String t(String fr, String en) => xpdT(context, fr, en);

    void goToSection(XpdSiteSection section) {
      final scrollInPlace = onSection;
      if (scrollInPlace != null) {
        scrollInPlace(section);
        return;
      }
      context.pushNamed(
        AccueilWidget.routeName,
        queryParameters: {'section': section.slug},
      );
    }

    Future<void> open(String url) async {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Lien indisponible', 'Link unavailable'))),
      );
    }

    void goToRoute(String routeName) {
      if (routeName == currentRouteName) return;
      context.pushNamed(routeName);
    }

    return XpdFooter(
      tagline: t(
        'Expéditions des ventes aux enchères. Enlèvement, emballage et '
            'livraison de vos lots partout en France métropolitaine.',
        'Auction shipping. Pickup, packing and delivery of your lots across '
            'mainland France.',
      ),
      domain: 'EXPEDION-ENCHERES.COM',
      copyright: '© ${DateTime.now().year} Expedion — '
          '${t('Expéditions des ventes aux enchères', 'Auction shipping')}',
      groupNote: t(
        'Expedion et Expeditoo appartiennent au même groupe',
        // "the same company" said something stronger than the French, and
        // stronger than the mentions légales page, which describes Expeditoo
        // as "société du même groupe". Two brands in one group is the claim.
        'Expedion and Expeditoo belong to the same group',
      ),
      columns: [
        XpdFooterColumn(
          title: 'Service',
          links: [
            XpdFooterLink(
              label: t('Demander un devis', 'Request a quote'),
              onTap: () => goToSection(XpdSiteSection.devis),
            ),
            XpdFooterLink(
              label: t('Tarifs', 'Pricing'),
              onTap: () => goToSection(XpdSiteSection.tarifs),
            ),
            XpdFooterLink(
              label: t('Couverture', 'Coverage'),
              onTap: () => goToSection(XpdSiteSection.couverture),
            ),
            XpdFooterLink(
              label: t('Application mobile', 'Mobile app'),
              onTap: () => goToSection(XpdSiteSection.app),
            ),
          ],
        ),
        XpdFooterColumn(
          title: t('Groupe', 'Group'),
          links: [
            XpdFooterLink(
              label: t('Expeditoo — transporteurs', 'Expeditoo — carriers'),
              onTap: () => open(ExpedionConfig.expeditooWebUrl),
            ),
            XpdFooterLink(
              label: t('Devenir transporteur', 'Become a carrier'),
              // Not the Expeditoo home page the link above already opens —
              // the application form itself.
              onTap: () => open(ExpedionConfig.carrierApplicationUrl),
            ),
            XpdFooterLink(
              label: t('Maisons de ventes', 'Auction houses'),
              onTap: () => goToRoute(ContactWidget.routeName),
            ),
          ],
        ),
        XpdFooterColumn(
          title: t('Légal', 'Legal'),
          links: [
            XpdFooterLink(
              label: t('CGV', 'Terms & Conditions'),
              onTap: () => goToRoute(CgvWidget.routeName),
            ),
            XpdFooterLink(
              label: t('Mentions légales', 'Legal notice'),
              onTap: () => goToRoute(MentionsLegalesWidget.routeName),
            ),
            XpdFooterLink(
              label: t('Politique de confidentialité', 'Privacy policy'),
              onTap: () => goToRoute(ConfidentialiteWidget.routeName),
            ),
            XpdFooterLink(
              label: 'Cookies',
              onTap: () => goToRoute(CookiesWidget.routeName),
            ),
          ],
        ),
      ],
    );
  }
}
