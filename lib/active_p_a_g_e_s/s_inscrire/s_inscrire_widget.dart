import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/design_system/ds_google_glyph.dart';
import '/design_system/ds_logo.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/quote_draft.dart';
import '/index.dart';
import '/main.dart';
import '/quote_resume.dart';
import 's_inscrire_model.dart';
export 's_inscrire_model.dart';

/// Create an account.
///
/// Shares the login page's shape — lockup, one bordered card, labelled fields,
/// filled action, "or continue with", Google — extended with the billing and
/// delivery addresses the quote flow needs. Those live in their own labelled
/// groups rather than a single undifferentiated column, since there are twelve
/// of them.
///
/// Accounts are created in Expeditoo's Better Auth, which is configured with
/// `requireEmailVerification: true` and `autoSignIn: false`. A successful
/// sign-up therefore does *not* sign anyone in: the page switches to a
/// "check your inbox" state instead of navigating into the app. The Firebase
/// path, still used when Expeditoo is unconfigured, does sign in immediately,
/// and only then are the Airtable and Firestore side effects meaningful — so
/// they are guarded on actually having a session.
class SInscrireWidget extends StatefulWidget {
  const SInscrireWidget({super.key});

  static String routeName = 'S-inscrire';
  static String routePath = '/sInscrire';

  @override
  State<SInscrireWidget> createState() => _SInscrireWidgetState();
}

class _SInscrireWidgetState extends State<SInscrireWidget> {
  late SInscrireModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _sameDeliveryAddress = true;
  bool _acceptedTerms = false;
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;

  /// Set once Better Auth has created the account and mailed the link.
  String? _verificationSentTo;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SInscrireModel());

    _model.nomTextController ??= TextEditingController();
    _model.nomFocusNode ??= FocusNode();
    _model.prenomTextController ??= TextEditingController();
    _model.prenomFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.motDePasseTextController ??= TextEditingController();
    _model.motDePasseFocusNode ??= FocusNode();
    _model.motDePasseConfirmeTextController ??= TextEditingController();
    _model.motDePasseConfirmeFocusNode ??= FocusNode();

    // Billing address.
    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController5 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController6 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController7 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();
    _model.textController8 ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();
    _model.textController9 ??= TextEditingController();
    _model.textFieldFocusNode6 ??= FocusNode();

    // Delivery address, used only when it differs from the billing one.
    _model.textController10 ??= TextEditingController();
    _model.textFieldFocusNode7 ??= FocusNode();
    _model.textController11 ??= TextEditingController();
    _model.textFieldFocusNode8 ??= FocusNode();
    _model.textController12 ??= TextEditingController();
    _model.textFieldFocusNode9 ??= FocusNode();
    _model.textController13 ??= TextEditingController();
    _model.textFieldFocusNode10 ??= FocusNode();
    _model.textController14 ??= TextEditingController();
    _model.textFieldFocusNode11 ??= FocusNode();
    _model.textController15 ??= TextEditingController();
    _model.textFieldFocusNode12 ??= FocusNode();

    // Web signs in through Google's own button, which publishes its result on
    // a stream rather than returning it — see the sign-in page for why.
    if (googleIdentityButtonSupported) {
      authManager.listenForGoogleWebSignIn();
      _googleWebSignIn = authManager.googleWebSignIns.listen(_onGoogleSignUp);
    }
  }

  StreamSubscription<BaseAuthUser?>? _googleWebSignIn;

  /// Finishes a Google sign-up.
  ///
  /// The customer record is created here as well as on the email path. It was
  /// created on neither before, and once Google becomes the primary way to sign
  /// up on web that would have left the whole cohort without one.
  ///
  /// Whatever address fields the visitor filled in are used. They may be empty
  /// — Google needs none of them — and an incomplete customer record is still
  /// better than no record at all, since the quote flow collects the address
  /// again anyway and has somewhere to put it.
  /// A null [user] means the Google exchange was refused, not that nothing
  /// happened — report it rather than leaving the button looking inert.
  Future<void> _onGoogleSignUp(BaseAuthUser? user) async {
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (user == null) {
      setState(() => _error = _explain());
      return;
    }
    await _createAirtableCustomer(
      uid: user.uid ?? '',
      email: user.email ?? '',
    );
    if (!mounted) return;
    context.goNamedAuth(_destination, context.mounted);
  }

  @override
  void dispose() {
    _googleWebSignIn?.cancel();
    _model.dispose();
    super.dispose();
  }

  bool get _isEnglish =>
      FFLocalizations.of(context).languageCode.startsWith('en');

  String _t(String fr, String en) => _isEnglish ? en : fr;

  String _explain() {
    final result = authManager.lastExpeditooResult;
    switch (result?.code) {
      case 'USER_ALREADY_EXISTS':
      case 'USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL':
        return _t(
          'Un compte existe déjà avec cette adresse email.',
          'An account with that email already exists.',
        );
      case 'PASSWORD_TOO_SHORT':
        return _t(
          'Le mot de passe est trop court.',
          'That password is too short.',
        );
      case 'NOT_CONFIGURED':
        return _t(
          "La création de compte n'est pas disponible pour le moment.",
          'Account creation is unavailable right now.',
        );
      default:
        // Not `result.message` — see the same guard in se_connecter: that
        // string's language is whatever the failure spoke, not the reader's.
        return _t('La création du compte a échoué.',
            'Could not create the account.');
    }
  }

  /// Where to land once the account exists.
  ///
  /// A draft parked by the landing page means the visitor has already answered
  /// the fork's question — they attached the slip, or typed the addresses
  /// instead — so this resumes into the matching form rather than asking
  /// again. With no draft it is `ChoixDevisWidget`, as before.
  String get _destination => quoteDraftResumeRoute(QuoteDraft.peek());

  Future<void> _createAccount() async {
    if (_busy) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      setState(() => _error = _t(
            "Acceptez les conditions d'utilisation pour continuer.",
            'Accept the terms of use to continue.',
          ));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _model.emailTextController.text.trim();

    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.createAccountWithEmail(
      context,
      email,
      _model.motDePasseTextController.text,
    );

    if (!mounted) return;

    if (user == null) {
      final result = authManager.lastExpeditooResult;
      // Better Auth created the account but withheld the session pending
      // verification — that is a success, not a failure.
      if (result != null && result.succeeded) {
        // The customer record is created here, before anyone is signed in,
        // because this is the only moment the form's answers exist. Waiting
        // until after verification would mean asking for the address again.
        await _createAirtableCustomer(
          uid: result.user?.id ?? '',
          email: result.user?.email ?? email,
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _verificationSentTo = email;
        });
        return;
      }
      setState(() {
        _busy = false;
        _error = _explain();
      });
      return;
    }

    // Reached when the account system signed the visitor in on creation, which
    // today means the Firebase path. Both records are keyed on that session.
    await _createAirtableCustomer(uid: currentUserUid, email: currentUserEmail);
    await _syncFirestoreProfile();

    if (!mounted) return;
    setState(() => _busy = false);

    // A draft parked on the landing page is a stronger statement of intent
    // than `PageDeDestination`, which is set by whichever screen last sent
    // someone here: registering in the middle of a quote request and landing
    // back on the landing page loses the answers they just typed.
    if (QuoteDraft.peek() != null ||
        FFAppState().PageDeDestination == 'Demande devis') {
      context.pushNamedAuth(_destination, context.mounted);
    } else {
      context.pushNamedAuth(AccueilWidget.routeName, context.mounted);
    }
  }

  /// Creates the Airtable customer record for a brand-new account.
  ///
  /// This used to be one method with the Firestore update below, guarded on
  /// `currentUserReference` and reached only from the Firebase branch — so a
  /// Better Auth sign-up, which is now every sign-up, got no customer record at
  /// all. The personal space then had nothing to show, and the customer number
  /// derived from the uid never existed.
  ///
  /// It is separate now because the two halves have genuinely different
  /// conditions. Airtable is keyed on whatever id the account system issued and
  /// needs no session, so it runs for every sign-up. Firestore needs a document
  /// that only a Firebase account has.
  ///
  /// [uid] and [email] are passed in rather than read from `currentUserUid`,
  /// because on the Better Auth path there is deliberately no session yet:
  /// sign-up runs under `requireEmailVerification`, so the account exists while
  /// nobody is signed in.
  Future<void> _createAirtableCustomer({
    required String uid,
    required String email,
  }) async {
    if (uid.isEmpty) return;
    await NewclientSignUpDMCall.call(
      nom: _model.nomTextController.text,
      prenom: _model.prenomTextController.text,
      eMail: email,
      authUserUid: uid,
      adresseClientL1: _model.textController4.text,
      adresseClientL2: _model.textController5.text,
      codePostalClient: _model.textController6.text,
      villeClient: _model.textController7.text,
      telephoneClient: _model.textController9.text,
      paysClient: _model.textController8.text,
    );
  }

  /// Mirrors the new account into the Firestore user document.
  ///
  /// Only a Firebase-era session has one of these, and `currentUserReference`
  /// now says so — it returns null for a Better Auth session rather than a
  /// reference to a document that has never existed. This guard is therefore
  /// finally the check the original comment claimed it was.
  Future<void> _syncFirestoreProfile() async {
    final reference = currentUserReference;
    if (reference == null) return;

    _model.airtableUserID = await GetAirtableUserIDCall.call(
      uid: currentUserUid,
    );

    await reference.update(createUsersRecordData(
      nom: _model.nomTextController.text,
      prenom: _model.prenomTextController.text,
      email: currentUserEmail,
      airtableUserID: GetAirtableUserIDCall.airtableUserID(
        (_model.airtableUserID?.jsonBody ?? ''),
      ),
    ));
  }

  Future<void> _signUpWithGoogle() async {
    if (_googleBusy) return;
    setState(() {
      _googleBusy = true;
      _error = null;
    });

    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithGoogle(context);

    if (!mounted) return;
    setState(() => _googleBusy = false);

    if (user == null) {
      if (authManager.lastExpeditooResult?.succeeded == false) {
        setState(() => _error = _explain());
      }
      return;
    }
    // A Google account arrives verified, so this lands straight in the app —
    // after the customer record, which this path used to skip entirely.
    await _onGoogleSignUp(user);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final palette = XpdPalette.of(context);
    final themeMode = MyApp.of(context).themeMode;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -200.0,
              left: 0.0,
              right: 0.0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 900.0,
                    height: 620.0,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          palette.glowColor,
                          palette.glowColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12.0,
              right: 16.0,
              child: Row(
                children: [
                  XpdLanguageToggle(
                    languageCode: _isEnglish ? 'en' : 'fr',
                    onChanged: (code) => MyApp.of(context).setLocale(code),
                  ),
                  const SizedBox(width: 12.0),
                  XpdThemeToggle(
                    mode: themeMode,
                    languageCode: _isEnglish ? 'en' : 'fr',
                    onChanged: (mode) {
                      MyApp.of(context).setThemeMode(mode);
                      // Light → system on a light platform changes no
                      // brightness, so nothing above would rebuild the tick.
                      safeSetState(() {});
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 48.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () =>
                              context.pushNamed(AccueilWidget.routeName),
                          child: const XpdLogo(
                            markSize: 38.0,
                            wordmarkSize: 22.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      if (_verificationSentTo != null)
                        _verificationNotice(palette)
                      else
                        _card(palette),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The post-sign-up state. Better Auth has mailed a link and there is no
  /// session yet, so this must not pretend the visitor is in.
  Widget _verificationNotice(XpdPalette palette) => XpdPanel(
        radius: 22.0,
        padding: const EdgeInsets.all(34.0),
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: palette.greenBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                color: palette.green,
                size: 24.0,
              ),
            ),
            const SizedBox(height: 22.0),
            Text(
              _t('Vérifiez votre boîte mail', 'Check your inbox'),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 26.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 26.0 * -0.03,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              _t(
                "Nous avons envoyé un lien de confirmation à $_verificationSentTo. Ouvrez-le pour activer votre compte, puis connectez-vous.",
                'We sent a confirmation link to $_verificationSentTo. Open it to activate your account, then sign in.',
              ),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.5,
                height: 1.6,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 26.0),
            XpdButton(
              label: _t('Aller à la connexion', 'Go to sign in'),
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              onPressed: () => context.pushNamed(SeConnecterWidget.routeName),
            ),
          ],
        ),
      );

  Widget _card(XpdPalette palette) => XpdPanel(
        radius: 22.0,
        padding: const EdgeInsets.all(34.0),
        elevated: true,
        child: Form(
          key: _model.formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('Créer un compte', 'Create an account'),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 30.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 30.0 * -0.03,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _t(
                  'Vos devis, vos bordereaux et vos livraisons au même endroit.',
                  'Your quotes, bordereaux and deliveries in one place.',
                ),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16.0,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 28.0),
              // French forms lead with the family name, English ones with the
              // given name, so the pair swaps over with the locale.
              _pair(
                _isEnglish ? _prenomField() : _nomField(),
                _isEnglish ? _nomField() : _prenomField(),
              ),
              const SizedBox(height: 18.0),
              XpdField(
                label: _t('Adresse email', 'Email address'),
                hint: _t('vous@exemple.fr', 'you@example.com'),
                controller: _model.emailTextController!,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return _t('Entrez votre email.', 'Enter your email.');
                  }
                  if (!RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$').hasMatch(text)) {
                    return _t(
                      'Cette adresse email est invalide.',
                      'That email address is not valid.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18.0),
              _pair(
                _password(
                  palette,
                  label: _t('Mot de passe', 'Password'),
                  controller: _model.motDePasseTextController!,
                  focusNode: _model.motDePasseFocusNode,
                  obscure: _obscure,
                  onToggle: () => setState(() => _obscure = !_obscure),
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) {
                      return _t(
                        'Choisissez un mot de passe.',
                        'Choose a password.',
                      );
                    }
                    if (text.length < 8) {
                      return _t(
                        'Au moins 8 caractères.',
                        'At least 8 characters.',
                      );
                    }
                    return null;
                  },
                ),
                _password(
                  palette,
                  label: _t('Confirmer', 'Confirm password'),
                  controller: _model.motDePasseConfirmeTextController!,
                  focusNode: _model.motDePasseConfirmeFocusNode,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) =>
                      value != _model.motDePasseTextController.text
                          ? _t(
                              'Les mots de passe ne correspondent pas.',
                              'The passwords do not match.',
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 30.0),
              _groupLabel(
                  palette, _t('ADRESSE DE FACTURATION', 'BILLING ADDRESS')),
              const SizedBox(height: 16.0),
              XpdField(
                label: _t('Adresse', 'Address'),
                controller: _model.textController4!,
              ),
              const SizedBox(height: 18.0),
              XpdField(
                label: _t("Complément d'adresse", 'Address line 2'),
                controller: _model.textController5!,
              ),
              const SizedBox(height: 18.0),
              _pair(
                XpdField(
                  label: _t('Code postal', 'Postcode'),
                  controller: _model.textController6!,
                ),
                XpdField(
                  label: _t('Ville', 'City'),
                  controller: _model.textController7!,
                ),
              ),
              const SizedBox(height: 18.0),
              _pair(
                XpdField(
                  label: _t('Pays', 'Country'),
                  controller: _model.textController8!,
                ),
                XpdField(
                  label: _t('Téléphone', 'Phone'),
                  controller: _model.textController9!,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 24.0),
              _toggleRow(
                palette,
                value: _sameDeliveryAddress,
                onChanged: (v) => setState(() => _sameDeliveryAddress = v),
                label: _t(
                  'Livrer à la même adresse',
                  'Deliver to the same address',
                ),
              ),
              if (!_sameDeliveryAddress) ...[
                const SizedBox(height: 30.0),
                _groupLabel(
                  palette,
                  _t('ADRESSE DE LIVRAISON', 'DELIVERY ADDRESS'),
                ),
                const SizedBox(height: 16.0),
                XpdField(
                  label: _t('Adresse', 'Address'),
                  controller: _model.textController10!,
                ),
                const SizedBox(height: 18.0),
                XpdField(
                  label: _t("Complément d'adresse", 'Address line 2'),
                  controller: _model.textController11!,
                ),
                const SizedBox(height: 18.0),
                _pair(
                  XpdField(
                    label: _t('Code postal', 'Postcode'),
                    controller: _model.textController12!,
                  ),
                  XpdField(
                    label: _t('Ville', 'City'),
                    controller: _model.textController13!,
                  ),
                ),
                const SizedBox(height: 18.0),
                _pair(
                  XpdField(
                    label: _t('Pays', 'Country'),
                    controller: _model.textController14!,
                  ),
                  XpdField(
                    label: _t('Téléphone', 'Phone'),
                    controller: _model.textController15!,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
              const SizedBox(height: 24.0),
              _termsRow(palette),
              if (_error != null) ...[
                const SizedBox(height: 18.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.red.withValues(alpha: 0.10),
                    border:
                        Border.all(color: palette.red.withValues(alpha: 0.32)),
                    borderRadius: BorderRadius.circular(11.0),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13.5,
                      height: 1.45,
                      color: palette.red,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22.0),
              XpdButton(
                label: _t('Créer un compte', 'Create account'),
                expand: true,
                busy: _busy,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                onPressed: _createAccount,
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(child: Container(height: 1.0, color: palette.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      _t('Ou continuer avec', 'Or continue with'),
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14.0,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1.0, color: palette.line)),
                ],
              ),
              const SizedBox(height: 24.0),
              // Google's own button on web — only it produces the ID token
              // Better Auth verifies. See the same note on the sign-in page.
              if (googleIdentityButtonSupported)
                Align(
                  alignment: Alignment.center,
                  child: LayoutBuilder(
                    builder: (context, constraints) => googleIdentityButton(
                      width: constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : null,
                    ),
                  ),
                )
              else
                _GoogleButton(
                  busy: _googleBusy,
                  label: _t("S'inscrire avec Google", 'Sign up with Google'),
                  onPressed: _signUpWithGoogle,
                ),
              const SizedBox(height: 26.0),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _t('Déjà un compte ? ', 'Already have an account? '),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14.5,
                      color: palette.muted,
                    ),
                  ),
                  XpdLink(
                    label: _t('Se connecter', 'Sign in'),
                    fontSize: 14.5,
                    weight: FontWeight.w600,
                    onTap: () => context.pushNamed(SeConnecterWidget.routeName),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? _t('Champ requis.', 'Required.') : null;

  Widget _nomField() => XpdField(
        label: _t('Nom', 'Last name'),
        controller: _model.nomTextController!,
        validator: _required,
      );

  Widget _prenomField() => XpdField(
        label: _t('Prénom', 'First name'),
        controller: _model.prenomTextController!,
        validator: _required,
      );

  Widget _pair(Widget a, Widget b) {
    final narrow = MediaQuery.sizeOf(context).width < 560.0;
    return narrow
        ? Column(children: [a, const SizedBox(height: 18.0), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 18.0),
              Expanded(child: b),
            ],
          );
  }

  Widget _groupLabel(XpdPalette palette, String text) => Row(
        children: [
          XpdEyebrow(text),
          const SizedBox(width: 12.0),
          Expanded(child: Container(height: 1.0, color: palette.line)),
        ],
      );

  Widget _password(
    XpdPalette palette, {
    required String label,
    required TextEditingController controller,
    required FocusNode? focusNode,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13.0,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            validator: validator,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.0,
              color: palette.text,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.input,
              hintText: '••••••••',
              hintStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.0,
                color: palette.faint,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 13.0,
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.0,
                  color: palette.muted,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.0),
                borderSide: BorderSide(color: palette.line2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.0),
                borderSide: const BorderSide(color: XpdPalette.blue),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.0),
                borderSide: BorderSide(color: palette.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.0),
                borderSide: BorderSide(color: palette.red),
              ),
            ),
          ),
        ],
      );

  Widget _toggleRow(
    XpdPalette palette, {
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) =>
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14.5,
                color: palette.soft,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: XpdPalette.blue,
            inactiveTrackColor: palette.chip,
          ),
        ],
      );

  Widget _termsRow(XpdPalette palette) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18.0,
                height: 18.0,
                margin: const EdgeInsets.only(top: 2.0),
                decoration: BoxDecoration(
                  color: _acceptedTerms ? XpdPalette.blue : Colors.transparent,
                  border: Border.all(
                    color: _acceptedTerms ? XpdPalette.blue : palette.line2,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: _acceptedTerms
                    ? const Icon(Icons.check_rounded,
                        size: 13.0, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  _t(
                    "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                    'I accept the terms of use and the privacy policy.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14.0,
                    height: 1.45,
                    color: palette.soft,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Same outline action as the login page's, kept local to avoid exporting a
/// button that only these two screens use.
class _GoogleButton extends StatefulWidget {
  const _GoogleButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 18.0),
          decoration: BoxDecoration(
            color: _hovered ? palette.chip : Colors.transparent,
            border: Border.all(color: palette.line2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy)
                SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.muted),
                  ),
                )
              else
                const GoogleGlyph(size: 20.0),
              const SizedBox(width: 12.0),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
