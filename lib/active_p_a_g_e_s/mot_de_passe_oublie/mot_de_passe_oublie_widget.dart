import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/design_system/ds_logo.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import 'mot_de_passe_oublie_model.dart';
export 'mot_de_passe_oublie_model.dart';

/// Password reset.
///
/// The same card as the login page, one field wide. The mail is sent by
/// Expeditoo's Better Auth (`/forget-password`), falling back to Firebase for
/// accounts that predate the migration.
///
/// The confirmation is deliberately the same whether or not the address is
/// known: telling a stranger "no such account" turns this form into a way to
/// enumerate who has one.
class MotDePasseOublieWidget extends StatefulWidget {
  const MotDePasseOublieWidget({super.key});

  static String routeName = 'Mot-de-passe-oublie';
  static String routePath = '/motDePasseOublie';

  @override
  State<MotDePasseOublieWidget> createState() => _MotDePasseOublieWidgetState();
}

class _MotDePasseOublieWidgetState extends State<MotDePasseOublieWidget> {
  late MotDePasseOublieModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _busy = false;
  String? _sentTo;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MotDePasseOublieModel());
    _model.emailRecuperationTextController ??= TextEditingController();
    _model.emailRecuperationFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool get _isEnglish =>
      FFLocalizations.of(context).languageCode.startsWith('en');

  String _t(String fr, String en) => _isEnglish ? en : fr;

  Future<void> _send() async {
    if (_busy) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    final email = _model.emailRecuperationTextController.text.trim();
    setState(() => _busy = true);

    await authManager.resetPassword(email: email, context: context);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _sentTo = email;
    });
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
                      XpdPanel(
                        radius: 22.0,
                        padding: const EdgeInsets.all(34.0),
                        elevated: true,
                        child: _sentTo == null
                            ? _form(palette)
                            : _confirmation(palette),
                      ),
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

  Widget _form(XpdPalette palette) => Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Mot de passe oublié', 'Forgot password'),
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
                'Entrez votre adresse email et nous vous enverrons un lien de réinitialisation.',
                'Enter your email address and we will send you a reset link.',
              ),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16.0,
                height: 1.55,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 28.0),
            XpdField(
              label: _t('Adresse email', 'Email address'),
              hint: _t('vous@exemple.fr', 'you@example.com'),
              controller: _model.emailRecuperationTextController!,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _send(),
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
            const SizedBox(height: 24.0),
            XpdButton(
              label: _t('Envoyer le lien', 'Send reset link'),
              expand: true,
              busy: _busy,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              onPressed: _send,
            ),
            const SizedBox(height: 24.0),
            Center(
              child: XpdLink(
                label: _t('Retour à la connexion', 'Back to sign in'),
                fontSize: 14.5,
                onTap: () => context.pushNamed(SeConnecterWidget.routeName),
              ),
            ),
          ],
        ),
      );

  Widget _confirmation(XpdPalette palette) => Column(
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
              "Si un compte existe pour $_sentTo, un lien de réinitialisation vient d'être envoyé. Pensez à regarder vos spams.",
              'If an account exists for $_sentTo, a reset link is on its way. Check your spam folder too.',
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
            label: _t('Retour à la connexion', 'Back to sign in'),
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            onPressed: () => context.pushNamed(SeConnecterWidget.routeName),
          ),
          const SizedBox(height: 16.0),
          Center(
            child: XpdLink(
              label: _t('Renvoyer le lien', 'Send it again'),
              fontSize: 14.0,
              onTap: () => setState(() => _sentTo = null),
            ),
          ),
        ],
      );
}
