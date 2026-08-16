// The base URL decides whether a deployed build can reach its backend at all.
//
// It has been wrong twice: first pointing at a stale deployment that 404'd every
// /api/expedion/* route, then at localhost — which made the deployed app ask the
// visitor's own machine for the API, and Chrome refused outright ("Permission
// was denied for this request to access the `loopback` address space").
//
// `flutter test` runs in debug, so these pin the debug branch and the override.
// The release branch is a compile-time constant and cannot be exercised here;
// what it resolves to is asserted through the constant itself.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/backend/expedion_api/expedion_config.dart';

void main() {
  group('ExpedionConfig.baseUrl', () {
    test('has no trailing slash, so path concatenation cannot double it', () {
      expect(ExpedionConfig.baseUrl, isNot(endsWith('/')));
    });

    test('debug builds talk to the local backend', () {
      // No --dart-define is passed under `flutter test`, so this is the
      // default branch: a plain checkout must work against `pnpm dev`.
      expect(ExpedionConfig.baseUrl, 'http://localhost:3000');
      expect(ExpedionConfig.isOverridden, isFalse);
    });

    test('derived URLs hang off the same host', () {
      expect(ExpedionConfig.expeditooWebUrl, ExpedionConfig.baseUrl);
      expect(
        ExpedionConfig.adminDashboardUrl,
        '${ExpedionConfig.baseUrl}/admin/expedion',
      );
    });
  });

  group('the deployed host', () {
    // `kReleaseMode` is false under `flutter test`, so the release branch is
    // folded away and cannot be reached at runtime. Reading the constant out of
    // the source is the only way to assert on it — and it is worth asserting,
    // because a wrong value here is invisible until someone loads the deployed
    // site and every request fails.
    late final String deployed;

    setUpAll(() {
      final source =
          File('lib/backend/expedion_api/expedion_config.dart').readAsStringSync();
      final match = RegExp(
        r"_vercelDeployment\s*=\s*'([^']+)'",
        dotAll: true,
      ).firstMatch(source);
      expect(match, isNotNull,
          reason: '_vercelDeployment is gone or was renamed');
      deployed = match!.group(1)!;
    });

    test('is https', () {
      expect(Uri.parse(deployed).scheme, 'https',
          reason: 'a page served over https cannot call an http origin');
    });

    test('is not a loopback address', () {
      final host = Uri.parse(deployed).host;
      expect(host, isNot(anyOf('localhost', '127.0.0.1', '0.0.0.0')),
          reason: 'Chrome blocks a public page reaching the loopback space, '
              'which is exactly how the deployed build broke before');
    });

    test('carries no trailing slash and no path', () {
      expect(deployed, isNot(endsWith('/')));
      expect(Uri.parse(deployed).path, isEmpty,
          reason: 'routes are appended to this, so a path would double up');
    });
  });
}
