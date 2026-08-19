import 'dart:convert';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

/// Base URL of the payment server that creates Stripe Checkout sessions with
/// the SECRET key (which can't live in the client) and e-mails payment links.
///
/// Defaults to the local dev server (tools/local_payment_server.js) so the flow
/// works WITHOUT deploying / fixing the Firebase Cloud Function. For production,
/// host that same server (or a corrected Cloud Function) and point this here.
// TODO(EXPEDITOO-TESTING): localhost fallback — deploy the payment server
// (tools/local_payment_server.js, or a fixed Cloud Function) and set
// PAYMENT_SERVER_URL in the Vercel build env (wired through vercel-build.sh)
// so deployed builds stop pointing at localhost:4242.
const _kPaymentServerBaseUrl = String.fromEnvironment(
  'PAYMENT_SERVER_URL',
  defaultValue: 'http://localhost:4242',
);

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
      apiUrl: '$_kPaymentServerBaseUrl/create-checkout-session',
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

class PostMessageCall {
  static Future<ApiCallResponse> call({
    String? nom = '',
    String? prenom = '',
    String? email = '',
    String? sujet = '',
    String? message = '',
    String? uid = '',
    String? numDevis = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Nom": "${escapeStringForJson(nom)}",
    "Prénom": "${escapeStringForJson(prenom)}",
    "Email": "${escapeStringForJson(email)}",
    "Sujet": "${escapeStringForJson(sujet)}",
    "Message": "${escapeStringForJson(message)}",
    "UID": "${escapeStringForJson(uid)}",
    "N° Devis":"${escapeStringForJson(numDevis)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'PostMessage',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/MESSAGERIE',
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

class UpdateDevisValiderCall {
  static Future<ApiCallResponse> call({
    String? typeDeDevisValide = '',
    String? quoteID = '',
    String? status = 'Devis Validé',
  }) async {
    final ffApiRequestBody = '''
{
  "records": [
    {
      "id": "${escapeStringForJson(quoteID)}",
      "fields": {
        "VALIDER DEVIS": "${escapeStringForJson(status)}",
        "Type de Devis validé": "${escapeStringForJson(typeDeDevisValide)}"
      }
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UpdateDevisValider',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS',
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
}

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
      apiUrl: '$_kPaymentServerBaseUrl/confirm-payment',
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

class CreatePaymentAirtableCall {
  static Future<ApiCallResponse> call({
    String? currency = 'EUR',
    String? description = 'TRE',
    int? amountstripe = 222,
    String? orderId = 'tet',
    String? status = 'Paiement en attente',
    String? userId = 'TESTSESSION',
    String? sessionId = 'TESTSESSION',
    String? quoteID = '',
    String? paymentUrl = '',
    // Recipient address. Only set on the "email me the link" path; left blank
    // for pay-now. An Airtable automation keyed on "Email is not empty" then
    // e-mails the link for the email path only.
    String? email = '',
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
    "currency": "${escapeStringForJson(currency)}",
    "lien de paiement stripe": "${escapeStringForJson(paymentUrl)}",
    "Email": "${escapeStringForJson(email)}",
    "N°Devis": "${escapeStringForJson(quoteID)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'CreatePaymentAirtable',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/PAIEMENTS FLUTTERFLOW',
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
  "customerEmail": "${escapeStringForJson(email)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SendPaymentLinkEmail',
      apiUrl: '$_kPaymentServerBaseUrl/send-payment-email',
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
