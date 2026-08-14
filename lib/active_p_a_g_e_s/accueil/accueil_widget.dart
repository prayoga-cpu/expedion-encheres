import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/quote_draft.dart';
import '/design_system/ds_logo.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/design_system/ds_site_footer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import '/main.dart';
import 'accueil_model.dart';
export 'accueil_model.dart';

/// The Expedion Enchères landing page.
///
/// A section-for-section port of the marketing page: the Expeditoo
/// announcement strip, a sticky translucent header, the hero and its express
/// quote card, the group explainer, the routing flow, the full quote form,
/// pricing, coverage, the handling promises, the mobile app, partners,
/// testimonials, the FAQ, the closing call to action and the footer.
///
/// Two things the HTML does with browser primitives are done here in Dart: the
/// `#anchor` links scroll with [Scrollable.ensureVisible] against a per-section
/// [GlobalKey], and the FR/EN switch drives the app's own [Locale] rather than
/// swapping `data-en` attributes, so the rest of the app follows the choice
/// made here.
class AccueilWidget extends StatefulWidget {
  const AccueilWidget({super.key});

  static const String routeName = 'Accueil';
  static const String routePath = '/accueil';

  @override
  State<AccueilWidget> createState() => _AccueilWidgetState();
}

class _AccueilWidgetState extends State<AccueilWidget> {
  late AccueilModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  // Anchor targets for the header, footer and in-page links.
  final _flowKey = GlobalKey();
  final _devisKey = GlobalKey();
  final _tarifsKey = GlobalKey();
  final _couvertureKey = GlobalKey();
  final _appKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _contactKey = GlobalKey();

  // Hero "Devis express" card.
  final _expressPickup = TextEditingController();
  final _expressDelivery = TextEditingController();
  SelectedFile? _expressFile;

  // The full "Demander un devis" form.
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _lotCount = TextEditingController();
  final _hammerPrice = TextEditingController();
  final _deadline = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  SelectedFile? _bordereau;
  late String _lotType = _lotTypesFr.first;

  /// Which FAQ rows are open. The design ships the first one expanded.
  final Set<int> _openFaq = {0};

  static const _expeditooUrl = 'https://expeditoo-rho.vercel.app/';
  static const _contactEmail = 'contact@expedion-encheres.com';
  static const _phoneNumber = '01 84 80 12 40';

  static const _lotTypesFr = [
    'Tableau, objet, moins de 20 kg',
    'Mobilier, 20 à 80 kg',
    'Volumineux ou fragile, plus de 80 kg',
    'Je ne sais pas encore',
  ];
  static const _lotTypesEn = [
    'Painting, object, under 20 kg',
    'Furniture, 20 to 80 kg',
    'Bulky or fragile, over 80 kg',
    "I don't know yet",
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccueilModel());
  }

  @override
  void dispose() {
    _model.dispose();
    _scrollController.dispose();
    for (final controller in [
      _expressPickup,
      _expressDelivery,
      _pickup,
      _delivery,
      _lotCount,
      _hammerPrice,
      _deadline,
      _email,
      _phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // ========================================
  // Language, navigation and submission
  // ========================================

  bool get _isEnglish =>
      FFLocalizations.of(context).languageCode.startsWith('en');

  /// The markup carries French as its text and English in `data-en`; this
  /// picks between the pair the same way the page's `applyLang` does.
  String _t(String fr, String en) => _isEnglish ? en : fr;

  void _setLanguage(String code) {
    if (code == (_isEnglish ? 'en' : 'fr')) return;
    // The dropdown's selection is one of the French strings until the locale
    // flips; carry the index across so the choice survives the switch.
    final index = _lotTypesFr.contains(_lotType)
        ? _lotTypesFr.indexOf(_lotType)
        : _lotTypesEn.indexOf(_lotType);
    MyApp.of(context).setLocale(code);
    if (index >= 0) {
      setState(() {
        _lotType = code == 'en' ? _lotTypesEn[index] : _lotTypesFr[index];
      });
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      // Clear the pinned header, which the scroll view does not account for.
      alignment: 0.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  Future<void> _openExpeditoo() => _open(_expeditooUrl);
  Future<void> _mailContact() => _open('mailto:$_contactEmail');

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Lien indisponible', 'Link unavailable'))),
      );
    }
  }

  Future<void> _pickFile(void Function(SelectedFile) onPicked) async {
    final file = await selectFile(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null || !mounted) return;
    setState(() => onPicked(file));
  }

  /// Signed-out visitors log in first, which is what the page did before.
  void _goToQuoteFlow() => context.pushNamed(
        loggedIn ? ChoixDevisWidget.routeName : SeConnecterWidget.routeName,
      );

  /// The hero card carries the two fields it has; the form below carries all
  /// of them. Either way the values are parked for the devis form to seed from.
  void _submitExpress() {
    QuoteDraft.stage(QuoteDraft(
      pickup: _expressPickup.text.trim(),
      delivery: _expressDelivery.text.trim(),
      bordereau: _expressFile,
    ));
    _goToQuoteFlow();
  }

  void _submitFull() {
    QuoteDraft.stage(QuoteDraft(
      pickup: _pickup.text.trim(),
      delivery: _delivery.text.trim(),
      lotCount: _lotCount.text.trim(),
      lotType: _lotType,
      hammerPrice: _hammerPrice.text.trim(),
      deadline: _deadline.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      bordereau: _bordereau,
    ));
    _goToQuoteFlow();
  }

  // ========================================
  // Page
  // ========================================

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final palette = XpdPalette.of(context);
    final themeMode = MyApp.of(context).themeMode;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: palette.bg,
      endDrawer: _MobileMenu(
        onLink: (key) {
          Navigator.of(context).pop();
          _scrollTo(key);
        },
        flowKey: _flowKey,
        tarifsKey: _tarifsKey,
        couvertureKey: _couvertureKey,
        faqKey: _faqKey,
        devisKey: _devisKey,
        languageCode: _isEnglish ? 'en' : 'fr',
        onLanguageChanged: _setLanguage,
        onLogin: () {
          Navigator.of(context).pop();
          context.pushNamed(loggedIn
              ? EspacePersonnelWidget.routeName
              : SeConnecterWidget.routeName);
        },
        loggedIn: loggedIn,
        t: _t,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // The announcement strip scrolls away; the header below it stays.
          SliverToBoxAdapter(
            child: XpdAnnouncementBar(
              message: _t(
                "Transporteur ? Les courses du groupe s'enchèrent sur Expeditoo, notre plateforme 100 % web.",
                "Carrier? The group's jobs are bid on Expeditoo, our 100% web platform.",
              ),
              linkLabel: _t('Ouvrir Expeditoo →', 'Open Expeditoo →'),
              onLinkTap: _openExpeditoo,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeader(
              child: XpdHeader(
                languageCode: _isEnglish ? 'en' : 'fr',
                onLanguageChanged: _setLanguage,
                themeMode: themeMode,
                onThemeChanged: (mode) {
                  MyApp.of(context).setThemeMode(mode);
                  // Light → system on a light platform changes no brightness,
                  // so nothing above would rebuild the tick.
                  safeSetState(() {});
                },
                onLogoTap: () => _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOut,
                ),
                onMenuTap: () => scaffoldKey.currentState?.openEndDrawer(),
                links: [
                  XpdNavItem(
                    label: _t('Comment ça marche', 'How it works'),
                    onTap: () => _scrollTo(_flowKey),
                  ),
                  XpdNavItem(
                    label: _t('Tarifs', 'Pricing'),
                    onTap: () => _scrollTo(_tarifsKey),
                  ),
                  XpdNavItem(
                    label: _t('Couverture', 'Coverage'),
                    onTap: () => _scrollTo(_couvertureKey),
                  ),
                  XpdNavItem(
                    label: 'FAQ',
                    onTap: () => _scrollTo(_faqKey),
                  ),
                ],
                trailing: [
                  _HeaderTextAction(
                    label: loggedIn
                        ? _t('Espace personnel', 'My account')
                        : _t('Connexion', 'Log in'),
                    onTap: () => context.pushNamed(loggedIn
                        ? EspacePersonnelWidget.routeName
                        : SeConnecterWidget.routeName),
                  ),
                  XpdButton(
                    label: _t('Demander un devis', 'Request a quote'),
                    fontSize: 14.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 9.0,
                    ),
                    radius: 10.0,
                    onPressed: () => _scrollTo(_devisKey),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _hero(),
              _stats(),
              _group(),
              _flow(),
              _quoteForm(),
              _pricing(),
              _coverage(),
              _handling(),
              _mobileApp(),
              _partners(),
              _testimonials(),
              _faq(),
              _closing(),
              _footer(),
            ]),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Hero
  // ========================================

  Widget _hero() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdChip(
          label: _t(
            'Enlèvement et livraison partout en France',
            'Pickup and delivery across France',
          ),
          dotColor: palette.green,
        ),
        const SizedBox(height: 24.0),
        _heroHeadline(),
        const SizedBox(height: 24.0),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520.0),
          child: Text(
            _t(
              "Expedion enlève votre achat à la maison de ventes, l'emballe et le livre chez vous. Un prix fixe, un seul suivi, zéro coup de fil.",
              'Expedion collects your purchase from the auction house, packs it and delivers it to your door. One fixed price, one tracking feed, zero phone calls.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 17.5,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        _heroSteps(),
        const SizedBox(height: 24.0),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            XpdButton(
              label: _t('Demander un devis', 'Request a quote'),
              onPressed: () => _scrollTo(_devisKey),
            ),
            XpdButton(
              label: _t('Comment ça marche', 'How it works'),
              variant: XpdButtonVariant.outline,
              onPressed: () => _scrollTo(_flowKey),
            ),
          ],
        ),
        const SizedBox(height: 26.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const XpdStars(),
            const SizedBox(width: 12.0),
            Flexible(
              child: Text(
                _t(
                  'Maisons de ventes et acheteurs nous font confiance',
                  'Trusted by auction houses and buyers',
                ),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14.0,
                  color: palette.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final content = stack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 40.0), _expressCard()],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // `grid-template-columns:minmax(0,1.08fr) minmax(320px,0.92fr)`
              Expanded(flex: 108, child: copy),
              const SizedBox(width: 56.0),
              Expanded(
                flex: 92,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 320.0),
                  child: _expressCard(),
                ),
              ),
            ],
          );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // The blue radial glow behind the hero.
        Positioned(
          top: -260.0,
          left: 0.0,
          right: 0.0,
          child: Center(
            child: IgnorePointer(
              child: Container(
                width: 1100.0,
                height: 520.0,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      palette.glowColor,
                      palette.glowColor.withValues(alpha: 0.0)
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
        ),
        XpdSection(top: 88.0, child: content),
      ],
    );
  }

  Widget _heroHeadline() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = width < XpdLayout.tablet ? 38.0 : 56.0;
    final style = TextStyle(
      fontFamily: 'Geist',
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * -0.035,
      height: 1.04,
      color: palette.text,
    );

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: _t('Vous avez remporté le lot.', 'You won the lot.')),
          const TextSpan(text: '\n'),
          TextSpan(
            text: _t("Nous l'apportons chez vous.", 'We bring it home.'),
            style: TextStyle(color: palette.blueLink),
          ),
        ],
      ),
    );
  }

  /// The `01 → 02 → 03` strip under the hero paragraph.
  Widget _heroSteps() {
    final palette = XpdPalette.of(context);
    final steps = [
      ('01', _t('Envoyez le bordereau', 'Send the bordereau')),
      ('02', _t('Prix fixe sous 48 h', 'Fixed price in 48 h')),
      ('03', _t('Livré chez vous', 'Delivered to your door')),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: palette.chip,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10.0,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  steps[i].$1,
                  style: TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 12.0,
                    color: palette.amber,
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  steps[i].$2,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13.5,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('→', style: TextStyle(color: palette.faint)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _expressCard() {
    final palette = XpdPalette.of(context);
    return XpdPanel(
      padding: const EdgeInsets.all(24.0),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t('Devis express', 'Express quote'),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.18,
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              XpdTag(
                label: _t('RÉPONSE 48 H', 'REPLY IN 48 H'),
                color: palette.amberText,
                background: palette.amberTint(0.12),
                borderColor: palette.amberTint(0.30),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          XpdField(
            label:
                _t('Enlèvement — maison de ventes', 'Pickup — auction house'),
            hint: 'Drouot, Paris 9e',
            controller: _expressPickup,
            verticalPadding: 12.0,
          ),
          const SizedBox(height: 16.0),
          XpdField(
            label: _t(
              'Livraison — ville et code postal',
              'Delivery — city and postcode',
            ),
            hint: '33000 Bordeaux',
            controller: _expressDelivery,
            verticalPadding: 12.0,
          ),
          const SizedBox(height: 16.0),
          XpdFileDrop(
            title: _t('Bordereau (facultatif)', 'Bordereau (optional)'),
            caption: _t(
              'Nous lisons les lots pour vous',
              'We read the lots for you',
            ),
            fileName: _expressFile?.originalFilename,
            chipSize: 34.0,
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
            onTap: () => _pickFile((f) => _expressFile = f),
          ),
          const SizedBox(height: 16.0),
          XpdButton(
            label: _t('Obtenir un prix fixe', 'Get a fixed price'),
            fontSize: 15.5,
            expand: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
            onPressed: _submitExpress,
          ),
          const SizedBox(height: 16.0),
          Text(
            _t(
              'PRIX FIXE · ASSURÉ AD VALOREM · SANS ENGAGEMENT',
              'FIXED PRICE · INSURED AD VALOREM · NO COMMITMENT',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 10.5,
              letterSpacing: 10.5 * 0.1,
              color: palette.faint,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Stats
  // ========================================

  Widget _stats() {
    final palette = XpdPalette.of(context);
    final cards = [
      ('48h', _t('Devis sous 48 heures', 'Quote within 48 hours')),
      ('100%', _t('France métropolitaine', 'Mainland France')),
      ('10j', _t('Avant frais de gardiennage', 'Before storage fees')),
      ('Ad valorem', _t('Assurance disponible', 'Insurance available')),
    ];

    return XpdSection(
      top: 64.0,
      child: _Grid(
        minTileWidth: 220.0,
        spacing: 16.0,
        children: [
          for (final (value, label) in cards)
            XpdPanel(
              padding: const EdgeInsets.all(24.0),
              radius: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 30.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.6,
                        color: palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14.0,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========================================
  // One company, two apps
  // ========================================

  Widget _group() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;

    final intro = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 40.0,
      runSpacing: 20.0,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              XpdEyebrow(
                  _t('UN GROUPE, DEUX APPLICATIONS', 'ONE COMPANY, TWO APPS')),
              const SizedBox(height: 14.0),
              XpdSectionHeading(_t(
                'Expedion prend la commande. Expeditoo trouve le camion.',
                'Expedion books it. Expeditoo moves it.',
              )),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380.0),
          child: Text(
            _t(
              "Vous ne parlez qu'à Expedion. Derrière, le même groupe opère le réseau de transporteurs : un lot n'attend jamais un camion.",
              'You only ever deal with Expedion. Behind it, the same company runs the carrier network, so a lot never waits for a truck.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16.0,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ),
      ],
    );

    final expedionCard = XpdPanel(
      padding: const EdgeInsets.all(30.0),
      borderColor: palette.amberTint(0.24),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(palette.amberTint(0.10), palette.bg2),
          palette.bg2,
        ],
        stops: const [0.0, 0.6],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 11.0,
            runSpacing: 8.0,
            children: [
              const XpdLogoMark(size: 26.0),
              Text(
                'EXPEDION',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.34,
                  color: palette.text,
                ),
              ),
              XpdTag(
                label: _t('CÔTÉ ACHETEUR · MOBILE', 'BUYER SIDE · MOBILE'),
                color: palette.amberText,
                borderColor: palette.amberTint(0.30),
              ),
              XpdTag(
                label: _t('VOUS ÊTES ICI', 'YOU ARE HERE'),
                color: const Color(0xFF0A0B0E),
                background: XpdPalette.brandAmber,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            _t(
              "Votre devis, votre bordereau, votre créneau d'enlèvement, votre suivi — dans une app mobile iPhone et Android. Un chauffeur du réseau est attribué par notre équipe, en mode concierge.",
              'Your quote, your bordereau, your pickup slot, your tracking — in a mobile app for iPhone and Android. A driver from the pool is assigned by our team, concierge style.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.5,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );

    final expeditooCard = XpdPanel(
      padding: const EdgeInsets.all(30.0),
      borderColor: palette.blueTint(0.32),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(palette.blueTint(0.14), palette.bg2),
          palette.bg2,
        ],
        stops: const [0.0, 0.6],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 11.0,
            runSpacing: 8.0,
            children: [
              const ExpeditooLogoMark(size: 26.0),
              Text(
                'EXPEDITOO',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.34,
                  color: palette.text,
                ),
              ),
              XpdTag(
                label: _t('CÔTÉ TRANSPORT · WEB', 'CARRIER SIDE · WEB'),
                color: palette.blueText,
                borderColor: palette.blueTint(0.35),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _openExpeditoo,
                  child: const XpdTag(
                    label: 'OUVRIR EXPEDITOO →',
                    color: Colors.white,
                    background: XpdPalette.blue,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            _t(
              "Le réseau, sur le web. Si aucun chauffeur n'est disponible, la course est publiée automatiquement et les transporteurs enchèrent à la baisse. Vous choisissez, ou nous choisissons pour vous.",
              'The network, on the web. When no driver is free, the job is posted automatically and carriers bid it down. You pick, or we pick for you.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.5,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );

    return XpdSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          const SizedBox(height: 32.0),
          if (stack)
            Column(
              children: [
                expedionCard,
                const SizedBox(height: 16.0),
                expeditooCard,
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: expedionCard),
                  const SizedBox(width: 16.0),
                  Expanded(child: expeditooCard),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========================================
  // Routing flow
  // ========================================

  Widget _flow() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;

    Widget node({
      required String title,
      required String subtitle,
      Color? background,
      Color? borderColor,
      Color? titleColor,
      Color? subtitleColor,
      double maxWidth = double.infinity,
      bool centre = false,
    }) =>
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: background ?? palette.bg2,
              border: Border.all(color: borderColor ?? palette.line2),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment:
                  centre ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: centre ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: centre ? 17.0 : 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.17,
                    color: titleColor ?? palette.text,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  subtitle,
                  textAlign: centre ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14.0,
                    color: subtitleColor ?? palette.muted,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget connector(double height, Color color) => Container(
          width: 1.0,
          height: height,
          color: color,
        );

    final amberBg = palette.amberTint(0.07);
    final amberBorder = palette.amberTint(0.28);
    final amberLine = palette.amberTint(0.35);
    final blueBg = palette.blueTint(0.09);
    final blueBorder = palette.blueTint(0.34);
    final blueLine = palette.blueTint(0.40);

    final amberBranch = Column(
      children: [
        node(
          title: _t('Chauffeur disponible', 'Driver available'),
          subtitle: _t('Trouvé dans le réseau', 'Matched in the pool'),
          background: amberBg,
          borderColor: amberBorder,
          titleColor: palette.amberText,
          subtitleColor: palette.amberSub,
        ),
        connector(30.0, amberLine),
        node(
          title: _t('Attribution du chauffeur', 'Admin assigns driver'),
          subtitle: _t('Modèle concierge', 'Concierge model'),
          background: amberBg,
          borderColor: amberBorder,
          titleColor: palette.amberText,
          subtitleColor: palette.amberSub,
        ),
        connector(stack ? 30.0 : 150.0, amberLine),
      ],
    );

    final blueBranch = Column(
      children: [
        node(
          title: _t('Aucun chauffeur disponible', 'No driver available'),
          subtitle: _t('Ou course refusée', 'Or cannot take the job'),
          background: blueBg,
          borderColor: blueBorder,
          titleColor: palette.blueText,
          subtitleColor: palette.blueSub,
        ),
        connector(30.0, blueLine),
        node(
          title: _t('Transmis à Expeditoo', 'Escalate to Expeditoo'),
          subtitle: _t(
            'Course publiée automatiquement',
            'Job posted automatically',
          ),
          background: blueBg,
          borderColor: blueBorder,
          titleColor: palette.blueText,
          subtitleColor: palette.blueSub,
        ),
        connector(30.0, blueLine),
        node(
          title:
              _t('Les transporteurs enchèrent', 'Carriers bid, client picks'),
          subtitle: _t('Enchère inversée, vous choisissez', 'Reverse auction'),
          background: blueBg,
          borderColor: blueBorder,
          titleColor: palette.blueText,
          subtitleColor: palette.blueSub,
        ),
        connector(30.0, blueLine),
      ],
    );

    return Container(
      key: _flowKey,
      child: XpdSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XpdSectionIntro(
              eyebrow: _t('COMMENT ÇA MARCHE', 'HOW IT WORKS'),
              heading: _t(
                "De l'adjudication à votre porte",
                'From the hammer to your door',
              ),
              lead: _t(
                'Une seule demande, deux chemins possibles, toujours le même suivi.',
                'One request, two possible routes, always the same status feed.',
              ),
            ),
            const SizedBox(height: 44.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                node(
                  title:
                      _t('Vous demandez un devis', 'Client requests a devis'),
                  subtitle: _t(
                    'Sur Expedion, bordereau importé',
                    'Expedion, bordereau upload',
                  ),
                  maxWidth: 520.0,
                  centre: true,
                ),
                connector(34.0, palette.line2),
                if (stack)
                  Column(children: [
                    amberBranch,
                    const SizedBox(height: 8.0),
                    blueBranch,
                  ])
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: amberBranch),
                        const SizedBox(width: 24.0),
                        Expanded(child: blueBranch),
                      ],
                    ),
                  ),
                node(
                  title: _t(
                      'Livraison, un seul suivi', 'Delivery, one status feed'),
                  subtitle: _t(
                    'Synchronisé entre les deux applications',
                    'Synced to both apps',
                  ),
                  maxWidth: 520.0,
                  centre: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Quote form
  // ========================================

  Widget _quoteForm() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;
    final narrow = width < XpdLayout.tablet;

    Widget pair(Widget a, Widget b) => narrow
        ? Column(children: [a, const SizedBox(height: 18.0), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 18.0),
              Expanded(child: b),
            ],
          );

    final form = XpdPanel(
      padding: const EdgeInsets.all(34.0),
      radius: 22.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _t('Demander un devis', 'Request a quote'),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 28.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 28.0 * -0.025,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _t(
              'Deux minutes. Joignez le bordereau, nous faisons la lecture.',
              'Two minutes. Attach the bordereau and we do the reading.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.0,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 26.0),
          pair(
            XpdField(
              label:
                  _t('Enlèvement — maison de ventes', 'Pickup — auction house'),
              hint: 'Drouot, Paris 9e',
              controller: _pickup,
            ),
            XpdField(
              label: _t(
                'Livraison — ville et code postal',
                'Delivery — city and postcode',
              ),
              hint: '33000 Bordeaux',
              controller: _delivery,
            ),
          ),
          const SizedBox(height: 18.0),
          pair(
            XpdField(
              label: _t('Nombre de lots', 'Number of lots'),
              hint: '2',
              controller: _lotCount,
              keyboardType: TextInputType.number,
            ),
            XpdSelect(
              label: _t('Type de lot', 'Type of lot'),
              value: _lotType,
              options: _isEnglish ? _lotTypesEn : _lotTypesFr,
              onChanged: (v) => setState(() => _lotType = v ?? _lotType),
            ),
          ),
          const SizedBox(height: 18.0),
          pair(
            XpdField(
              label: _t(
                "Prix d'adjudication, pour l'assurance",
                'Hammer price, for insurance',
              ),
              hint: '4 200 €',
              controller: _hammerPrice,
              keyboardType: TextInputType.number,
            ),
            XpdField(
              label: _t("Date limite d'enlèvement", 'Pickup deadline'),
              hint: '22 / 08 / 2026',
              controller: _deadline,
            ),
          ),
          const SizedBox(height: 26.0),
          XpdFileDrop(
            title: _t(
              "Joindre votre bordereau d'adjudication",
              'Attach your bordereau',
            ),
            caption: _t(
              "PDF, JPG ou PNG — jusqu'à 10 Mo",
              'PDF, JPG or PNG — up to 10 MB',
            ),
            fileName: _bordereau?.originalFilename,
            trailingLabel:
                narrow ? null : _t('Choisir un fichier', 'Choose a file'),
            onTap: () => _pickFile((f) => _bordereau = f),
          ),
          const SizedBox(height: 26.0),
          pair(
            XpdField(
              label: 'Email',
              hint: 'vous@exemple.fr',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            XpdField(
              label: _t('Téléphone', 'Phone'),
              hint: '06 12 34 56 78',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 26.0),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18.0,
            runSpacing: 12.0,
            children: [
              XpdButton(
                label: _t('Recevoir mon devis', 'Get my quote'),
                onPressed: _submitFull,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320.0),
                child: Text(
                  _t(
                    'Sans engagement. Réponse sous 48 heures, par email.',
                    'No commitment. Answer within 48 hours, by email.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13.0,
                    color: palette.dim,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final nextSteps = [
      (
        '01',
        _t(
          'Nous lisons le bordereau et dimensionnons le lot.',
          'We read the bordereau and size the lot.',
        ),
        palette.amber
      ),
      (
        '02',
        _t(
          'Un prix fixe, tout compris, arrive dans votre boîte mail.',
          'A fixed, all-in price lands in your inbox.',
        ),
        palette.amber
      ),
      (
        '03',
        _t(
          'Vous acceptez, nous réservons le créneau avec la maison de ventes.',
          'You accept, we book the pickup slot with the auction house.',
        ),
        palette.amber
      ),
      (
        '04',
        _t(
          'Chauffeur du réseau, ou transporteur via Expeditoo. Même suivi.',
          'Driver from the pool, or a carrier via Expeditoo. Same tracking.',
        ),
        palette.blueLink
      ),
    ];

    final aside = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdPanel(
          padding: const EdgeInsets.all(26.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              XpdEyebrow(_t('CE QUI SE PASSE ENSUITE', 'WHAT HAPPENS NEXT')),
              const SizedBox(height: 18.0),
              for (final (index, text, color) in nextSteps)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == '04' ? 0.0 : 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          index,
                          style: TextStyle(
                            fontFamily: 'Geist Mono',
                            fontSize: 12.0,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14.5,
                            height: 1.55,
                            color: palette.soft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        XpdPanel(
          padding: const EdgeInsets.all(22.0),
          background: palette.amberTint(0.07),
          borderColor: palette.amberTint(0.24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('Le gardiennage court vite', 'Storage clock is ticking'),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: palette.amberText,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _t(
                  "La plupart des maisons de ventes facturent le gardiennage après 10 jours. Envoyez la demande le jour de l'adjudication.",
                  'Most auction houses charge storage after 10 days. Send the request the day you win.',
                ),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14.0,
                  height: 1.55,
                  color: palette.amberSub,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      key: _devisKey,
      child: XpdSection(
        child: stack
            ? Column(
                children: [form, const SizedBox(height: 28.0), aside],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 28.0),
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 380.0, minWidth: 300.0),
                    child: aside,
                  ),
                ],
              ),
      ),
    );
  }

  // ========================================
  // Pricing
  // ========================================

  Widget _pricing() {
    final palette = XpdPalette.of(context);

    Widget tier({
      required String name,
      required String detail,
      required String price,
      required List<String> features,
      bool featured = false,
    }) {
      final card = XpdPanel(
        padding: const EdgeInsets.all(28.0),
        borderColor: featured ? palette.blueTint(0.34) : null,
        gradient: featured
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(palette.blueTint(0.12), palette.bg2),
                  palette.bg2,
                ],
                stops: const [0.0, 0.55],
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 17.0,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              detail,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14.0,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 18.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                price,
                style: TextStyle(
                  fontFamily: 'Geist Mono',
                  fontSize: 28.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.56,
                  color: palette.text,
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            Container(height: 1.0, color: palette.line),
            const SizedBox(height: 18.0),
            for (var i = 0; i < features.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == features.length - 1 ? 0.0 : 9.0,
                ),
                child: Text(
                  features[i],
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14.0,
                    color: palette.soft,
                  ),
                ),
              ),
          ],
        ),
      );

      if (!featured) return card;
      // `LE PLUS FRÉQUENT` sits astride the card's top border.
      return Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -11.0,
            left: 28.0,
            child: XpdTag(
              label: _t('LE PLUS FRÉQUENT', 'MOST COMMON'),
              color: Colors.white,
              background: XpdPalette.blue,
              filled: true,
            ),
          ),
        ],
      );
    }

    return Container(
      key: _tarifsKey,
      child: XpdSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XpdSectionIntro(
              eyebrow: _t('FOURCHETTES DE PRIX', 'ESTIMATE RANGES'),
              heading: _t(
                'Ce que coûte une livraison, en général',
                'What a delivery usually costs',
              ),
              lead: _t(
                'Fourchettes indicatives pour un enlèvement en France métropolitaine. Votre devis, lui, est un prix fixe.',
                'Indicative ranges for a single pickup in mainland France. Your quote is a fixed price, not an estimate.',
              ),
              maxWidth: 620.0,
            ),
            const SizedBox(height: 36.0),
            _Grid(
              minTileWidth: 300.0,
              spacing: 16.0,
              children: [
                tier(
                  name: _t('Petit lot', 'Small lot'),
                  detail: _t(
                    'Tableau, objet, moins de 20 kg',
                    'Painting, object, under 20 kg',
                  ),
                  price: '45 – 90 €',
                  features: [
                    _t('Enlèvement et emballage inclus',
                        'Pickup and packing included'),
                    _t('Livraison à votre porte', 'Delivery to your door'),
                    _t('2 à 4 jours ouvrés', '2 to 4 working days'),
                  ],
                ),
                tier(
                  name: _t('Lot standard', 'Standard lot'),
                  detail: _t('Mobilier, 20 à 80 kg', 'Furniture, 20 to 80 kg'),
                  price: '90 – 260 €',
                  featured: true,
                  features: [
                    _t('Manutention à deux si nécessaire',
                        'Two-person handling if needed'),
                    _t('Couvertures, coins, film', 'Blankets, corners, film'),
                    _t('Créneau de livraison de 2 h', '2h delivery window'),
                  ],
                ),
                tier(
                  name: _t('Volumineux ou fragile', 'Bulky or fragile'),
                  detail: _t(
                    'Armoire, marbre, plus de 80 kg',
                    'Wardrobe, marble, over 80 kg',
                  ),
                  price: _t('à partir de 320 €', 'from 320 €'),
                  features: [
                    _t('Caisse sur mesure sur demande', 'Crating on request'),
                    _t(
                      'Étages et escaliers chiffrés au devis',
                      'Stairs and floor noted on the quote',
                    ),
                    _t(
                      'Publié sur Expeditoo si spécialisé',
                      'Posted to Expeditoo if specialised',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 26.0, vertical: 22.0),
              decoration: BoxDecoration(
                color: palette.chip,
                border: Border.all(color: palette.line),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Wrap(
                spacing: 32.0,
                runSpacing: 10.0,
                children: [
                  for (final note in [
                    _t(
                      "Assurance ad valorem, 1,2 % du prix d'adjudication",
                      'Ad valorem insurance, 1.2% of the hammer price',
                    ),
                    _t('Gardiennage offert 10 jours',
                        'Storage free for 10 days'),
                    _t(
                      'Prix HT, options chiffrées au devis',
                      'Prices excl. VAT, options priced on the quote',
                    ),
                  ])
                    Text(
                      note,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14.0,
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Coverage
  // ========================================

  Widget _coverage() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;

    // J+2 regions are highlighted in amber; the rest sit in the muted grey.
    const regions = <(String, String)>[
      ('Île-de-France', 'J+2'),
      ('Centre-Val de Loire', 'J+2'),
      ('Hauts-de-France', 'J+3'),
      ('Normandie', 'J+3'),
      ('Grand Est', 'J+3'),
      ('Bretagne', 'J+3'),
      ('Pays de la Loire', 'J+3'),
      ('Bourgogne-Franche-Comté', 'J+3'),
      ('Auvergne-Rhône-Alpes', 'J+3'),
      ('Nouvelle-Aquitaine', 'J+4'),
      ('Occitanie', 'J+4'),
      ("Provence-Alpes-Côte d'Azur", 'J+4'),
    ];

    Widget row((String, String) region) => Container(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  region.$1,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14.5,
                    color: palette.soft,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                region.$2,
                style: TextStyle(
                  fontFamily: 'Geist Mono',
                  fontSize: 13.0,
                  color: region.$2 == 'J+2' ? palette.amber : palette.muted,
                ),
              ),
            ],
          ),
        );

    final table = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480.0),
      child: _Grid(
        minTileWidth: 210.0,
        spacing: 22.0,
        runSpacing: 10.0,
        children: [for (final region in regions) row(region)],
      ),
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdEyebrow(_t('COUVERTURE', 'COVERAGE')),
        const SizedBox(height: 22.0),
        XpdSectionHeading(_t(
          'Toutes les salles des ventes de France métropolitaine',
          'Every auction room in mainland France',
        )),
        const SizedBox(height: 22.0),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460.0),
          child: Text(
            _t(
              'Délais habituels après enlèvement du lot. Corse et outre-mer sur devis.',
              'Typical transit once the lot is collected. Corsica and overseas on request.',
            ),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16.0,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 22.0),
        table,
      ],
    );

    final map = XpdPanel(
      padding: const EdgeInsets.all(14.0),
      radius: 22.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const XpdStripePlate(height: 430.0, label: 'CARTE DE COUVERTURE'),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 4.0),
            child: Text(
              _t(
                'Déposez ici la carte de France, régions teintées par délai',
                'Drop the coverage map here — regions shaded by transit time',
              ),
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 11.0,
                color: palette.faint,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: _couvertureKey,
      child: XpdSection(
        child: stack
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 40.0), map],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 40.0),
                  Expanded(child: map),
                ],
              ),
      ),
    );
  }

  // ========================================
  // Why it arrives intact
  // ========================================

  Widget _handling() {
    final palette = XpdPalette.of(context);

    Widget promise(String title, String body, Color tint, Color border) =>
        XpdPanel(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: tint,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.17,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                body,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14.5,
                  height: 1.6,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        );

    return XpdSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                XpdEyebrow(
                    _t('POURQUOI ÇA ARRIVE INTACT', 'WHY IT ARRIVES INTACT')),
                const SizedBox(height: 14.0),
                XpdSectionHeading(
                  _t("Un lot n'est pas un colis", 'A lot is not a parcel'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36.0),
          _Grid(
            minTileWidth: 300.0,
            spacing: 16.0,
            children: [
              promise(
                _t("Assuré à la valeur d'adjudication",
                    'Insured at hammer value'),
                _t(
                  "Couverture ad valorem sur demande, de l'enlèvement à la signature. L'attestation est jointe au devis.",
                  'Ad valorem cover on request, from pickup to signature. The certificate is attached to your quote.',
                ),
                palette.amberTint(0.12),
                palette.amberTint(0.28),
              ),
              promise(
                _t('Emballé pour la route', 'Packed for the road'),
                _t(
                  'Couvertures, protège-angles, film, caisse sur mesure pour le verre et le marbre. Photos avant chargement.',
                  'Blankets, corner guards, film, custom crates for glass and marble. Photos before loading.',
                ),
                palette.amberTint(0.12),
                palette.amberTint(0.28),
              ),
              promise(
                _t('Un suivi, deux applications', 'One feed, both apps'),
                _t(
                  "Que votre lot voyage avec notre chauffeur ou un transporteur d'Expeditoo, le suivi est le même.",
                  'Whether your lot travels with our driver or a carrier from Expeditoo, the status feed is the same one.',
                ),
                palette.blueTint(0.14),
                palette.blueTint(0.32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Mobile app
  // ========================================

  Widget _mobileApp() {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < XpdLayout.desktop;

    final phone = Center(
      child: Container(
        width: 250.0,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: palette.bg2,
          border: Border.all(color: palette.line2),
          borderRadius: BorderRadius.circular(36.0),
          boxShadow: [palette.shadow],
        ),
        child: XpdStripePlate(
          height: 490.0,
          radius: 26.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const XpdLogoMark(size: 64.0),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: palette.bg2,
                  border: Border.all(color: palette.line),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'CAPTURE APP MOBILE',
                  style: TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 11.0,
                    letterSpacing: 11.0 * 0.12,
                    color: palette.faint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bullets = [
      (
        _t('Une seule app, iPhone et Android.', 'One app, iPhone and Android.'),
        _t(
          'Flutter compile le même code en natif pour les deux stores — les nouveautés sortent le même jour partout.',
          'Flutter compiles the same code natively for both stores — features ship the same day everywhere.',
        ),
      ),
      (
        _t('Le bordereau se scanne.', 'The bordereau scans itself.'),
        _t(
          'Photographiez votre bordereau ; la demande de devis part en deux minutes.',
          'Point the camera at your bordereau; the quote request leaves in two minutes.',
        ),
      ),
      (
        _t('Chaque étape vous prévient.', 'Every step notifies you.'),
        _t(
          "Notification à l'enlèvement, au départ, à l'approche du chauffeur. Rien à rafraîchir.",
          'Push at pickup, departure and when the driver is close. No refreshing.',
        ),
      ),
      (
        _t('Vos documents hors connexion.', 'Documents offline.'),
        _t(
          "Devis, attestation d'assurance et factures restent lisibles sans réseau.",
          'Quote, insurance certificate and invoices stay readable without network.',
        ),
      ),
    ];

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdEyebrow(_t(
          'APPLICATION MOBILE — iOS & ANDROID',
          'MOBILE APP — iOS & ANDROID',
        )),
        const SizedBox(height: 20.0),
        XpdSectionHeading(_t(
          'Votre lot vit dans votre poche',
          'Your lot lives in your pocket',
        )),
        const SizedBox(height: 20.0),
        Text(
          _t(
            'Expedion est une application mobile, construite avec Flutter. Un seul code, deux plateformes — et ça se voit :',
            'Expedion is a mobile app, built with Flutter. One codebase, both platforms — and it shows:',
          ),
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16.0,
            height: 1.6,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 20.0),
        for (final (lead, rest) in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text(
                    '→',
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 12.0,
                      color: palette.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15.0,
                        height: 1.6,
                        color: palette.text,
                      ),
                      children: [
                        TextSpan(
                          text: '$lead ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: rest,
                          style: TextStyle(color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6.0),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10.0,
          runSpacing: 10.0,
          children: [
            for (final store in ['APP STORE', 'GOOGLE PLAY'])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.line2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  store,
                  style: TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 11.0,
                    letterSpacing: 11.0 * 0.12,
                    color: palette.muted,
                  ),
                ),
              ),
            Text(
              _t(
                'Badges à remplacer par les visuels officiels des stores',
                'Badges to be replaced by official store assets',
              ),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13.0,
                color: palette.faint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: palette.blueTint(0.09),
            border: Border.all(color: palette.blueTint(0.30)),
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.0,
            runSpacing: 8.0,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460.0),
                child: Text(
                  _t(
                    "Transporteur ? Expeditoo est 100 % web — rien à installer, les enchères se font dans le navigateur.",
                    'Carrier? Expeditoo is 100% web — nothing to install, bids in the browser.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14.0,
                    color: palette.blueSub,
                  ),
                ),
              ),
              XpdLink(
                label: _t('Voir Expeditoo →', 'See Expeditoo →'),
                onTap: _openExpeditoo,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      key: _appKey,
      child: XpdSection(
        child: stack
            ? Column(children: [phone, const SizedBox(height: 48.0), copy])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // `grid-template-columns:minmax(280px,0.7fr) minmax(0,1.3fr)`
                  Expanded(flex: 7, child: phone),
                  const SizedBox(width: 48.0),
                  Expanded(flex: 13, child: copy),
                ],
              ),
      ),
    );
  }

  // ========================================
  // Partners, testimonials, FAQ
  // ========================================

  Widget _partners() {
    return XpdSection(
      top: XpdLayout.sectionGapSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          XpdEyebrow(_t(
            'MAISONS DE VENTES OÙ NOUS PASSONS CHAQUE SEMAINE',
            'AUCTION HOUSES WE COLLECT FROM WEEKLY',
          )),
          const SizedBox(height: 26.0),
          _Grid(
            minTileWidth: 150.0,
            spacing: 12.0,
            children: [
              for (var i = 1; i <= 6; i++)
                XpdStripePlate(
                  height: 74.0,
                  label: 'LOGO ${i.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testimonials() {
    final palette = XpdPalette.of(context);

    Widget card(String quote, String name, String role) => XpdPanel(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const XpdStars(size: 13.0),
              const SizedBox(height: 20.0),
              Text(
                quote,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18.0,
                  height: 1.55,
                  letterSpacing: -0.18,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.chip,
                      border: Border.all(color: palette.line),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        role,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13.0,
                          color: palette.dim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

    return XpdSection(
      top: XpdLayout.sectionGapSm,
      child: _Grid(
        minTileWidth: 340.0,
        spacing: 16.0,
        children: [
          card(
            _t(
              "« J'ai acheté une commode à Paris et j'habite Bordeaux. Le devis est arrivé le lendemain matin, et je n'ai eu personne à appeler. »",
              '“I bought a chest of drawers in Paris and live in Bordeaux. The quote came the next morning, and I never had to call anyone.”',
            ),
            'Claire M.',
            _t('Acheteuse particulière, Bordeaux', 'Private buyer, Bordeaux'),
          ),
          card(
            _t(
              '« Un miroir, deux lampes, une console en marbre. Tout est arrivé emballé comme au départ. Deux heures de prévenance avant la livraison. »',
              '“A mirror, two lamps, a marble console. Everything arrived wrapped as it left. Two hours’ notice before delivery.”',
            ),
            'Julien R.',
            _t('Acheteur particulier, Lyon', 'Private buyer, Lyon'),
          ),
        ],
      ),
    );
  }

  Widget _faq() {
    final palette = XpdPalette.of(context);

    final entries = <(String, String)>[
      (
        _t('De quoi avez-vous besoin pour chiffrer ?',
            'What do you need to quote?'),
        _t(
          "Le bordereau, le code postal de livraison et la date limite d'enlèvement. Si vous connaissez les dimensions, ajoutez-les ; sinon nous appelons la maison de ventes.",
          'The bordereau, the delivery postcode and the pickup deadline. If you know the dimensions, add them; otherwise we call the auction house.',
        ),
      ),
      (
        _t('Qui transporte réellement mon lot ?',
            'Who actually carries my lot?'),
        _t(
          "Un chauffeur de notre réseau, attribué par notre équipe. Si aucun n'est disponible, la course est publiée sur Expeditoo, notre plateforme transporteurs, et un transporteur vérifié la prend au prix de son enchère. Même assurance, même suivi, même interlocuteur.",
          'A driver from our own pool, assigned by our team. If none is free, the job is posted on Expeditoo, our carrier platform, and a vetted carrier takes it at a bid price. Same insurance, same tracking, same contact.',
        ),
      ),
      (
        _t("Quand le lot est-il enlevé ?", 'When is the lot collected?'),
        _t(
          "En général dans les 3 jours ouvrés suivant l'acceptation du devis, dans les horaires de retrait de la maison de ventes. Nous réservons le créneau pour vous.",
          "Usually within 3 working days of accepting the quote, inside the auction house's own collection hours. We book the slot for you.",
        ),
      ),
      (
        _t("Et si quelque chose est abîmé ?", 'And if something is damaged?'),
        _t(
          "Des photos sont prises avant chargement et à la livraison. Avec la couverture ad valorem, le sinistre est indemnisé au prix d'adjudication indiqué sur votre devis.",
          'Photos are taken before loading and at delivery. With ad valorem cover, a claim is settled at the hammer price stated on your quote.',
        ),
      ),
      (
        _t("Montez-vous le lot à l'étage ?", 'Do you carry the lot upstairs?'),
        _t(
          "Oui, si vous indiquez l'étage et la présence d'un ascenseur lors de la demande. C'est chiffré au devis, jamais facturé sur le pas de la porte.",
          'Yes, if you tell us the floor and whether there is a lift when you request the quote. It is priced in, never charged on the doorstep.',
        ),
      ),
      (
        _t('Pouvez-vous garder mon lot ?', 'Can you store the lot for me?'),
        _t(
          "Dix jours de gardiennage sont inclus après enlèvement, puis un tarif mensuel indiqué au devis. Cela reste moins cher que le gardiennage de la plupart des maisons de ventes.",
          'Ten days of storage are included after collection, then a monthly rate you will find on the quote. It is still cheaper than most auction-house storage.',
        ),
      ),
    ];

    return Container(
      key: _faqKey,
      child: XpdSection(
        maxWidth: XpdLayout.narrowWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const XpdEyebrow('FAQ'),
            const SizedBox(height: 12.0),
            XpdSectionHeading(
              _t('Les questions que posent les acheteurs',
                  'Questions buyers ask'),
            ),
            const SizedBox(height: 32.0),
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == entries.length - 1 ? 0.0 : 10.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.bg2,
                    border: Border.all(color: palette.line),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _openFaq.contains(i)
                                ? _openFaq.remove(i)
                                : _openFaq.add(i);
                          }),
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 20.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entries[i].$1,
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.165,
                                      color: palette.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                AnimatedRotation(
                                  turns: _openFaq.contains(i) ? -0.5 : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20.0,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 22.0),
                          child: Text(
                            entries[i].$2,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 15.0,
                              height: 1.65,
                              color: palette.muted,
                            ),
                          ),
                        ),
                        crossFadeState: _openFaq.contains(i)
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                        sizeCurve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Closing CTA and footer
  // ========================================

  Widget _closing() {
    final palette = XpdPalette.of(context);

    return Container(
      key: _contactKey,
      child: XpdSection(
        child: Container(
          padding: const EdgeInsets.all(56.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(palette.blueTint(0.16), palette.bg2),
                Color.alphaBlend(palette.amberTint(0.08), palette.bg2),
              ],
            ),
            border: Border.all(color: palette.line2),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 40.0,
            runSpacing: 28.0,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        'Envoyez le bordereau. Recevez un prix fixe.',
                        'Send the bordereau. Get a fixed price.',
                      ),
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 34.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 34.0 * -0.03,
                        height: 1.12,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _t(
                        'Réponse sous 48 heures, ou appelez-nous au $_phoneNumber.',
                        'Answer within 48 hours, or call us on $_phoneNumber.',
                      ),
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16.5,
                        height: 1.55,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  XpdButton(
                    label: _t('Demander un devis', 'Request a quote'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 16.0,
                    ),
                    onPressed: () => _scrollTo(_devisKey),
                  ),
                  XpdButton(
                    label: _contactEmail,
                    variant: XpdButtonVariant.outline,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 16.0,
                    ),
                    onPressed: _mailContact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() => XpdFooter(
        tagline: _t(
          'Expéditions des ventes aux enchères. Enlèvement, emballage et livraison de vos lots partout en France métropolitaine.',
          'Auction shipping. Pickup, packing and delivery of your lots across mainland France.',
        ),
        domain: 'EXPEDION-ENCHERES.COM',
        copyright: '© ${DateTime.now().year} Expedion — '
            '${_t('Expéditions des ventes aux enchères', 'Auction shipping')}',
        groupNote: _t(
          'Expedion et Expeditoo appartiennent au même groupe',
          'Expedion and Expeditoo are part of the same company',
        ),
        columns: [
          XpdFooterColumn(
            title: 'Service',
            links: [
              XpdFooterLink(
                label: _t('Demander un devis', 'Request a quote'),
                onTap: () => _scrollTo(_devisKey),
              ),
              XpdFooterLink(
                label: _t('Tarifs', 'Pricing'),
                onTap: () => _scrollTo(_tarifsKey),
              ),
              XpdFooterLink(
                label: _t('Couverture', 'Coverage'),
                onTap: () => _scrollTo(_couvertureKey),
              ),
              XpdFooterLink(
                label: _t('Application mobile', 'Mobile app'),
                onTap: () => _scrollTo(_appKey),
              ),
            ],
          ),
          XpdFooterColumn(
            title: _t('Groupe', 'Group'),
            links: [
              XpdFooterLink(
                label: _t('Expeditoo — transporteurs', 'Expeditoo — carriers'),
                onTap: _openExpeditoo,
              ),
              XpdFooterLink(
                label: _t('Devenir transporteur', 'Become a carrier'),
                onTap: _openExpeditoo,
              ),
              XpdFooterLink(
                label: _t('Maisons de ventes', 'Auction houses'),
                onTap: () => context.pushNamed(ContactWidget.routeName),
              ),
            ],
          ),
          XpdFooterColumn(
            title: _t('Légal', 'Legal'),
            links: [
              // No legal pages exist yet; these render as plain text rather
              // than links that go nowhere.
              const XpdFooterLink(label: 'CGV'),
              XpdFooterLink(label: _t('Mentions légales', 'Legal notice')),
              XpdFooterLink(
                label: _t('Politique de confidentialité', 'Privacy policy'),
              ),
              const XpdFooterLink(label: 'Cookies'),
            ],
          ),
        ],
      );
}

/// Keeps [XpdHeader] pinned once the announcement strip has scrolled past.
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.child});

  final XpdHeader child;

  @override
  double get minExtent => XpdHeader.height;

  @override
  double get maxExtent => XpdHeader.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_PinnedHeader old) => old.child != child;
}

/// A plain text action in the header's trailing group — "Connexion".
class _HeaderTextAction extends StatefulWidget {
  const _HeaderTextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeaderTextAction> createState() => _HeaderTextActionState();
}

class _HeaderTextActionState extends State<_HeaderTextAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14.5,
            color: _hovered ? palette.blueLink : palette.muted,
          ),
        ),
      ),
    );
  }
}

/// The header's links, the toggles and the account action, as a drawer on the
/// widths where they cannot share a row.
class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
    required this.onLink,
    required this.flowKey,
    required this.tarifsKey,
    required this.couvertureKey,
    required this.faqKey,
    required this.devisKey,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.onLogin,
    required this.loggedIn,
    required this.t,
  });

  final void Function(GlobalKey) onLink;
  final GlobalKey flowKey;
  final GlobalKey tarifsKey;
  final GlobalKey couvertureKey;
  final GlobalKey faqKey;
  final GlobalKey devisKey;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogin;
  final bool loggedIn;
  final String Function(String, String) t;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final entries = <(String, GlobalKey)>[
      (t('Comment ça marche', 'How it works'), flowKey),
      (t('Tarifs', 'Pricing'), tarifsKey),
      (t('Couverture', 'Coverage'), couvertureKey),
      ('FAQ', faqKey),
    ];

    return Drawer(
      backgroundColor: palette.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: XpdLogo(markSize: 26.0)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.text),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              for (final (label, key) in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16.0,
                      color: palette.text,
                    ),
                  ),
                  onTap: () => onLink(key),
                ),
              const Spacer(),
              XpdLanguageToggle(
                languageCode: languageCode,
                onChanged: onLanguageChanged,
              ),
              const SizedBox(height: 16.0),
              XpdButton(
                label: t('Demander un devis', 'Request a quote'),
                expand: true,
                onPressed: () => onLink(devisKey),
              ),
              const SizedBox(height: 10.0),
              XpdButton(
                label: loggedIn
                    ? t('Espace personnel', 'My account')
                    : t('Connexion', 'Log in'),
                variant: XpdButtonVariant.outline,
                expand: true,
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays children out in as many equal columns as fit at [minTileWidth],
/// collapsing to fewer as the viewport narrows. The design's grids are all
/// `repeat(N, minmax(0,1fr))`, which is this once N stops fitting.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.children,
    this.minTileWidth = 260.0,
    this.spacing = 16.0,
    double? runSpacing,
  }) : runSpacing = runSpacing ?? spacing;

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, children.length);
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
