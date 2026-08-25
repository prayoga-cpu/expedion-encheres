import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

/// The Google Identity Services button, rendered by Google itself.
///
/// On web this is not a style choice. `google_sign_in`'s `signIn()` uses the
/// OAuth implicit flow and yields only an access token, never an ID token —
/// the plugin says so itself, and warns that the method "is discouraged on the
/// web because it can't reliably provide an `idToken`". Better Auth's
/// `/sign-in/social` needs exactly that ID token, so the only supported way to
/// obtain one in a browser is `signInSilently` (the One Tap prompt, which the
/// visitor may never see) or this widget.
///
/// The credential does not come back through this call. GIS delivers it to the
/// plugin, which republishes it on `GoogleSignIn.onCurrentUserChanged`, so the
/// caller listens there rather than awaiting a result — see
/// `ExpedionAuthManager.googleWebSignIns`.
Widget googleIdentityButton({double? width}) => web_only.renderButton(
      configuration: web_only.GSIButtonConfiguration(
        // Matches the outline treatment the rest of the social row uses, so
        // Google's button sits in the same visual register as its neighbours
        // even though its interior is not ours to style.
        theme: web_only.GSIButtonTheme.outline,
        size: web_only.GSIButtonSize.large,
        text: web_only.GSIButtonText.continueWith,
        shape: web_only.GSIButtonShape.rectangular,
        logoAlignment: web_only.GSIButtonLogoAlignment.left,
        minimumWidth: width,
      ),
    );

/// True where [googleIdentityButton] renders a real, working control.
const bool googleIdentityButtonSupported = true;
