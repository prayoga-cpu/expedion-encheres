/// Where the Expeditoo backend lives.
///
/// One place, because two clients need the same answer: [ExpedionApi] for
/// quotes and [ExpeditooAuthClient] for sign-in, both served by the same
/// Next.js app.
///
/// Requiring `--dart-define=EXPEDION_API_BASE_URL=…` for the app to work at all
/// was the wrong default. `flutter run -d chrome` passes no defines, so every
/// screen that reads a quote failed with a build-flag error message — which
/// tells a developer what to type but tells a user nothing, and made the app
/// look broken on a plain checkout. The define is now an override, not a
/// prerequisite.
class ExpedionConfig {
  const ExpedionConfig._();

  /// Build-time override. Set this for a staging deployment, or to point a
  /// local client at a colleague's tunnel.
  static const String _override =
      String.fromEnvironment('EXPEDION_API_BASE_URL');

  /// Where `pnpm dev` serves expeditoo-ship, from `~/Code/expeditoo-ship`.
  static const String _localDefault = 'http://localhost:3000';

  /// The Vercel deployment.
  ///
  /// NOT the default right now. That deployment is stale — it answers
  /// `/api/health` but 404s every `/api/expedion/*` route, because it predates
  /// them — so pointing at it produces a working-looking app whose every quote
  /// call fails. Until it is rebuilt from `main`, both debug and release
  /// resolve to the local server.
  // ignore: unused_field
  static const String _vercelDeployment = 'https://expeditoo-rho.vercel.app';

  /// Resolved base URL, without a trailing slash.
  ///
  /// One line to flip back once the deployment is current: restore
  /// `kReleaseMode ? _vercelDeployment : _localDefault`. A `--dart-define`
  /// overrides this either way, so a staging build needs no code change.
  static String get baseUrl {
    final resolved = _override.isNotEmpty ? _override : _localDefault;
    return resolved.endsWith('/')
        ? resolved.substring(0, resolved.length - 1)
        : resolved;
  }

  /// True when the base URL came from a `--dart-define` rather than a default.
  /// Surfaced in error messages so a failure against an unexpected host is
  /// diagnosable without reading the build command.
  static bool get isOverridden => _override.isNotEmpty;

  /// Where the landing page's "Ouvrir Expeditoo" links point.
  ///
  /// The same host as the API, so the carrier-side link opens the instance this
  /// build actually talks to. Sending a visitor to the Vercel deployment while
  /// the app reads a local database would show them a different world.
  static String get expeditooWebUrl => baseUrl;

  /// The operator dashboard, served by Expeditoo's Next.js app.
  ///
  /// It is a different origin from the Flutter app, which is the whole reason
  /// it needs a link: typing `/admin/expedion` into the Flutter app hits
  /// Flutter's router, finds no such route, and falls through to the quote
  /// chooser — which looks like the page is missing rather than elsewhere.
  static String get adminDashboardUrl => '$baseUrl/admin/expedion';
}
