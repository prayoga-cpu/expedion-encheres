import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

/// Base URL of the payment server that creates Stripe Checkout sessions with
/// the SECRET key (which can't live in the client) and e-mails payment links.
///
/// The endpoints are deployed as Vercel functions in this repo's own `api/`
/// directory, so a release web build calls its OWN origin — no configuration
/// and no CORS. `PAYMENT_SERVER_URL` remains as an override for pointing a
/// build somewhere else; local dev falls back to
/// `tools/local_payment_server.js` on :4242, which serves the same handlers.
///
/// The empty-define trap the old constant had: `vercel-build.sh` always
/// passes `--dart-define=PAYMENT_SERVER_URL=` and a defined-but-empty value
/// suppresses `defaultValue`, so the deployed build silently called
/// `https:///...` (empty host) and every payment failed with a generic
/// "réessayez". Resolving through a function that treats empty as unset —
/// the pattern `ExpedionConfig.baseUrl` already uses — closes that hole.
const _kPaymentServerUrlDefine = String.fromEnvironment('PAYMENT_SERVER_URL');

String paymentServerBaseUrl() {
  final configured = _kPaymentServerUrlDefine.trim();
  if (configured.isNotEmpty) {
    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }
  if (kIsWeb && kReleaseMode) return Uri.base.origin;
  return 'http://localhost:4242';
}

class CreatePaymentIntentCall {
  static Future<ApiCallResponse> call({
    int? unitAmount,
    String? currency = 'eur',
    String? userID = '',
    String? cancelUrl = '',
    String? successUrl = '',
    String? productName = '',
    int? quantity,
    String? orderID = '',
    String? recordID = '',
  }) async {
    final ffApiRequestBody = '''
{
  "unitAmount": ${unitAmount ?? 0},
  "currency": "${escapeStringForJson(currency)}",
  "userID": "${escapeStringForJson(userID)}",
  "cancelUrl": "${escapeStringForJson(cancelUrl)}",
  "successUrl": "${escapeStringForJson(successUrl)}",
  "productName": "${escapeStringForJson(productName)}",
  "quantity": ${quantity ?? 1},
  "orderID": "${escapeStringForJson(orderID)}",
  "recordID": "${escapeStringForJson(recordID)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'CreatePaymentIntent',
      apiUrl: '${paymentServerBaseUrl()}/api/create-checkout-session',
      callType: ApiCallType.POST,
      headers: {'Content-Type': 'application/json'},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? sessionID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.id''',
      ));
  static String? sessionURL(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.url''',
      ));
}

/// `PostMessageCall` stood here: a POST into the Airtable `MESSAGERIE` table,
/// behind the contact forms on `/contact` and `/pageContactDevis`.
///
/// Both are gone — `/contact` is a live support thread against Expeditoo's
/// inbox, `/pageContactDevis` forwards to it — so nothing wrote to that table
/// any more. Removed rather than left dead: a working Airtable POST helper
/// sitting in this file is an invitation to wire a form back up to a mailbox
/// nobody watches. `MESSAGERIE` now receives nothing; its history is still
/// there if anyone needs to read it.

/// Asks the payment server to VERIFY a Checkout session is actually paid, then
/// (server-side) record the settlement.
///
/// This is the only way the app marks a quote paid. The client-side
/// `MarkQuotePaidCall` that used to sit here was spoofable — visiting /success
/// with any recordId settled that quote — and had stopped working besides, as
/// it addressed Airtable with what is now a Postgres id.
class ConfirmPaymentCall {
  static Future<ApiCallResponse> call({
    String? sessionId = '',
    String? recordId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "sessionId": "${escapeStringForJson(sessionId)}",
  "recordId": "${escapeStringForJson(recordId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ConfirmPayment',
      apiUrl: '${paymentServerBaseUrl()}/api/confirm-payment',
      callType: ApiCallType.POST,
      headers: {'Content-Type': 'application/json'},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool updated(dynamic response) =>
      getJsonField(response, r'''$.updated''') == true;
  static bool paid(dynamic response) =>
      getJsonField(response, r'''$.paid''') == true;
}

class SendPaymentLinkEmailCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    int? amount,
    String? currency = 'eur',
    String? productName = 'Retrait/Expédition de biens',
    String? successUrl = '',
    String? cancelUrl = '',
    String? userID = '',
    String? orderID = '',
    String? recordID = '',
    String? quoteNum = '',
    String? lang = 'fr',
  }) async {
    final ffApiRequestBody = '''
{
  "unitAmount": ${amount ?? 0},
  "currency": "${escapeStringForJson(currency)}",
  "productName": "${escapeStringForJson(productName)}",
  "successUrl": "${escapeStringForJson(successUrl)}",
  "cancelUrl": "${escapeStringForJson(cancelUrl)}",
  "userID": "${escapeStringForJson(userID)}",
  "orderID": "${escapeStringForJson(orderID)}",
  "recordID": "${escapeStringForJson(recordID)}",
  "quoteNum": "${escapeStringForJson(quoteNum)}",
  "customerEmail": "${escapeStringForJson(email)}",
  "lang": "${escapeStringForJson(lang)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SendPaymentLinkEmail',
      apiUrl: '${paymentServerBaseUrl()}/api/send-payment-email',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? paymentUrl(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.url''',
      ));
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
