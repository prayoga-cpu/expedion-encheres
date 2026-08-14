import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/design_system/ds_google_glyph.dart';
import '/design_system/ds_logo.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import 'se_connecter_model.dart';
export 'se_connecter_model.dart';

/// Sign in.
///
/// The layout follows Expeditoo's own login screen so the two products read as
/// one company: the lockup centred above a single bordered card, the fields
/// labelled outside their inputs, "Forgot password?" aligned to the password
/// label, a remember-me checkbox, the filled action, a hairline "or continue
/// with" divider, the Google button, and the sign-up prompt underneath.
///
/// The brand is Expedion's — the current mark from the site, not the Expeditoo
/// cube — and the palette and type are the site's, so the page belongs to this
/// app while the shape is shared.
class SeConnecterWidget extends StatefulWidget {
  const SeConnecterWidget({super.key});

  static String routeName = 'SE-CONNECTER';
  static String routePath = '/seConnecter';

  @override
  State<SeConnecterWidget> createState() => _SeConnecterWidgetState();
}

class _SeConnecterWidgetState extends State<SeConnecterWidget> {
  late SeConnecterModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _obscure = true;
  bool _remember = true;
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SeConnecterModel());
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.motDePasseTextController ??= TextEditingController();
    _model.motDePasseFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool get _isEnglish =>
      FFLocalizations.of(context).languageCode.startsWith('en');

  String _t(String fr, String en) => _isEnglish ? en : fr;

  /// Turns Better Auth's failure codes into something a visitor can act on.
  /// Falling back to the server's own message keeps rate-limit and lockout
  /// responses readable instead of flattening everything to "wrong password".
  String _explain() {
    final result = authManager.lastExpeditooResult;
    if (result == null) {
      return _t(
        'Email ou mot de passe incorrect.',
        'Incorrect email or password.',
      );
    }
    if (result.needsEmailVerification) {
      return _t(
        "Vérifiez votre adresse email avant de vous connecter. Un lien vous a été envoyé.",
        'Confirm your email address before signing in. We sent you a link.',
      );
    }
    switch (result.code) {
      case 'INVALID_EMAIL_OR_PASSWORD':
      case 'INVALID_CREDENTIALS':
      case 'USER_NOT_FOUND':
        return _t(
          'Email ou mot de passe incorrect.',
          'Incorrect email or password.',
        );
      case 'NOT_CONFIGURED':
        return _t(
          "La connexion n'est pas disponible pour le moment.",
          'Sign-in is unavailable right now.',
        );
      default:
        return result.message ??
            _t('La connexion a échoué.', 'Sign-in failed.');
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithEmail(
      context,
      _model.emailTextController.text.trim(),
      _model.motDePasseTextController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (user == null) {
      setState(() => _error = _explain());
      return;
    }
    context.goNamedAuth(ChoixDevisWidget.routeName, context.mounted);
  }

  Future<void> _signInWithGoogle() async {
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
      // A cancelled Google sheet is not an error worth shouting about; only
      // report when the exchange itself failed.
      if (authManager.lastExpeditooResult?.succeeded == false) {
        setState(() => _error = _explain());
      }
      return;
    }
    context.goNamedAuth(ChoixDevisWidget.routeName, context.mounted);
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
            // The soft blue wash behind the card, as on the reference screen.
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
                  constraints: const BoxConstraints(maxWidth: 460.0),
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
                _t('Bon retour', 'Welcome back'),
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
                  'Connectez-vous à votre compte EXPEDION',
                  'Sign in to your EXPEDION account',
                ),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16.0,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 28.0),
              XpdField(
                label: _t('Adresse email', 'Email address'),
                hint: 'vous@exemple.fr',
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
              // "Forgot password?" sits on the password label's row.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t('Mot de passe', 'Password'),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13.0,
                      color: palette.muted,
                    ),
                  ),
                  XpdLink(
                    label: _t('Mot de passe oublié ?', 'Forgot password?'),
                    fontSize: 13.0,
                    onTap: () =>
                        context.pushNamed(MotDePasseOublieWidget.routeName),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              _passwordField(palette),
              const SizedBox(height: 18.0),
              _rememberMe(palette),
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
                label: _t('Se connecter', 'Sign In'),
                expand: true,
                busy: _busy,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                onPressed: _signIn,
              ),
              const SizedBox(height: 24.0),
              _divider(palette),
              const SizedBox(height: 24.0),
              _googleButton(palette),
              const SizedBox(height: 26.0),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _t("Pas encore de compte ? ", "Don't have an account? "),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14.5,
                      color: palette.muted,
                    ),
                  ),
                  XpdLink(
                    label: _t("S'inscrire", 'Sign up'),
                    fontSize: 14.5,
                    weight: FontWeight.w600,
                    onTap: () => context.pushNamed(SInscrireWidget.routeName),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _passwordField(XpdPalette palette) => TextFormField(
        controller: _model.motDePasseTextController,
        focusNode: _model.motDePasseFocusNode,
        obscureText: _obscure,
        onFieldSubmitted: (_) => _signIn(),
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 15.0,
          color: palette.text,
        ),
        validator: (value) => (value ?? '').isEmpty
            ? _t('Entrez votre mot de passe.', 'Enter your password.')
            : null,
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
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20.0,
              color: palette.muted,
            ),
            tooltip: _obscure ? _t('Afficher', 'Show') : _t('Masquer', 'Hide'),
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
      );

  /// Better Auth's session lasts seven days, which is what this promises.
  Widget _rememberMe(XpdPalette palette) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _remember = !_remember),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: _remember ? XpdPalette.blue : Colors.transparent,
                  border: Border.all(
                    color: _remember ? XpdPalette.blue : palette.line2,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: _remember
                    ? const Icon(Icons.check_rounded,
                        size: 13.0, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10.0),
              Text(
                _t('Rester connecté 7 jours', 'Remember me for 7 days'),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14.0,
                  color: palette.soft,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _divider(XpdPalette palette) => Row(
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
      );

  Widget _googleButton(XpdPalette palette) => _OutlineActionButton(
        busy: _googleBusy,
        onPressed: _signInWithGoogle,
        icon: const GoogleGlyph(size: 20.0),
        label: _t('Se connecter avec Google', 'Sign in with Google'),
      );
}

/// A full-width outline button with a leading glyph — the social action.
class _OutlineActionButton extends StatefulWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool busy;

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
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
                widget.icon,
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
