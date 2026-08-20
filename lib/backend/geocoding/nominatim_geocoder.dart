import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single Nominatim search result, trimmed to what an address form needs.
class GeocodeSuggestion {
  const GeocodeSuggestion({
    required this.label,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.lat,
    required this.lng,
  });

  /// The full display string, for the suggestions dropdown.
  final String label;

  /// Street line only ("10 Rue de Rivoli") — what goes in the address field.
  final String address;
  final String city;
  final String postalCode;
  final double lat;
  final double lng;

  @override
  String toString() => label;
}

/// Address search against Nominatim (OpenStreetMap) — the same provider and
/// France-only scoping Expeditoo's own admin map picker uses
/// (`expeditoo-ship/src/lib/geocoding.ts`, `location-picker-field.tsx`).
///
/// This is a public, unauthenticated HTTP API with no server-side proxy on
/// either side of the bridge, so the client calls it directly, exactly as the
/// admin's browser does. Coordinates found here are never sent to the
/// Expedion API — the server resolves and trusts its own copy of them
/// (`expedionService.geocodeMissingCoordinates`) once an address is saved.
/// This class exists purely to help the visitor pick a real, geocodable
/// address at entry time, and to show them it resolved.
class NominatimGeocoder {
  NominatimGeocoder._();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Required by Nominatim's usage policy:
  /// https://operations.osmfoundation.org/policies/nominatim/
  static const Map<String, String> _headers = {
    'User-Agent': 'ExpedionEncheres/1.0',
    'Accept': 'application/json',
  };

  /// Forward search, scoped to France. Returns an empty list on any failure
  /// — this is a best-effort assist, never a blocker to typing an address by
  /// hand.
  static Future<List<GeocodeSuggestion>> search(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': trimmed,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      'countrycodes': 'fr',
    });

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .whereType<GeocodeSuggestion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// One-shot best-effort resolve of an already-assembled address, for a
  /// submit-time fallback when the visitor typed an address without picking
  /// a suggestion. Returns `null` rather than throwing on any failure.
  static Future<GeocodeSuggestion?> resolve({
    required String address,
    required String postalCode,
    required String city,
  }) async {
    final query = [address, postalCode, city]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
    final results = await search(query, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  static GeocodeSuggestion? _fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lng = double.tryParse('${json['lon']}');
    if (lat == null || lng == null) return null;

    final address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : const <String, dynamic>{};

    // Defensively re-checked client-side even though the query already
    // scoped `countrycodes=fr` — mirrors the admin picker's own
    // belt-and-braces check in `location-picker-field.tsx`.
    final countryCode = (address['country_code'] as String?)?.toLowerCase();
    if (countryCode != null && countryCode != 'fr') return null;

    final houseNumber = (address['house_number'] as String?)?.trim() ?? '';
    final road = (address['road'] as String?)?.trim() ?? '';
    final streetLine =
        [houseNumber, road].where((s) => s.isNotEmpty).join(' ');

    final city = (address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            '')
        .toString()
        .trim();
    final postalCode = (address['postcode'] as String?)?.trim() ?? '';
    final displayName = (json['display_name'] as String?)?.trim() ?? '';

    return GeocodeSuggestion(
      label: displayName.isNotEmpty ? displayName : streetLine,
      address: streetLine.isNotEmpty ? streetLine : displayName,
      city: city,
      postalCode: postalCode,
      lat: lat,
      lng: lng,
    );
  }
}
