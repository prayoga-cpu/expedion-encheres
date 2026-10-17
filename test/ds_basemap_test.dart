// The map's style loading, without the network: the TileJSON lookup in
// DSBasemap.load needs OpenFreeMap, but what is read from the bundle — and
// how it is named for the tile cache — does not.

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'package:expedion_encheres/design_system/ds_basemap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fingerprint', () {
    test('is FNV-1a 32, so it is the same on every run and platform', () {
      // Reference values of the published algorithm.
      expect(DSBasemap.fingerprint(''), '811c9dc5');
      expect(DSBasemap.fingerprint('a'), 'e40c292c');
      expect(DSBasemap.fingerprint('foobar'), 'bf9cf968');
    });

    test('changes with the content', () {
      expect(
        DSBasemap.fingerprint('{"x":1}'),
        isNot(DSBasemap.fingerprint('{"x":2}')),
      );
    });
  });

  group('readStyle', () {
    test('light and dark are cached under different names', () async {
      final light = await DSBasemap.readStyle(dark: false);
      final dark = await DSBasemap.readStyle(dark: true);

      // A shared id would let the tile cache hand one style's tiles to the
      // other — the dark map drawn light.
      expect(light['id'], 'expedion-light');
      expect(dark['id'], 'expedion-dark');
      expect(
        light['metadata']['version'],
        isNot(dark['metadata']['version']),
      );
    });

    test('both read as themes over the OpenFreeMap source', () async {
      for (final dark in [false, true]) {
        final style = await DSBasemap.readStyle(dark: dark);
        final theme = vtr.ThemeReader().read(style);

        expect(theme.id, dark ? 'expedion-dark' : 'expedion-light');
        expect(theme.layers, isNotEmpty);
        expect(theme.tileSources, {'openmaptiles'});
        expect(
          style['sources']['openmaptiles']['url'],
          'https://tiles.openfreemap.org/planet',
        );
      }
    });
  });
}
