import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// The basemap behind every Expedion map: Expeditoo's own monochrome style
/// over OpenFreeMap's vector tiles, so the two apps draw the same map.
///
/// The styles in `assets/jsons/map_style_{light,dark}.json` are copies of
/// `expeditoo-ship/public/map-styles/{light,dark}.json`; change them together.
/// OpenFreeMap needs no key and sets no request limit, which is why it replaced
/// CARTO's raster tiles: since September 2026 those answer every keyless
/// request with an "API KEY REQUIRED" image.
///
/// Attribution is a condition of using the tiles — [attribution] is what the
/// map must show.
class DSBasemap {
  DSBasemap._(this.theme, this.providers);

  /// The style's layers, ready for a `VectorTileLayer`.
  final vtr.Theme theme;

  /// One provider per source the style names (`openmaptiles`).
  final TileProviders providers;

  static const String attribution =
      '© OpenFreeMap · © OpenMapTiles · © OpenStreetMap';

  static const String _lightAsset = 'assets/jsons/map_style_light.json';
  static const String _darkAsset = 'assets/jsons/map_style_dark.json';

  static final Map<bool, Future<DSBasemap>> _loads = {};

  /// The basemap for one brightness, read once and shared by every map.
  ///
  /// A failed read is forgotten rather than cached, so the next map to ask
  /// tries again instead of inheriting a stale failure.
  static Future<DSBasemap> load({required bool dark}) =>
      _loads[dark] ??= _read(dark).catchError((Object error) {
        _loads.remove(dark);
        throw error;
      });

  static Future<DSBasemap> _read(bool dark) async {
    final style = await readStyle(dark: dark);
    final sources = style['sources'] as Map<String, dynamic>;
    final providers = <String, VectorTileProvider>{};
    for (final entry in sources.entries) {
      providers[entry.key] = await _provider(entry.value as Map);
    }
    return DSBasemap._(
      vtr.ThemeReader().read(style),
      TileProviders(providers),
    );
  }

  /// A source's tiles, resolved through its TileJSON when it names one.
  ///
  /// OpenFreeMap publishes a new planet build every week under a dated path,
  /// so the tile URL cannot be written into the style: the TileJSON at the
  /// source's `url` says which build is current.
  static Future<VectorTileProvider> _provider(Map source) async {
    var tileJson = source;
    final url = source['url'];
    if (url is String) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw StateError('TileJSON $url answered ${response.statusCode}');
      }
      tileJson = jsonDecode(response.body) as Map;
    }
    final tiles = tileJson['tiles'];
    if (tiles is! List || tiles.isEmpty) {
      throw StateError('TileJSON names no tiles');
    }
    return NetworkVectorTileProvider(
      urlTemplate: tiles.first as String,
      maximumZoom: (tileJson['maxzoom'] as num?)?.toInt() ?? 14,
      minimumZoom: (tileJson['minzoom'] as num?)?.toInt() ?? 0,
    );
  }

  /// The bundled style for one brightness, named and versioned.
  ///
  /// The layer caches the tiles it draws — on the web in IndexedDB, across
  /// visits — under the theme's id and version, which a style without them
  /// reads as "default" / "none". Both styles would then share one cache, and
  /// the dark map would come back drawn in the light style; an edited style
  /// would never replace what was cached. So each is named, and versioned by
  /// its own content.
  @visibleForTesting
  static Future<Map<String, dynamic>> readStyle({required bool dark}) async {
    final text = await rootBundle.loadString(dark ? _darkAsset : _lightAsset);
    final style = jsonDecode(text) as Map<String, dynamic>;
    style['id'] = dark ? 'expedion-dark' : 'expedion-light';
    style['metadata'] = {'version': fingerprint(text)};
    return style;
  }

  /// A 32-bit FNV-1a hash of [text], in hex.
  ///
  /// `String.hashCode` is not guaranteed to survive a restart, and this must,
  /// since it keys a persistent cache. The multiply is split (the prime is
  /// 2^24 + 0x193) so that no intermediate passes 2^53 and a web build, whose
  /// integers are doubles, computes the same value as the VM.
  @visibleForTesting
  static String fingerprint(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (((hash << 24) & 0xffffffff) + hash * 0x193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Forgets every read basemap. Tests only.
  @visibleForTesting
  static void reset() => _loads.clear();
}
