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

/// Airtable Personal Access Token, supplied at build time via
/// `--dart-define=AIRTABLE_PAT=...` rather than committed to source.
///
/// This is the last Airtable credential the client holds. It survives only for
/// the screens listed in INTEGRATION.md section 10; each one repointed onto
/// `/api/expedion/*` removes a consumer, and the define goes when the last does.
const _kAirtablePat = String.fromEnvironment('AIRTABLE_PAT');

class CreateAirtableQuoteCall {
  static Future<ApiCallResponse> call({
    String? prenom = '',
    String? nom = '',
    String? eMail = '',
    String? telephone = '',
    String? quesouhaitezVous =
        'Retrait enchères - Withdraw your lots in an auction house',
    String? assuranceadvalorem = '',
    String? adressederetrait = '',
    String? codepostalderetrait = '',
    String? lieuderetrait = '',
    String? nomdelamaisondeventes = '',
    String? telephonederetrait = '',
    int? montantdelamarchandise,
    String? tranche = '',
    String? datedevente = '',
    String? bordereauDocURL = '',
    String? nBordereau = '',
    String? bordereauacquitte = '',
    String? dESCRIPTIONdelobjet = '',
    String? longueurdelobjet = '',
    String? largeurdelobjet = '',
    String? hauteurdelobjet = '',
    String? poidsdelobjet = '',
    String? protgouemball = '',
    String? imagesURL = '',
    String? adressedelivraison = '',
    String? adressedelivraisonL2 = '',
    String? codepostaldelivraison = '',
    String? villedelivraison = '',
    String? paysdelivraison = '',
    String? telephonedelivraison = '',
    String? nomdudestinataire = '',
    String? commentaire = '',
    String? conditionsgnrales = '',
    String? pieceIdUrl = '',
    String? uid = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Nom": "${escapeStringForJson(nom)}",
    "Prénom": "${escapeStringForJson(prenom)}",
    "E-mail": "${escapeStringForJson(eMail)}",
    "Téléphone": "${escapeStringForJson(telephone)}",
    "En tant que particulier que souhaitez-vous?": "${escapeStringForJson(quesouhaitezVous)}",
    "Souhaitez-vous une assurance ad valorem": "${escapeStringForJson(assuranceadvalorem)}",
    "Adresse de retrait": "${escapeStringForJson(adressederetrait)}",
    "Code postal de retrait": "${escapeStringForJson(codepostalderetrait)}",
    "Ville de retrait": "${escapeStringForJson(lieuderetrait)}",
    "Nom de la maison de ventes": "${escapeStringForJson(nomdelamaisondeventes)}",
    "Téléphone de retrait": "${escapeStringForJson(telephonederetrait)}",
    "Montant de la marchandise": ${montantdelamarchandise},
    "Tranche Montant de la marchandise": "${escapeStringForJson(tranche)}",
    "N°Bordereau": "${escapeStringForJson(nBordereau)}",
    "Bordereau acquitté ou pas": "${escapeStringForJson(bordereauacquitte)}",
    "DESCRIPTION de l'objet": "${escapeStringForJson(dESCRIPTIONdelobjet)}",
    "Longueur": "${escapeStringForJson(longueurdelobjet)}",
    "Hauteur": "${escapeStringForJson(hauteurdelobjet)}",
    "Largeur": "${escapeStringForJson(largeurdelobjet)}",
    "Adresse de livraison": "${escapeStringForJson(adressedelivraison)}",
    "Adresse de livraison L2": "${escapeStringForJson(adressedelivraisonL2)}",
    "Code postal de livraison": "${escapeStringForJson(codepostaldelivraison)}",
    "Ville de livraison": "${escapeStringForJson(villedelivraison)}",
    "Pays de livraison": "${escapeStringForJson(paysdelivraison)}",
    "Téléphone de livraison": "${escapeStringForJson(telephonedelivraison)}",
    "Nom du destinataire": "${escapeStringForJson(nomdudestinataire)}",
    "UID": "${escapeStringForJson(uid)}",
    "Bordereaux (document)": [
      {
        "url": "${escapeStringForJson(bordereauDocURL)}"
      }
    ],
    "Images": [
      {
        "url": "${escapeStringForJson(imagesURL)}"
      }
    ],
    "Piece d'Identité": [
      {
        "url": "${escapeStringForJson(pieceIdUrl)}"
      }
    ]
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'CreateAirtableQuote',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
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
}

class AirtableQuotePayDirectCall {
  static Future<ApiCallResponse> call({
    String? prenom = '',
    String? nom = '',
    String? email = '',
    String? telephone = '',
    String? tranche = '',
    bool? conditionsGenerales,
    String? udi = '',
    String? uploadedFileBordereau = '',
    String? zoneExpedition = '',
    int? poidsExpedition,
    String? dimensionExpedition = '',
    int? fraisExpedition,
    String? uploadedFileImage = '',
    String? commentaire = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Nom": "${escapeStringForJson(nom)}",
    "Prénom": "${escapeStringForJson(prenom)}",
    "Type Expedition": "${escapeStringForJson(zoneExpedition)}",
    "Frais d'expédition": ${fraisExpedition},
    "Poids Expedition": ${poidsExpedition},
    "Dimension Expedition": "${escapeStringForJson(dimensionExpedition)}",
    "UID": "${escapeStringForJson(udi)}",
    "E-mail": "${escapeStringForJson(email)}",
    "Commentaire":"${escapeStringForJson(commentaire)}",
    "Bordereaux (document)": [
      {
        "url": "${escapeStringForJson(uploadedFileBordereau)}"
      }
    ],
    "Images": [
      {
        "url": "${escapeStringForJson(uploadedFileImage)}"
      }
    ]
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AirtableQuotePayDirect',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
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
}

class GetPriceCall {
  static Future<ApiCallResponse> call({
    String? place = '',
    int? weight,
    String? size = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetPrice',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/Prices?filterByFormula=AND(   {Place}=\'${place}\',   {Weight}=${weight},   {Size}=\'${size}\' )',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'destination': place,
        'poids': weight,
        'taille': size,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static int? price(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.records[:].fields.Price''',
      ));
}

class NewclientSignUpDMCall {
  static Future<ApiCallResponse> call({
    String? nom = '',
    String? prenom = '',
    String? eMail = '',
    String? authUserUid = '',
    String? userType = 'Demandeur',
    String? telephoneClient = '',
    String? adresseClientL1 = '',
    String? adresseClientL2 = '',
    String? codePostalClient = '',
    String? villeClient = '',
    String? adresseLivraisonL1 = '',
    String? adresseLivaisonL2 = '',
    String? codePostalLiv = '',
    String? villeLivraison = '',
    String? telephoneLiv = '',
    String? paysClient = '',
    String? paysLivraison = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Prénom": "${escapeStringForJson(prenom)}",
    "Nom": "${escapeStringForJson(nom)}",
    "Email": "${escapeStringForJson(eMail)}",
    "UID": "${escapeStringForJson(authUserUid)}",
    "Type d'utilisateur": "${escapeStringForJson(userType)}",
    "Adresse L1 client": "${escapeStringForJson(adresseClientL1)}",
    "Adresse L2 client": "${escapeStringForJson(adresseClientL2)}",
    "Code postal client": "${escapeStringForJson(codePostalClient)}",
    "Ville client": "${escapeStringForJson(villeClient)}",
    "Pays client": "${escapeStringForJson(paysClient)}",
    "Téléphone client": "${escapeStringForJson(telephoneClient)}",
    "Adresse de Livraison L1": "${escapeStringForJson(adresseLivraisonL1)}",
    "Adresse de Livraison L2": "${escapeStringForJson(adresseLivaisonL2)}",
    "Code postal de livraison": "${escapeStringForJson(codePostalLiv)}",
    "Ville de livraison": "${escapeStringForJson(villeLivraison)}",
    "Pays Livraison": "${escapeStringForJson(paysLivraison)}",
    "Téléphone Livraison": "${escapeStringForJson(telephoneLiv)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NewclientSignUpDM',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/USERS',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
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

  static String? nom(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Nom''',
      ));
  static String? prenom(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Prénom''',
      ));
  static String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Email''',
      ));
}

class UpdateProfilinfoCall {
  static Future<ApiCallResponse> call({
    String? nom = '',
    String? prenom = '',
    String? eMail = '',
    String? authUserUid = '',
    String? userType = 'Demandeur',
    String? telephoneClient = '',
    String? adresseClientL1 = '',
    String? adresseClientL2 = '',
    String? codePostalClient = '',
    String? villeClient = '',
    String? adresseLivraisonL1 = '',
    String? adresseLivaisonL2 = '',
    String? codePostalLiv = '',
    String? villeLivraison = '',
    String? telephoneLiv = '',
    String? paysClient = '',
    String? paysLivraison = '',
    String? uid = '',
    String? airtableUserID = '',
  }) async {
    final ffApiRequestBody = '''
{
  "records": [
    {
      "id": "${escapeStringForJson(airtableUserID)}",
      "fields": {
        "Prénom": "${escapeStringForJson(prenom)}",
        "Nom": "${escapeStringForJson(nom)}",
        "Adresse L1 client": "${escapeStringForJson(adresseClientL1)}",
        "Adresse L2 client": "${escapeStringForJson(adresseClientL2)}",
        "Code postal client": "${escapeStringForJson(codePostalClient)}",
        "Ville client": "${escapeStringForJson(villeClient)}",
        "Pays client": "${escapeStringForJson(paysClient)}",
        "Téléphone client": "${escapeStringForJson(telephoneClient)}",
        "Adresse de Livraison L1": "${escapeStringForJson(adresseLivraisonL1)}",
        "Adresse de Livraison L2": "${escapeStringForJson(adresseLivaisonL2)}",
        "Code postal de livraison": "${escapeStringForJson(codePostalLiv)}",
        "Ville de livraison": "${escapeStringForJson(villeLivraison)}",
        "Pays Livraison": "${escapeStringForJson(paysLivraison)}",
        "Téléphone Livraison": "${escapeStringForJson(telephoneLiv)}"
      }
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UpdateProfilinfo',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/USERS',
      callType: ApiCallType.PATCH,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
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

  static String? nom(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Nom''',
      ));
  static String? prenom(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Prénom''',
      ));
  static String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.fields.Email''',
      ));
}

class GetAirtableUserIDCall {
  static Future<ApiCallResponse> call({
    String? uid = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetAirtableUserID',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/USERS?filterByFormula=AND(   {UID}=\'${uid}\')',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': uid,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? airtableUserID(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].id''',
      ));
}

class GetUserCall {
  static Future<ApiCallResponse> call({
    String? userID = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetUser',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/USERS',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'filterByFormula': "{UID}=\'${userID}\'",
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? nom(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields.Nom''',
      ));
  static String? prunelle(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields.Prénom''',
      ));
  static String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields.Email''',
      ));
  static String? adresseL1client(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields["Adresse L1 client"]''',
      ));
  static String? codePostalClient(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields["Code postal client"]''',
      ));
  static String? villeClient(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields["Ville client"]''',
      ));
  static String? paysClient(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields["Pays client"]''',
      ));
  static String? telephoneClient(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields["Téléphone client"]''',
      ));
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

class CreatePaymentAitableCall {
  static Future<ApiCallResponse> call({
    String? sessionId = '',
    String? userId = '',
    String? status = 'Paiement en attente',
    String? orderId = '',
    String? currency = 'EUR',
    int? amountstripe,
    String? description = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Description": "${escapeStringForJson(description)}",
    "amount stripe": ${amountstripe},
    "orderId": "${escapeStringForJson(orderId)}",
    "status": "${escapeStringForJson(status)}",
    "userId": "${escapeStringForJson(userId)}",
    "sessionId": "${escapeStringForJson(sessionId)}",
    "currency": "${escapeStringForJson(currency)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'CreatePaymentAitable',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/PAIEMENTS',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
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
