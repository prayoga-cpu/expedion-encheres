/// Expedion ↔ Expeditoo shared design system.
///
/// Every widget here is a one-to-one Flutter port of its counterpart in
/// `expeditoo-ship/src/components/ui`. The colour, type and shape tokens they
/// consume live in `FlutterFlowTheme` (see `flutter_flow/flutter_flow_theme.dart`),
/// whose values are the hex equivalents of Expeditoo's canonical `oklch`
/// definitions in `globals.css`.
///
/// | Expedion            | Expeditoo                    |
/// |---------------------|------------------------------|
/// | `DSCard`            | `card.tsx`                   |
/// | `DSQuoteCard`       | `home/ui/ListingCard.tsx`    |
/// | `DSBadge`           | `badge.tsx`                  |
/// | `DSButton`          | `button.tsx`                 |
/// | `DSTextField`       | `input.tsx` + `label.tsx`    |
/// | `DSAddressPicker`   | `location-picker-field.tsx`  |
/// | `showDSSheet`       | `sheet.tsx`                  |
/// | `DSEmptyState`      | `centered-empty-state.tsx`   |
/// | `DSPageLoader`      | `page-loader.tsx`            |
/// | `DSSkeleton`        | `skeleton.tsx`               |
/// | `DSStepper`         | `Stepper.tsx`                |
/// | `DSSupportChat`     | `admin/support` + `messages` |
library;

// The site layer — the marketing page's own tokens, chrome and section
// primitives. `XpdPalette` carries the full colour set from the page's
// `applyTheme()`, of which `FlutterFlowTheme` mirrors the subset it has slots
// for; both resolve to the same values.
export 'ds_form_feedback.dart';
export 'ds_l10n.dart';
export 'ds_google_glyph.dart';
export 'ds_logo.dart';
export 'ds_palette.dart';
export 'ds_site.dart';
export 'ds_site_footer.dart';

// The component-parity layer, ported from `expeditoo-ship/src/components/ui`.
export 'ds_address_autocomplete.dart';
export 'ds_badge.dart';
export 'ds_button.dart';
export 'ds_card.dart';
export 'ds_empty_state.dart';
export 'ds_loader.dart';
export 'ds_location_picker.dart';
// `DSNavItem`, `DSSearchBar`, `DSSegmentedControl`, `DSNotificationBadge` —
// interior-page controls the site layer has no counterpart for yet.
export 'ds_navigation.dart';
export 'ds_quote_card.dart';
export 'ds_sheet.dart';
export 'ds_stepper.dart';
export 'ds_storage_countdown.dart';
export 'ds_support_chat.dart';
export 'ds_text_field.dart';
export 'ds_tokens.dart';

// Superseded by the site layer above: the landing page, header and footer are
// now `XpdSection` / `XpdHeader` / `XpdFooter`. Kept, and deliberately not
// re-exported, so a stale import fails loudly rather than quietly resolving to
// the old look. Delete once no branch needs them.
//   ds_marketing.dart  ds_top_nav.dart  ds_footer.dart
