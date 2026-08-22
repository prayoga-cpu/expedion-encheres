import 'package:flutter/foundation.dart' show kReleaseMode;

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

  /// The Vercel deployment that serves the API in production.
  ///
  /// Was `expeditoo-rho.vercel.app`, which had gone stale: it answered
  /// `/api/health` but 404'd every `/api/expedion/*` route because it predated
  /// them. Both debug and release were pointed at localhost to avoid that trap,
  /// which then became a worse one — a deployed build asked a visitor's own
  /// machine for the API, and Chrome blocked it outright as a public page
  /// reaching into the loopback address space.
  ///
  /// This host answers `/api/expedion/quotes` with 401 rather than 404, which
  /// is how you tell a current deployment from a stale one: the route exists
  /// and is asking who you are.
  static const String _vercelDeployment =
      'https://expeditoo-ship-five.vercel.app';

  /// Resolved base URL, without a trailing slash.
  ///
  /// Release builds talk to the deployment; debug talks to `pnpm dev`, so a
  /// plain `flutter run -d chrome` works against a local backend with no flags.
  /// `--dart-define=EXPEDION_API_BASE_URL=…` overrides both, which is what a
  /// staging build or a tunnel uses.
  static String get baseUrl {
    final resolved = _override.isNotEmpty
        ? _override
        : (kReleaseMode ? _vercelDeployment : _localDefault);
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

  /// Where "Devenir transporteur" lands.
  ///
  /// It used to open [expeditooWebUrl] — the same page as the link directly
  /// above it in the footer — so the two links promised different things and
  /// did the same one. `/carrier/application` is the actual sign-up: signed
  /// out it redirects to `/signin?callbackUrl=/carrier/application`, so the
  /// link still resolves for a visitor who has no account yet.
  static String get carrierApplicationUrl => '$baseUrl/carrier/application';

  /// The operator dashboard, served by Expeditoo's Next.js app.
  ///
  /// It is a different origin from the Flutter app, which is the whole reason
  /// it needs a link: typing `/admin/expedion` into the Flutter app hits
  /// Flutter's router, finds no such route, and falls through to the quote
  /// chooser — which looks like the page is missing rather than elsewhere.
  static String get adminDashboardUrl => '$baseUrl/admin/expedion';
}
