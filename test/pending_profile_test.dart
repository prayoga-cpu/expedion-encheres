// What sign-up parks for the Expeditoo profile, and when it is sent.
//
// The e-mail path has no session at sign-up, so the details wait on the device
// for the first sign-in. These pin the three things that could go quietly
// wrong: sending them for the wrong account, losing the address because the
// phone was mistyped, and dropping them when the server simply did not answer.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/auth/base_auth_user_provider.dart';
import 'package:expedion_encheres/auth/expeditoo/expedion_auth.dart';
import 'package:expedion_encheres/auth/expeditoo/expeditoo_auth_client.dart';
import 'package:expedion_encheres/backend/expedion_api/expedion_profile.dart';
import 'package:expedion_encheres/backend/pending_profile.dart';

const _profileJson = {
  'success': true,
  'data': {
    'email': 'camille@example.fr',
    'firstName': null,
    'lastName': null,
    'phone': null,
    'address': null,
  },
};

final _update = ExpedionProfileUpdate(
  phone: '06 12 34 56 78',
  address: ExpedionAddress.fromForm(
    line1: '12 rue X',
    zip: '75011',
    city: 'Paris',
  ),
);

void _signInAs(String email) {
  currentUser = ExpeditooAuthUser(ExpeditooUser(id: 'u1', email: email));
}

/// Runs [body] against a fake server; returns the bodies of every PUT.
Future<List<Map<String, dynamic>>> _withServer(
  Future<void> Function() body,
  http.Response Function(Map<String, dynamic> sent, int attempt) respond,
) async {
  final sent = <Map<String, dynamic>>[];
  await http.runWithClient(body, () {
    return MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/expedion/me/profile');
      expect(request.headers['Authorization'], 'Bearer token');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      sent.add(payload);
      return respond(payload, sent.length);
    });
  });
  return sent;
}

http.Response _json(int status, Object body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      '__expeditoo_session_token__': 'token',
    });
    await ExpeditooAuthClient.initialize();
    await PendingProfile.clear();
  });

  test('sends the details once the owner signs in, then forgets them',
      () async {
    await PendingProfile.stage(email: 'Camille@example.fr', update: _update);
    _signInAs('camille@example.fr');

    final sent = await _withServer(() async {
      await PendingProfile.flush();
      await PendingProfile.flush();
    }, (_, __) => _json(200, _profileJson));

    expect(sent, hasLength(1));
    expect(sent.single['phone'], '06 12 34 56 78');
    expect(sent.single['address']['city'], 'Paris');
  });

  test('keeps them from a different account', () async {
    await PendingProfile.stage(email: 'camille@example.fr', update: _update);
    _signInAs('someone.else@example.fr');

    final none = await _withServer(
      PendingProfile.flush,
      (_, __) => _json(200, _profileJson),
    );
    expect(none, isEmpty);

    _signInAs('camille@example.fr');
    final later = await _withServer(
      PendingProfile.flush,
      (_, __) => _json(200, _profileJson),
    );
    expect(later, hasLength(1));
  });

  test('a refused phone does not cost the address', () async {
    await PendingProfile.stage(email: 'camille@example.fr', update: _update);
    _signInAs('camille@example.fr');

    final sent = await _withServer(PendingProfile.flush, (payload, attempt) {
      if (payload.containsKey('phone')) {
        return _json(400, {
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Invalid input',
            'details': {'phone': 'Numéro invalide'},
          },
        });
      }
      return _json(200, _profileJson);
    });

    expect(sent, hasLength(2));
    expect(sent.last.containsKey('phone'), isFalse);
    expect(sent.last['address']['line1'], '12 rue X');
  });

  test('keeps them when the server did not answer properly', () async {
    await PendingProfile.stage(email: 'camille@example.fr', update: _update);
    _signInAs('camille@example.fr');

    final failed = await _withServer(
      PendingProfile.flush,
      (_, __) => _json(503, {'success': false}),
    );
    expect(failed, hasLength(1));

    final retried = await _withServer(
      PendingProfile.flush,
      (_, __) => _json(200, _profileJson),
    );
    expect(retried, hasLength(1));
  });

  test('they are written to device storage, not only memory', () async {
    await PendingProfile.stage(email: 'camille@example.fr', update: _update);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('expedion.pendingProfile');
    expect(stored, isNotNull);
    expect(jsonDecode(stored!)['email'], 'camille@example.fr');
  });
}
