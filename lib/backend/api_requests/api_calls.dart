import 'dart:convert';
import 'dart:typed_data';
import '../cloud_functions/cloud_functions.dart';

import 'package:flutter/foundation.dart';

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

/// Airtable Personal Access Tokens, supplied at build time via
/// `--dart-define=AIRTABLE_PAT=...` (and `AIRTABLE_PAT_TRANSPORTEURS=...`)
/// rather than committed to source.
const _kAirtablePat = String.fromEnvironment('AIRTABLE_PAT');
const _kAirtablePatTransporteurs =
    String.fromEnvironment('AIRTABLE_PAT_TRANSPORTEURS');

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

class CreateAirtableQuoteFromDocCall {
  static Future<ApiCallResponse> call({
    String? prenom = '',
    String? nom = '',
    String? email = '',
    String? telephone = '',
    String? queSouhaitezVous = '',
    String? souhaitezVousAssADV = '',
    String? tranche = '',
    bool? conditionsGenerales,
    String? udi = '',
    String? uploadedFileBordereau = '',
    String? uploadedFileImage = '',
    String? commentaire = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Nom": "${escapeStringForJson(nom)}",
    "Prénom": "${escapeStringForJson(prenom)}",
    "En tant que particulier que souhaitez-vous?": "${escapeStringForJson(queSouhaitezVous)}",
    "UID": "${escapeStringForJson(udi)}",
    "Souhaitez-vous une assurance ad valorem": "${escapeStringForJson(souhaitezVousAssADV)}",
    "Tranche Montant de la marchandise": "${escapeStringForJson(tranche)}",
    "E-mail": "${escapeStringForJson(email)}",
    "Commentaire": "${escapeStringForJson(commentaire)}",
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
      callName: 'CreateAirtableQuoteFromDoc',
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

class PostDDallFieldsCall {
  static Future<ApiCallResponse> call({
    String? prenom = '',
    String? nom = '',
    String? email = '',
    String? telephone = '',
    String? pieceID = '',
    String? queSouhaitezVous = '',
    String? souhaitezVousAssADV = '',
    String? adresseRetrait = '',
    String? codepostalRetrait = '',
    String? villeRetrait = '',
    String? nomMaisonVentes = '',
    String? telephoneRerait = '',
    double? montantMarchandise,
    String? tranche = '',
    String? dateVente = '',
    String? docBordereau = '',
    String? numBordereau = '',
    String? bordereauAcquite = '',
    String? descriptionObet = '',
    String? longueurObjet = '',
    String? largeurObjet = '',
    String? hauteurObjet = '',
    String? poidsObjet = '',
    String? objetProtege = '',
    String? imageObjet = '',
    String? adresseLivraisonL1 = '',
    String? adresseLivraisonL2 = '',
    String? codePostalLivraison = '',
    String? villeLivraison = '',
    String? paysLivraison = '',
    String? telephoneLivraison = '',
    String? nomDestinataire = '',
    bool? conditionsGenerales,
    String? udi = '',
    String? uploadedFileBordereau = '',
    String? uploadedFileImage = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Nom": "${escapeStringForJson(nom)}",
    "Prénom": "${escapeStringForJson(prenom)}",
    "En tant que particulier que souhaitez-vous?": "${escapeStringForJson(queSouhaitezVous)}",
    "UID": "${escapeStringForJson(udi)}",
    "Souhaitez-vous une assurance ad valorem": "${escapeStringForJson(souhaitezVousAssADV)}",
    "Tranche Montant de la marchandise": "${escapeStringForJson(tranche)}",
    "E-mail": "${escapeStringForJson(email)}",
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
      callName: 'PostDDallFields',
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

class GetClientQuotesCall {
  static Future<ApiCallResponse> call({
    String? userID = 'Db1XiG8JZSZNNM4PTdx7KAf5HZT2',
    String? numBordereau = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotes',
      apiUrl: (numBordereau == null || numBordereau.isEmpty)
          ? 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula={UID}=\"${userID}\"'
          : 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\", SEARCH(\"${numBordereau}\", {N°Bordereau}))',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
        'numBordereau': numBordereau,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Statut du devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? devisdisponible(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Devis disponible"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? numBordereau(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["N°Bordereau"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetClientQuotesNewCall {
  static Future<ApiCallResponse> call({
    String? userID = 'Db1XiG8JZSZNNM4PTdx7KAf5HZT2',
    String? devisFait = 'Confirmer',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotesNew',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\",{Confirmer le devis}=\"\")',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Statut du devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static dynamic confirmerledevis(dynamic response) => getJsonField(
        response,
        r'''$.records[:].fields["Confirmer le devis"]''',
      );
}

class SeachClientQuotesNumBodereauCall {
  static Future<ApiCallResponse> call({
    String? userID = '',
    String? numBordereau = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'SeachClientQuotesNumBodereau',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\",{N°Bordereau}=\"${numBordereau}\")',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
        'NumBordereau': numBordereau,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Statut du devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static dynamic confirmerledevis(dynamic response) => getJsonField(
        response,
        r'''$.records[:].fields["Confirmer le devis"]''',
      );
}

class GetClientQuotesValideCall {
  static Future<ApiCallResponse> call({
    String? userID = 'Db1XiG8JZSZNNM4PTdx7KAf5HZT2',
    String? devisValide = 'Devis Validé',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotesValide',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\",{VALIDER DEVIS}=\"${devisValide}\")',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["VALIDER DEVIS"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetClientQuotesPayeCall {
  static Future<ApiCallResponse> call({
    String? userID = 'Db1XiG8JZSZNNM4PTdx7KAf5HZT2',
    String? paiement = 'Paiement reçu',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotesPaye',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\",{STATUT DU PAIEMENT}=\"${paiement}\")',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
        'paiment': paiement,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["VALIDER DEVIS"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetClientQuotesWaitingForPaymentCall {
  static Future<ApiCallResponse> call({
    String? userID = 'Db1XiG8JZSZNNM4PTdx7KAf5HZT2',
    String? devisFait = 'Confirmer',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotesWaitingForPayment',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=AND({UID}=\"${userID}\",{Statut du devis}=\"en attente de validation\")',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'UID': userID,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statutdudevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Statut du devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetClientQuotesTransportCall {
  static Future<ApiCallResponse> call({
    String? villeRetrait = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientQuotesTransport',
      apiUrl: (villeRetrait == null || villeRetrait.isEmpty)
          ? 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS'
          : 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS?filterByFormula=SEARCH(\"${villeRetrait}\", {Ville de retrait})',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'ville de retrait': "${villeRetrait}",
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records''',
        true,
      ) as List?;
  static List<int>? numdevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Numéro Devis"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? statPaiement(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["STATUT DU PAIEMENT"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? dateDevis(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Date recu"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? frais(dynamic response) => (getJsonField(
        response,
        r'''$.records[:].fields["Tarif Devis correspondant"]''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static String? recordID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.records[:].id''',
      ));
}

class NewclientSignUpTPCall {
  static Future<ApiCallResponse> call({
    String? nom = '',
    String? prenom = '',
    String? eMail = '',
    String? authUserUid = '',
    String? userType = '',
    String? villeDeRetraitTP = '',
    String? villeDeLivraisonTP = '',
    String? capaciteVehiculeTP = '',
    String? commentaireTP = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Prénom": "${escapeStringForJson(prenom)}",
    "Nom": "${escapeStringForJson(nom)}",
    "Email": "${escapeStringForJson(eMail)}",
    "UID": "${escapeStringForJson(authUserUid)}",
    "Type d'utilisateur": "${escapeStringForJson(userType)}",
    "Départ":"${escapeStringForJson(villeDeRetraitTP)}",
    "Destination": "${escapeStringForJson(villeDeLivraisonTP)}",
    "Capacité du véhicule": "${escapeStringForJson(capaciteVehiculeTP)}",
    "Commentaires": "${escapeStringForJson(commentaireTP)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NewclientSignUpTP',
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

class NewTransporteurCall {
  static Future<ApiCallResponse> call({
    String? nom = '',
    String? prenom = '',
    String? uid = '',
    String? email = '',
    String? telephone = '',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Prénom": "${escapeStringForJson(prenom)}",
    "Nom": "${escapeStringForJson(nom)}",
    "Mail chauffeur": "${escapeStringForJson(email)}",
    "ID Flutterfow": "${escapeStringForJson(uid)}",
    "telephone chauffeur":"${escapeStringForJson(telephone)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NewTransporteur',
      apiUrl: 'https://api.airtable.com/v0/appu3jamyzCJRuOjr/TRANSPORTEURS',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $_kAirtablePatTransporteurs',
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

class UpdatePropositionTansporteurCall {
  static Future<ApiCallResponse> call({
    String? iDTransporteur = '',
    String? nomTransporteur = '',
    String? recordId = 'recrlWvAIcC6kMG8C',
  }) async {
    final ffApiRequestBody = '''
{
  "fields": {
    "Transporteur Proposer FFL": "${escapeStringForJson(nomTransporteur)}",
    "ID Transporteur": "${escapeStringForJson(iDTransporteur)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UpdatePropositionTansporteur',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/CONTACTS/${recordId}',
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

class GetClientPaymentsCall {
  static Future<ApiCallResponse> call({
    String? userID = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClientPayments',
      apiUrl:
          'https://api.airtable.com/v0/appu3jamyzCJRuOjr/PAYMENT-Flutterflow?filterByFormula=AND(   {userId}=\'${userID}\')',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $_kAirtablePat',
        'Content-Type': 'application/json',
      },
      params: {
        'userID': userID,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? desccription(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.records[:].fields.Description''',
      ));
  static int? amount(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.records[:].fields.Montant''',
      ));
  static List? records(dynamic response) => getJsonField(
        response,
        r'''$.records[:].fields''',
        true,
      ) as List?;
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

/// Marks an Airtable CONTACTS (quote) record as paid, client-side. This mirrors
/// exactly what the `stripeWebhook` Cloud Function would set, so the resulting
/// state is identical whether the quote is confirmed by the webhook or by the
/// in-app `/success` page after a Checkout redirect.
///
/// NOTE: this trusts the post-payment redirect rather than a verified webhook.
/// It matches the app's existing client-side Airtable access (the PAT is already
/// embedded here); for cryptographically verified confirmation use the webhook.
class MarkQuotePaidCall {
  static Future<ApiCallResponse> call({
    String? quoteID = '',
  }) async {
    final ffApiRequestBody = '''
{
  "records": [
    {
      "id": "${escapeStringForJson(quoteID)}",
      "fields": {
        "STATUT DU PAIEMENT": "Paiement reçu",
        "VALIDER DEVIS": "Devis Validé"
      }
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'MarkQuotePaid',
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
/// (server-side) mark the Airtable quote paid. Preferred over the client-side
/// [MarkQuotePaidCall] because it can't be spoofed by visiting /success and
/// avoids browser CORS on the Airtable PATCH.
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

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
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
