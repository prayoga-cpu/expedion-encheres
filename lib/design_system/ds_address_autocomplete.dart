import 'dart:async';

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
  });

  final TextEditingController controller;
  final ValueChanged<GeocodeSuggestion> onSelected;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  @override
  State<DSAddressAutocomplete> createState() => _DSAddressAutocompleteState();
}

class _DSAddressAutocompleteState extends State<DSAddressAutocomplete> {
  Timer? _debounce;
  List<GeocodeSuggestion> _options = const [];
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    _debounce?.cancel();

    if (query.trim().length < 3) {
      if (_options.isNotEmpty) setState(() => _options = const []);
      return;
    }

    // Nominatim's usage policy caps unauthenticated callers at ~1 req/s;
    // debouncing keystrokes is what keeps a fast typist under that.
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await NominatimGeocoder.search(query);
      if (!mounted || widget.controller.text != query) return;
      setState(() => _options = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return RawAutocomplete<GeocodeSuggestion>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (_) => _options,
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
        _debounce?.cancel();
        setState(() => _options = const []);
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
