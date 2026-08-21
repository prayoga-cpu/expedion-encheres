import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '/backend/geocoding/nominatim_geocoder.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_address_autocomplete.dart';
import 'ds_l10n.dart';
import 'ds_text_field.dart';
import 'ds_tokens.dart';

/// The Flutter port of `expeditoo-ship/src/components/ui/location-picker-field.tsx`
/// — one postal address plus the point a driver is routed to, entered either
/// way round: type it and the map follows, or drop the pin and the lines fill
/// themselves.
///
/// Same mechanism as the admin picker it is scraped from: Nominatim forward
/// search on the text, a draggable pin, Nominatim reverse geocoding on every
/// drop, France-only throughout. Two deliberate differences:
///
///  * the admin's in-map search box is gone, because the address line above
///    the map is already a search box ([DSAddressAutocomplete]) and two of
///    them in one field group is a trap, not a convenience;
///  * scroll-wheel zoom is off. This map lives halfway down a long form, and a
///    wheel that zooms the map instead of scrolling the page is the single
///    most complained-about behaviour of an embedded map. The `+` / `−`
///    buttons and pinch still zoom.
///
/// The coordinates never leave the client: `POST /api/expedion/quotes` has no
/// lat/lng in its schema (`createExpedionQuoteSchema`) and the server resolves
/// and trusts its own copy once the address is saved
/// (`expedionService.geocodeMissingCoordinates`). What this widget is *for* is
/// catching, at entry time, the address that will not geocode — the one that
/// would otherwise leave the quote stuck behind `escalationBlockers`'
/// "pickup coordinates" / "delivery coordinates" until an operator noticed.

// ============================================================================
// Basemap
// ============================================================================

/// CARTO's monochrome raster basemaps, which are what
/// `expeditoo-ship/public/map-styles/{light,dark}.json` describe in vector
/// form — the same grey land / darker water look, on a keyless endpoint a
/// Flutter raster [TileLayer] can read directly.
///
/// Attribution below the map is a condition of using them, exactly as on the
/// Expeditoo side. To move to a keyed provider (MapTiler, Stadia) later, these
/// two URLs and the attribution string are the whole change.
const String _kTileUrlLight =
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
const String _kTileUrlDark =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const List<String> _kTileSubdomains = ['a', 'b', 'c', 'd'];
const String _kAttribution = '© OpenStreetMap · © CARTO';

/// Required by Nominatim's usage policy and good manners on the tile CDN.
const String _kUserAgentPackage = 'com.expedion.encheres';

/// France, as `location-picker-field.tsx` bounds it.
final LatLngBounds _kFranceBounds = LatLngBounds(
  const LatLng(41.3, -5.5),
  const LatLng(51.1, 9.6),
);
const LatLng _kFranceCenter = LatLng(46.6, 2.35);
const double _kFranceZoom = 4.8;
const double _kPinnedZoom = 15.0;
const double _kMinZoom = 4.0;

/// How far inside the viewport a dragged pin is held.
const double _kDragMargin = 16.0;
const double _kMaxZoom = 18.0;

// ============================================================================
// Value
// ============================================================================

/// How far an address has got towards being routable.
enum DSAddressStatus {
  /// Nothing typed yet.
  empty,

  /// Some of the three lines are filled, so there is nothing to look up yet.
  incomplete,

  /// A forward or reverse lookup is in flight.
  checking,

  /// Resolved to a point — by picking a suggestion, by the automatic lookup,
  /// or by dropping the pin.
  confirmed,

  /// All three lines are filled and Nominatim knows nothing about them.
  notFound,

  /// [notFound], and the visitor said to use it anyway — or a pin was dropped
  /// somewhere with no street address behind it. The coordinates or the typed
  /// lines stand on the visitor's word.
  accepted,
}

/// A missing piece of an address, for a form that wants to list what is left.
enum DSAddressGap { address, postalCode, city, position }

/// The two lookups [DSAddressValue] performs, as function types so a test can
/// supply its own and drive the state machine deterministically instead of
/// waiting on a live Nominatim.
typedef DSForwardGeocode = Future<GeocodeSuggestion?> Function({
  required String address,
  required String postalCode,
  required String city,
});
typedef DSReverseGeocode = Future<GeocodeSuggestion?> Function(
  double lat,
  double lng,
);

/// The three address lines and the point they resolve to, kept together
/// because every one of them can change the others: picking a suggestion
/// fills the postcode, dropping a pin rewrites the street, editing the street
/// invalidates the pin.
///
/// Owns its own lookups. A form holds one per address, listens for changes,
/// and reads [gaps] to decide whether it can be submitted.
class DSAddressValue extends ChangeNotifier {
  DSAddressValue({
    DSForwardGeocode? forwardGeocode,
    DSReverseGeocode? reverseGeocode,
  })  : _forwardGeocode = forwardGeocode ?? NominatimGeocoder.resolve,
        _reverseGeocode = reverseGeocode ?? NominatimGeocoder.reverse {
    // Eagerly, not `late`: a lazy initialiser would run on its first read,
    // which is inside `_onEdited` — i.e. after the first edit had already
    // landed — and that edit would compare equal to itself and be ignored.
    _lastText = _textSnapshot;
    for (final controller in [address, postalCode, city]) {
      controller.addListener(_onEdited);
    }
  }

  final DSForwardGeocode _forwardGeocode;
  final DSReverseGeocode _reverseGeocode;

  final TextEditingController address = TextEditingController();
  final TextEditingController postalCode = TextEditingController();
  final TextEditingController city = TextEditingController();

  LatLng? _point;
  DSAddressStatus _status = DSAddressStatus.empty;

  Timer? _debounce;

  /// Bumped on every lookup so a slow answer to an old address cannot land on
  /// a new one.
  int _generation = 0;

  /// Set while this class is the one writing the controllers, so filling the
  /// city from a suggestion does not read as the visitor editing it.
  bool _applying = false;

  /// The three lines as they were at the last real edit. Assigned in the
  /// constructor.
  ///
  /// A [TextEditingController] notifies on any change to its value, and the
  /// selection is part of that value: focusing a field is enough, because
  /// `controller.text = ...` leaves the selection at offset -1 and
  /// `EditableText` repairs it on focus gain. Without this snapshot, tapping
  /// into a line that a pin had just filled read as an edit and threw the pin
  /// away before the visitor typed anything.
  String _lastText = '';

  String get _textSnapshot =>
      '${address.text}\u0000${postalCode.text}\u0000${city.text}';
  bool _disposed = false;

  LatLng? get point => _point;
  DSAddressStatus get status => _status;

  /// True while this object is the one writing the controllers. A field
  /// listening to the same controllers — the address autocomplete — uses it to
  /// tell a pin drop apart from a keystroke.
  bool get isApplying => _applying;

  /// Exactly five digits once separators are dropped — the shape
  /// `normalisePostalCode` requires server-side before a quote can publish
  /// (`expedion-escalation.service.ts`).
  static bool isPostalCode(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '').length == 5;

  bool get _hasCompleteText =>
      address.text.trim().isNotEmpty &&
      city.text.trim().isNotEmpty &&
      isPostalCode(postalCode.text);

  bool get isEmpty =>
      address.text.trim().isEmpty &&
      postalCode.text.trim().isEmpty &&
      city.text.trim().isEmpty;

  /// The address has a point behind it, or the visitor has said to go ahead
  /// without one.
  bool get isLocated =>
      _status == DSAddressStatus.confirmed ||
      _status == DSAddressStatus.accepted;

  /// Everything still missing before this address can be sent.
  Set<DSAddressGap> get gaps => {
        if (address.text.trim().isEmpty) DSAddressGap.address,
        if (!isPostalCode(postalCode.text)) DSAddressGap.postalCode,
        if (city.text.trim().isEmpty) DSAddressGap.city,
        if (!isLocated) DSAddressGap.position,
      };

  // --------------------------------------------------------------------------
  // Editing
  // --------------------------------------------------------------------------

  void _onEdited() {
    if (_applying) return;

    // A caret move, a focus gain, a selection repair — same text, no edit.
    final snapshot = _textSnapshot;
    if (snapshot == _lastText) return;
    _lastText = snapshot;

    // Any lookup already in flight was asked about the *old* text. Retiring
    // the generation here is what stops its answer landing on this edit —
    // without it a reverse geocode that started before the keystroke would
    // come back, overwrite the line being typed and mark the address
    // `confirmed` even though the point below has just been dropped.
    _generation++;

    // A point belongs to the text that produced it. Editing any line drops it
    // rather than letting a stale confirmation survive the edit.
    _point = null;
    _status = _statusForText();
    _scheduleResolve();
    notifyListeners();
  }

  DSAddressStatus _statusForText() {
    if (isEmpty) return DSAddressStatus.empty;
    if (!_hasCompleteText) return DSAddressStatus.incomplete;
    return DSAddressStatus.checking;
  }

  /// Nominatim's usage policy caps unauthenticated callers at about one
  /// request a second; the delay is what keeps a fast typist under that.
  void _scheduleResolve() {
    _debounce?.cancel();
    if (!_hasCompleteText) return;
    _debounce = Timer(const Duration(milliseconds: 900), resolveNow);
  }

  /// Looks the typed address up now. Safe to call at any time — it no-ops
  /// unless all three lines are filled.
  Future<void> resolveNow() async {
    if (_disposed || !_hasCompleteText) return;

    final generation = ++_generation;
    _debounce?.cancel();
    _status = DSAddressStatus.checking;
    notifyListeners();

    final hit = await _forwardGeocode(
      address: address.text,
      postalCode: postalCode.text,
      city: city.text,
    );
    if (_disposed || generation != _generation) return;

    // Only the coordinates are taken. What the visitor typed is left exactly
    // as typed — the bordereau's spelling of an address is often the one the
    // auction house will recognise on the phone.
    if (hit == null) {
      _status = DSAddressStatus.notFound;
    } else {
      _point = LatLng(hit.lat, hit.lng);
      _status = DSAddressStatus.confirmed;
    }
    notifyListeners();
  }

  /// The visitor picked a suggestion out of the address field's dropdown.
  void applySuggestion(GeocodeSuggestion suggestion) {
    _debounce?.cancel();
    _generation++;
    // Forced, blanks included — for the same reason `pin` forces them. A
    // suggestion for a hamlet often carries no postcode, and the previous
    // town's surviving next to the new one is a five-digit postcode from
    // another department that `normalisePostalCode` will happily accept.
    _write(
      postalCode: suggestion.postalCode,
      city: suggestion.city,
      force: true,
    );
    _point = LatLng(suggestion.lat, suggestion.lng);
    _status = DSAddressStatus.confirmed;
    notifyListeners();
  }

  /// The visitor tapped or dragged the pin. Reverse geocodes it and fills the
  /// three lines from the result, which is the whole point of the map: an
  /// address you can put your finger on but not spell.
  Future<void> pin(LatLng dropped) async {
    if (_disposed) return;

    final generation = ++_generation;
    _debounce?.cancel();
    _point = dropped;
    _status = DSAddressStatus.checking;
    notifyListeners();

    final hit = await _reverseGeocode(dropped.latitude, dropped.longitude);
    if (_disposed || generation != _generation) return;

    if (hit == null) {
      // A real point with nothing addressable behind it — a field, a car park.
      // The coordinates stand and the typed lines are left alone.
      _status = DSAddressStatus.accepted;
    } else {
      // The street is a suggestion: an empty one leaves whatever the visitor
      // typed alone, because a bordereau's spelling often beats the map's.
      _write(address: hit.address);

      // The town and postcode travel together. Forcing them — blanks included
      // — is right only when the pin has actually moved to a different
      // commune, which is the case where keeping the old postcode produces
      // "75009 Fontainebleau". Nudging the pin within the same town must not
      // blank a postcode the visitor typed correctly, so that case falls back
      // to the blank-skip.
      final movedTown = hit.city.trim().isNotEmpty &&
          hit.city.trim().toLowerCase() != city.text.trim().toLowerCase();
      _write(
        postalCode: hit.postalCode,
        city: hit.city,
        force: movedTown,
      );
      _status = DSAddressStatus.confirmed;
    }
    notifyListeners();
  }

  /// "Use it anyway" — the escape hatch for an address Nominatim does not
  /// know but the visitor does. Without it, a rural pickup could be
  /// unsubmittable, which is a worse failure than an unverified one.
  void acceptUnverified() {
    if (_status != DSAddressStatus.notFound) return;
    _status = DSAddressStatus.accepted;
    notifyListeners();
  }

  /// Refills from a saved draft without re-running any lookup.
  void restore({
    String address = '',
    String postalCode = '',
    String city = '',
    double? lat,
    double? lng,
    bool accepted = false,
  }) {
    _debounce?.cancel();
    _generation++;
    _write(address: address, postalCode: postalCode, city: city, force: true);
    _point = (lat == null || lng == null) ? null : LatLng(lat, lng);
    // `accepted` first: a pin whose reverse lookup found nothing is saved with
    // *both* a point and the flag, and reading the point alone would bring it
    // back claiming "Position confirmée" for a position nothing ever
    // confirmed — dropping the one warning an operator still has to act on.
    _status = accepted
        ? DSAddressStatus.accepted
        : (_point != null
            ? DSAddressStatus.confirmed
            : _statusForText());
    // A draft saved before its address resolved comes back with three full
    // lines and no point, which `_statusForText` reads as `checking`. Nothing
    // else would ever schedule that lookup — `_write` above ran under
    // `_applying`, so it woke no listener — and the address would sit
    // "Vérification…" for ever with Submit disabled. Ask again instead.
    if (_status == DSAddressStatus.checking) _scheduleResolve();
    notifyListeners();
  }

  /// Writes the controllers without the write reading back as an edit.
  /// Blank incoming values leave the existing line alone unless [force].
  void _write({
    String? address,
    String? postalCode,
    String? city,
    bool force = false,
  }) {
    _applying = true;
    void set(TextEditingController controller, String? value) {
      if (value == null) return;
      if (!force && value.trim().isEmpty) return;
      if (controller.text == value) return;
      controller.text = value;
    }

    set(this.address, address);
    set(this.postalCode, postalCode);
    set(this.city, city);
    _applying = false;
    _lastText = _textSnapshot;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    for (final controller in [address, postalCode, city]) {
      controller.removeListener(_onEdited);
      controller.dispose();
    }
    super.dispose();
  }
}

// ============================================================================
// Picker
// ============================================================================

/// An address block: the three lines, the map, and a line saying where the
/// address has got to. Drives a [DSAddressValue] and rebuilds with it.
class DSAddressPicker extends StatefulWidget {
  const DSAddressPicker({
    super.key,
    required this.value,
    required this.addressLabel,
    required this.postalCodeLabel,
    required this.cityLabel,
    this.addressHint,
    this.mapHeight,
  });

  final DSAddressValue value;
  final String addressLabel;
  final String postalCodeLabel;
  final String cityLabel;
  final String? addressHint;

  /// Overrides the responsive default (200px on a phone, 260px above 600px).
  final double? mapHeight;

  @override
  State<DSAddressPicker> createState() => _DSAddressPickerState();
}

class _DSAddressPickerState extends State<DSAddressPicker> {
  @override
  void initState() {
    super.initState();
    widget.value.addListener(_onValueChanged);
  }

  @override
  void didUpdateWidget(covariant DSAddressPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      oldWidget.value.removeListener(_onValueChanged);
      widget.value.addListener(_onValueChanged);
    }
  }

  @override
  void dispose() {
    widget.value.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    if (mounted) setState(() {});
  }

  String _t(String fr, String en) => xpdT(context, fr, en);

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? _t('Champ obligatoire', 'Required') : null;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSAddressAutocomplete(
          controller: value.address,
          label: widget.addressLabel,
          hintText: widget.addressHint,
          // Just the field's own job: the status line under the map is what
          // offers the pin, and saying it twice in one block reads as two
          // different instructions.
          helperText: _t(
            'Commencez à taper pour choisir une adresse reconnue.',
            'Start typing to pick a recognised address.',
          ),
          validator: _required,
          onSelected: value.applySuggestion,
          isProgrammaticEdit: () => value.isApplying,
        ),
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DSTextField(
                controller: value.postalCode,
                label: widget.postalCodeLabel,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                mono: true,
                validator: (input) {
                  final missing = _required(input);
                  if (missing != null) return missing;
                  return DSAddressValue.isPostalCode(input!)
                      ? null
                      : _t('Code postal à 5 chiffres', '5-digit postcode');
                },
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              flex: 2,
              child: DSTextField(
                controller: value.city,
                label: widget.cityLabel,
                validator: _required,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        DSLocationMap(
          point: value.point,
          busy: value.status == DSAddressStatus.checking,
          height: widget.mapHeight,
          onPinned: value.pin,
        ),
        const SizedBox(height: 8.0),
        _statusLine(context),
      ],
    );
  }

  Widget _statusLine(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final value = widget.value;

    final (IconData icon, Color color, String text) = switch (value.status) {
      DSAddressStatus.empty => (
          Icons.location_searching_rounded,
          theme.secondaryText,
          _t(
            "Saisissez l'adresse ou placez le point sur la carte.",
            'Type the address, or drop the pin on the map.',
          ),
        ),
      DSAddressStatus.incomplete => (
          Icons.location_searching_rounded,
          theme.secondaryText,
          _t(
            'Complétez adresse, code postal et ville pour vérifier la '
                'position.',
            'Fill in address, postcode and town to check the position.',
          ),
        ),
      DSAddressStatus.checking => (
          Icons.sync_rounded,
          theme.secondaryText,
          _t("Vérification de l'adresse…", 'Checking the address…'),
        ),
      DSAddressStatus.confirmed => (
          Icons.check_circle_outline_rounded,
          theme.success,
          _t(
            'Position confirmée — ${_coordinates(value.point)}',
            'Position confirmed — ${_coordinates(value.point)}',
          ),
        ),
      DSAddressStatus.notFound => (
          Icons.error_outline_rounded,
          theme.warning,
          _t(
            'Adresse non reconnue — placez le point sur la carte',
            'Address not recognised — drop the pin on the map',
          ),
        ),
      DSAddressStatus.accepted => (
          Icons.edit_location_alt_outlined,
          theme.secondaryText,
          _t(
            'Position non vérifiée — nous la contrôlerons de notre côté.',
            'Position unverified — we will check it on our side.',
          ),
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14.0, color: color),
        const SizedBox(width: 6.0),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(color: color),
          ),
        ),
        if (value.status == DSAddressStatus.notFound)
          TextButton(
            onPressed: value.acceptUnverified,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              minimumSize: const Size(0.0, 28.0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _t('utiliser quand même', 'use it anyway'),
              style: theme.labelSmall.override(color: theme.primary),
            ),
          ),
      ],
    );
  }

  static String _coordinates(LatLng? point) => point == null
      ? '—'
      : '${point.latitude.toStringAsFixed(4)}, '
          '${point.longitude.toStringAsFixed(4)}';
}

// ============================================================================
// Map
// ============================================================================

/// The map half of the picker: tap to drop the pin, drag the pin to correct
/// it, `+` / `−` to zoom. Every drop reports one [LatLng] through [onPinned];
/// what to do with it — reverse geocode, fill the lines — is the caller's.
class DSLocationMap extends StatefulWidget {
  const DSLocationMap({
    super.key,
    required this.point,
    required this.onPinned,
    this.busy = false,
    this.height,
  });

  final LatLng? point;
  final ValueChanged<LatLng> onPinned;

  /// A lookup is in flight for [point] — shown as a chip over the map.
  final bool busy;
  final double? height;

  @override
  State<DSLocationMap> createState() => _DSLocationMapState();
}

class _DSLocationMapState extends State<DSLocationMap> {
  final MapController _controller = MapController();

  /// Built once, and disposed by [TileLayer] rather than here.
  ///
  /// `TileLayer` disposes the provider it is handed in its own `dispose`
  /// (`tile_layer.dart`) and nowhere else — not when the instance changes. So
  /// constructing one inside `build` would abandon a `RetryClient`, and its
  /// in-flight tile requests, on every rebuild, and this map rebuilds on every
  /// keystroke in the address field above it. Holding one for the widget's
  /// life is the fix; disposing it here as well would be a second call on an
  /// object the layer already closed.
  final TileProvider _tileProvider = NetworkTileProvider();

  /// Where the pin is while a drag is in progress, before it is reported.
  LatLng? _dragPoint;

  /// True between the first pan update and the drop. While it is set, a
  /// rebuild from the parent must not pull [_dragPoint] out from under the
  /// finger; once it is clear, the parent's point is the only truth.
  bool _dragging = false;

  /// The last point this map itself produced. The camera follows [widget.point]
  /// when it changes from the outside — a suggestion picked, a draft restored
  /// — but not when the change is the visitor's own tap or drag, which would
  /// yank the map out from under their finger.
  LatLng? _selfEmitted;

  bool _ready = false;

  LatLng? get _shownPoint => _dragPoint ?? widget.point;

  @override
  void didUpdateWidget(covariant DSLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A finished drag hands over to the parent, whatever it decided — even
    // if it decided on the same point, which the old equality shortcut read as
    // "nothing happened" and left `_dragPoint` set for ever. The next external
    // change then drew the pin at the stale drag position while the camera
    // flew somewhere else.
    if (!_dragging && _dragPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dragging) setState(() => _dragPoint = null);
      });
    }

    final point = widget.point;
    if (point == null || point == oldWidget.point) return;
    if (point == _selfEmitted) return;
    if (_ready) _controller.move(point, _kPinnedZoom);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _ready = true;
    // A point resolved between the first build and here — a fast suggestion, a
    // restored draft — missed [MapOptions.initialCenter], which is read once.
    final point = widget.point;
    if (point != null && point != _selfEmitted) {
      _controller.move(point, _kPinnedZoom);
    }
  }

  void _emit(LatLng point) {
    _selfEmitted = point;
    widget.onPinned(point);
  }

  /// Keeps a dragged pin [_kDragMargin] pixels clear of the viewport edge.
  static double _inside(double value, double extent) {
    final limit = math.max(_kDragMargin, extent - _kDragMargin);
    return value.clamp(math.min(_kDragMargin, limit), limit);
  }

  void _commitDrag() {
    _dragging = false;
    final dropped = _dragPoint;
    if (dropped != null) _emit(dropped);
  }

  void _zoomBy(double delta) {
    if (!_ready) return;
    final camera = _controller.camera;
    _controller.move(
      camera.center,
      (camera.zoom + delta).clamp(_kMinZoom, _kMaxZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = widget.height ??
        (MediaQuery.sizeOf(context).width < 600.0 ? 200.0 : 260.0);
    final point = _shownPoint;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DSShape.control),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSShape.control),
          border: Border.all(
            color: theme.alternate,
            width: DSShape.borderWidth,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: widget.point ?? _kFranceCenter,
                  initialZoom:
                      widget.point == null ? _kFranceZoom : _kPinnedZoom,
                  minZoom: _kMinZoom,
                  maxZoom: _kMaxZoom,
                  backgroundColor: theme.secondaryBackground,
                  cameraConstraint:
                      CameraConstraint.containCenter(bounds: _kFranceBounds),
                  interactionOptions: const InteractionOptions(
                    // No wheel zoom (the page has to stay scrollable) and no
                    // rotation (a rotated address map helps nobody).
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onMapReady: _onMapReady,
                  onTap: (_, tapped) => _emit(tapped),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark ? _kTileUrlDark : _kTileUrlLight,
                    subdomains: _kTileSubdomains,
                    retinaMode: RetinaMode.isHighDensity(context),
                    userAgentPackageName: _kUserAgentPackage,
                    tileProvider: _tileProvider,
                  ),
                  if (point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 44.0,
                          height: 44.0,
                          // The pin's tip, not its middle, is the address.
                          alignment: Alignment.topCenter,
                          child: _draggablePin(theme),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            _attribution(theme),
            _zoomControls(theme),
            _hint(theme, point),
          ],
        ),
      ),
    );
  }

  Widget _draggablePin(FlutterFlowTheme theme) {
    return _DraggablePin(
      // A context below FlutterMap, so `MapCamera.of` can convert the drag's
      // pixels into degrees.
      onDragUpdate: (mapContext, delta) {
        final anchor = _shownPoint;
        if (anchor == null) return;
        final camera = MapCamera.of(mapContext);
        final moved = camera.latLngToScreenOffset(anchor) + delta;
        // Held a margin inside the viewport, in pixels rather than in
        // degrees: `MarkerLayer` culls a marker whose pixel bounds have left
        // the camera, which would take this gesture detector out of the tree
        // mid-drag. Clamping to the exact edge is not enough: the edge *is*
        // the cull threshold.
        final size = camera.size;
        setState(() => _dragPoint = camera.screenOffsetToLatLng(Offset(
              _inside(moved.dx, size.width),
              _inside(moved.dy, size.height),
            )));
      },
      onDragStart: () => _dragging = true,
      onDragEnd: _commitDrag,
      child: Icon(
        Icons.location_on,
        size: 40.0,
        color: theme.primary,
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 6.0),
        ],
      ),
    );
  }

  Widget _zoomControls(FlutterFlowTheme theme) {
    Widget button(IconData icon, double delta, String tooltip) => Material(
          color: theme.secondaryBackground.withValues(alpha: 0.92),
          child: InkWell(
            onTap: () => _zoomBy(delta),
            child: Tooltip(
              message: tooltip,
              child: SizedBox(
                width: 32.0,
                height: 32.0,
                child: Icon(icon, size: 18.0, color: theme.primaryText),
              ),
            ),
          ),
        );

    return Positioned(
      right: 8.0,
      bottom: 8.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSShape.small),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.alternate,
              width: DSShape.borderWidth,
            ),
            borderRadius: BorderRadius.circular(DSShape.small),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(
                  Icons.add_rounded, 1.0, xpdT(context, 'Zoomer', 'Zoom in')),
              Container(height: 1.0, width: 32.0, color: theme.alternate),
              button(Icons.remove_rounded, -1.0,
                  xpdT(context, 'Dézoomer', 'Zoom out')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attribution(FlutterFlowTheme theme) => Positioned(
        left: 6.0,
        bottom: 6.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.secondaryBackground.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(DSShape.small),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Text(
              _kAttribution,
              style: theme.labelSmall.override(
                color: theme.secondaryText,
                fontSize: 9.0,
              ),
            ),
          ),
        ),
      );

  /// The one-line prompt over the map: what to do, or what is happening.
  Widget _hint(FlutterFlowTheme theme, LatLng? point) {
    final String? message = widget.busy
        ? xpdT(context, "Recherche de l'adresse…", 'Looking up the address…')
        : point == null
            ? xpdT(
                context,
                'Touchez la carte pour placer le point',
                'Tap the map to drop the pin',
              )
            : null;
    if (message == null) return const SizedBox.shrink();

    return Positioned(
      top: 8.0,
      left: 0.0,
      right: 0.0,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.secondaryBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(DSShape.pill),
            border: Border.all(
              color: theme.alternate,
              width: DSShape.borderWidth,
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.busy) ...[
                  SizedBox(
                    width: 10.0,
                    height: 10.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                ],
                Text(
                  message,
                  style: theme.labelSmall.override(color: theme.primaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pin, as its own widget so that losing it ends the drag.
///
/// The clamp in [_DSLocationMapState] keeps a *dragged* pin inside the
/// viewport, but the camera can move underneath it — a second finger panning
/// the map is enough — and `MarkerLayer` then culls the marker, unmounts this
/// widget and disposes its recogniser without ever calling `onPanEnd` or
/// `onPanCancel`. Ending the drag from [dispose] is the only notification that
/// survives that, and without it the drag state latches: the map would ignore
/// every later update for the life of the page.
class _DraggablePin extends StatefulWidget {
  const _DraggablePin({
    required this.child,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Widget child;
  final VoidCallback onDragStart;
  final void Function(BuildContext mapContext, Offset delta) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_DraggablePin> createState() => _DraggablePinState();
}

class _DraggablePinState extends State<_DraggablePin> {
  bool _dragging = false;

  void _start() {
    _dragging = true;
    widget.onDragStart();
  }

  void _end() {
    if (!_dragging) return;
    _dragging = false;
    widget.onDragEnd();
  }

  @override
  void dispose() {
    // Culled mid-drag: commit what the visitor had, rather than leaving the
    // map holding a drag that can never finish.
    _end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          _PinPanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_PinPanGestureRecognizer>(
            () => _PinPanGestureRecognizer(debugOwner: this),
            (instance) {
              instance.onStart = (_) => _start();
              instance.onUpdate =
                  (details) => widget.onDragUpdate(context, details.delta);
              instance.onEnd = (_) => _end();
              // A cancelled drag has still moved the pin on screen;
              // committing is less surprising than snapping it back.
              instance.onCancel = _end;
            },
          ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            // Absorbed, deliberately. The marker sits *above* its point
            // (`Alignment.topCenter`), so a tap on the pin that fell through
            // to the map would be read as a tap roughly one icon-height north
            // of where the pin already is, and re-drop it there — the visitor
            // touches the pin and watches it walk up the street.
            (instance) {
              instance.onTap = () {};
            },
          ),
        },
        child: widget.child,
      ),
    );
  }
}

/// A pan that competes with a scrolling ancestor on equal terms.
///
/// A [PanGestureRecognizer] waits for [kPanSlop] (36 logical pixels) before it
/// will claim the pointer, while the [Scrollable] this map sits inside claims
/// at [kTouchSlop] (18). The page therefore won every mostly-vertical pin drag
/// 18 pixels before this recogniser was allowed an opinion, and dragging the
/// pin down a phone screen simply scrolled the form — the one gesture the map
/// exists for did nothing on the platform it matters most on.
///
/// Matching the page's threshold lets the deeper recogniser resolve first, as
/// a finger placed on the pin plainly intends. Dragging anywhere else on the
/// map still scrolls the page.
class _PinPanGestureRecognizer extends PanGestureRecognizer {
  _PinPanGestureRecognizer({super.debugOwner});

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) =>
      globalDistanceMoved.abs() >
      computeHitSlop(pointerDeviceKind, gestureSettings);
}
