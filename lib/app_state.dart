import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _selectedPlace = '';
  String get selectedPlace => _selectedPlace;
  set selectedPlace(String value) {
    _selectedPlace = value;
  }

  int _selectedWeight = 0;
  int get selectedWeight => _selectedWeight;
  set selectedWeight(int value) {
    _selectedWeight = value;
  }

  String _selectedSize = '';
  String get selectedSize => _selectedSize;
  set selectedSize(String value) {
    _selectedSize = value;
  }

  String _UserID = '';
  String get UserID => _UserID;
  set UserID(String value) {
    _UserID = value;
  }

  String _uploadedBodereauUrl = '';
  String get uploadedBodereauUrl => _uploadedBodereauUrl;
  set uploadedBodereauUrl(String value) {
    _uploadedBodereauUrl = value;
  }

  String _AssuranceChoix = '';
  String get AssuranceChoix => _AssuranceChoix;
  set AssuranceChoix(String value) {
    _AssuranceChoix = value;
  }

  String _demarcheChoix = '';
  String get demarcheChoix => _demarcheChoix;
  set demarcheChoix(String value) {
    _demarcheChoix = value;
  }

  String _UserStatus = '';
  String get UserStatus => _UserStatus;
  set UserStatus(String value) {
    _UserStatus = value;
  }

  bool _LoggedIn = false;
  bool get LoggedIn => _LoggedIn;
  set LoggedIn(bool value) {
    _LoggedIn = value;
  }

  /// Commentaires Transporteur
  String _ExigencesParticulieres = '';
  String get ExigencesParticulieres => _ExigencesParticulieres;
  set ExigencesParticulieres(String value) {
    _ExigencesParticulieres = value;
  }

  int _SelectedPrice = 0;
  int get SelectedPrice => _SelectedPrice;
  set SelectedPrice(int value) {
    _SelectedPrice = value;
  }

  String _TypeDeFomulaireDevis = '';
  String get TypeDeFomulaireDevis => _TypeDeFomulaireDevis;
  set TypeDeFomulaireDevis(String value) {
    _TypeDeFomulaireDevis = value;
  }

  String _uploadedPhotoUrl = '';
  String get uploadedPhotoUrl => _uploadedPhotoUrl;
  set uploadedPhotoUrl(String value) {
    _uploadedPhotoUrl = value;
  }

  /// used to hide any item in
  bool _HIDEitem = true;
  bool get HIDEitem => _HIDEitem;
  set HIDEitem(bool value) {
    _HIDEitem = value;
  }

  List<dynamic> _ConfirmedQuote = [];
  List<dynamic> get ConfirmedQuote => _ConfirmedQuote;
  set ConfirmedQuote(List<dynamic> value) {
    _ConfirmedQuote = value;
  }

  void addToConfirmedQuote(dynamic value) {
    ConfirmedQuote.add(value);
  }

  void removeFromConfirmedQuote(dynamic value) {
    ConfirmedQuote.remove(value);
  }

  void removeAtIndexFromConfirmedQuote(int index) {
    ConfirmedQuote.removeAt(index);
  }

  void updateConfirmedQuoteAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    ConfirmedQuote[index] = updateFn(_ConfirmedQuote[index]);
  }

  void insertAtIndexInConfirmedQuote(int index, dynamic value) {
    ConfirmedQuote.insert(index, value);
  }

  bool _DevisAssADV = false;
  bool get DevisAssADV => _DevisAssADV;
  set DevisAssADV(bool value) {
    _DevisAssADV = value;
  }

  bool _DevisSTDR = false;
  bool get DevisSTDR => _DevisSTDR;
  set DevisSTDR(bool value) {
    _DevisSTDR = value;
  }

  String _TypeDeDevisValide = '';
  String get TypeDeDevisValide => _TypeDeDevisValide;
  set TypeDeDevisValide(String value) {
    _TypeDeDevisValide = value;
  }

  /// quand un devis est validé et payé il doit se mettre en vert.
  bool _DevisValideEtPaye = false;
  bool get DevisValideEtPaye => _DevisValideEtPaye;
  set DevisValideEtPaye(bool value) {
    _DevisValideEtPaye = value;
  }

  String _statutDuDevis = '';
  String get statutDuDevis => _statutDuDevis;
  set statutDuDevis(String value) {
    _statutDuDevis = value;
  }

  /// si le devis vilidé ou pas
  String _DevisValideOuPas = '';
  String get DevisValideOuPas => _DevisValideOuPas;
  set DevisValideOuPas(String value) {
    _DevisValideOuPas = value;
  }

  String _queSouhaitezVous = '';
  String get queSouhaitezVous => _queSouhaitezVous;
  set queSouhaitezVous(String value) {
    _queSouhaitezVous = value;
  }

  bool _AutreExpeditionDebiens = false;
  bool get AutreExpeditionDebiens => _AutreExpeditionDebiens;
  set AutreExpeditionDebiens(bool value) {
    _AutreExpeditionDebiens = value;
  }

  bool _RetraitEnchres = false;
  bool get RetraitEnchres => _RetraitEnchres;
  set RetraitEnchres(bool value) {
    _RetraitEnchres = value;
  }

  bool _DevisAvantAchatVente = false;
  bool get DevisAvantAchatVente => _DevisAvantAchatVente;
  set DevisAvantAchatVente(bool value) {
    _DevisAvantAchatVente = value;
  }

  /// quand l'adresse de livraison du client est la meme  que son adresse de
  /// domicile
  bool _MemeAdresseDeLivraison = false;
  bool get MemeAdresseDeLivraison => _MemeAdresseDeLivraison;
  set MemeAdresseDeLivraison(bool value) {
    _MemeAdresseDeLivraison = value;
  }

  String _StatPaiement = '';
  String get StatPaiement => _StatPaiement;
  set StatPaiement(String value) {
    _StatPaiement = value;
  }

  String _adresseLivraisonL1 = '';
  String get adresseLivraisonL1 => _adresseLivraisonL1;
  set adresseLivraisonL1(String value) {
    _adresseLivraisonL1 = value;
  }

  String _adresseLivraisonL2 = '';
  String get adresseLivraisonL2 => _adresseLivraisonL2;
  set adresseLivraisonL2(String value) {
    _adresseLivraisonL2 = value;
  }

  String _codePostalLivraison = '';
  String get codePostalLivraison => _codePostalLivraison;
  set codePostalLivraison(String value) {
    _codePostalLivraison = value;
  }

  String _villeLivraison = '';
  String get villeLivraison => _villeLivraison;
  set villeLivraison(String value) {
    _villeLivraison = value;
  }

  String _paysLivraison = '';
  String get paysLivraison => _paysLivraison;
  set paysLivraison(String value) {
    _paysLivraison = value;
  }

  String _telephoneLivraison = '';
  String get telephoneLivraison => _telephoneLivraison;
  set telephoneLivraison(String value) {
    _telephoneLivraison = value;
  }

  String _PageDeDestination = '';
  String get PageDeDestination => _PageDeDestination;
  set PageDeDestination(String value) {
    _PageDeDestination = value;
  }

  String _SelectedQuoteNum = '';
  String get SelectedQuoteNum => _SelectedQuoteNum;
  set SelectedQuoteNum(String value) {
    _SelectedQuoteNum = value;
  }

  String _QuoteId = '';
  String get QuoteId => _QuoteId;
  set QuoteId(String value) {
    _QuoteId = value;
  }
}
