import 'package:flutter/material.dart';

import '/backend/geocoding/nominatim_geocoder.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_l10n.dart';
import 'ds_text_field.dart';
import 'ds_tokens.dart';

/// An address field that suggests real, geocodable addresses as the visitor
/// types — the same idea as Expeditoo's own admin search-and-pin map
/// (`location-picker-field.tsx`), minus the map: it queries the same
/// provider (Nominatim, France-only) and resolves the same shape of result,
/// but shows it as a dropdown rather than a draggable pin, since a
/// full interactive map on a phone form is a heavier and riskier build than
/// the address itself needs to be correct.
///
/// Picking a suggestion is the fast path: [onSelected] gets a
/// [GeocodeSuggestion] with the street line, city and postal code split out
/// and a lat/lng attached, which the caller can use to fill the sibling
/// fields and show a "position found" confirmation. Typing without picking
/// one is still a complete, valid entry — nothing here blocks free text, and
/// [controller] holds whatever is in the field either way. [onSelected] is
/// purely a client-side assist: coordinates are never sent to the Expedion
/// API from here, the server resolves and trusts its own copy once an
/// address is saved.
class DSAddressAutocomplete extends StatefulWidget {
  const DSAddressAutocomplete({
    super.key,
    required this.controller,
    required this.onSelected,
    this.label,
    this.hintText,
    this.helperText,
    this.validator,
    this.focusNode,
    this.isProgrammaticEdit,
  });

  final TextEditingController controller;
  final ValueChanged<GeocodeSuggestion> onSelected;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  /// Whether the edit arriving right now came from the owner rather than the
  /// keyboard — a pin dropped on the map, a restored draft.
  ///
  /// Without it every programmatic write reads as typing: a second Nominatim
  /// search fires for text nobody typed, and the suggestions overlay reopens
  /// over the address the map just filled in, offering stale alternatives that
  /// silently replace the pin if one is tapped.
  final bool Function()? isProgrammaticEdit;

  @override
  State<DSAddressAutocomplete> createState() => _DSAddressAutocompleteState();
}

class _DSAddressAutocompleteState extends State<DSAddressAutocomplete> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool get _ownsFocusNode => widget.focusNode == null;

  /// Retires a search whose keystroke has been superseded.
  int _searchToken = 0;

  /// The text the last search was started for, and what it found.
  ///
  /// `RawAutocomplete` rebuilds its options from *every* controller
  /// notification, and a controller notifies on selection and composing
  /// changes too — a caret move, a focus gain on a prefilled field, an IME
  /// composing update. Those are not new queries: searching again would put
  /// unthrottled traffic against Nominatim's rate limit, and retiring the
  /// pending search would blank the dropdown the visitor was reading.
  String? _lastQuery;
  List<GeocodeSuggestion> _lastResults = const [];

  @override
  void initState() {
    super.initState();
    // A field arriving with an address already in it — a restored draft, a
    // pin — has nothing to search for until somebody edits it.
    _lastQuery = widget.controller.text.trim();
  }

  @override
  void dispose() {
    // Retires any search still in flight, so its result cannot be applied to
    // a disposed state.
    _searchToken++;
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// Nominatim, debounced, as [RawAutocomplete]'s own options builder.
  ///
  /// It has to be the builder rather than a listener writing into a field:
  /// `RawAutocomplete` recomputes its options only when the field changes, so
  /// results that arrived *after* the last keystroke — which is every result,
  /// once a debounce is involved — never reached the overlay. The dropdown
  /// showed the previous query's hits, and showed nothing at all when the
  /// visitor stopped typing and waited, which is exactly when they were
  /// looking at it. `RawAutocomplete` already discards superseded async
  /// answers by call id; the token here also stops a disposed state from
  /// being touched.
  Future<Iterable<GeocodeSuggestion>> _search(TextEditingValue value) async {
    // A pin drop or a restored draft writes this field; neither is a search.
    if (widget.isProgrammaticEdit?.call() ?? false) {
      return const <GeocodeSuggestion>[];
    }

    final query = value.text.trim();
    if (query.length < 3) {
      _lastQuery = query;
      _lastResults = const [];
      return const <GeocodeSuggestion>[];
    }

    // Same text as last time: hand back what that search found rather than
    // starting — and retiring — another one.
    if (query == _lastQuery) return _lastResults;
    _lastQuery = query;

    final token = ++_searchToken;
    // Nominatim's usage policy caps unauthenticated callers at about one
    // request a second; this is what keeps a fast typist under that.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || token != _searchToken) return const <GeocodeSuggestion>[];

    final results = await NominatimGeocoder.search(query);
    if (!mounted || token != _searchToken) return const <GeocodeSuggestion>[];
    _lastResults = results;
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return RawAutocomplete<GeocodeSuggestion>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: _search,
      displayStringForOption: (option) => option.address,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return DSTextField(
          controller: controller,
          focusNode: focusNode,
          label: widget.label,
          hintText: widget.hintText,
          helperText: widget.helperText,
          validator: widget.validator,
          keyboardType: TextInputType.streetAddress,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      onSelected: (option) {
        // Retires the search this selection raced, so a late answer cannot
        // reopen the overlay over the address just chosen.
        _searchToken++;
        widget.onSelected(option);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(DSShape.control),
            color: theme.secondaryBackground,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 240.0, maxWidth: 480.0),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18.0,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              option.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall
                                  .override(color: theme.primaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small "position confirmed" indicator for below an address field once a
/// [GeocodeSuggestion] has been resolved — the lightweight stand-in for
/// looking at a pin on Expeditoo's admin map: not a map, but the same
/// reassurance that the address really does resolve to a point Expeditoo can
/// route a driver to.
class DSPositionConfirmedChip extends StatelessWidget {
  const DSPositionConfirmedChip({
    super.key,
    required this.suggestion,
  });

  final GeocodeSuggestion? suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final resolved = suggestion != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          resolved
              ? Icons.check_circle_outline_rounded
              : Icons.location_searching_rounded,
          size: 14.0,
          color: resolved ? theme.success : theme.secondaryText,
        ),
        const SizedBox(width: 6.0),
        Flexible(
          child: Text(
            resolved
                ? '${suggestion!.lat.toStringAsFixed(4)}, '
                    '${suggestion!.lng.toStringAsFixed(4)}'
                : xpdT(
                    context,
                    'Position non confirmée — choisissez une suggestion ou '
                        'continuez à saisir',
                    'Position not confirmed yet — pick a suggestion or keep '
                        'typing',
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      ],
    );
  }
}
