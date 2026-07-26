import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/stripe/payment_manager.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'form_devis_paiement_directe_widget.dart'
    show FormDevisPaiementDirecteWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FormDevisPaiementDirecteModel
    extends FlutterFlowModel<FormDevisPaiementDirecteWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Destination widget.
  String? destinationValue;
  FormFieldController<String>? destinationValueController;
  // State field(s) for Poids widget.
  int? poidsValue;
  FormFieldController<int>? poidsValueController;
  // State field(s) for taille widget.
  String? tailleValue;
  FormFieldController<String>? tailleValueController;
  // State field(s) for Nom widget.
  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;
  String? Function(BuildContext, String?)? nomTextControllerValidator;
  // State field(s) for Prenom widget.
  FocusNode? prenomFocusNode;
  TextEditingController? prenomTextController;
  String? Function(BuildContext, String?)? prenomTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for Telephone widget.
  FocusNode? telephoneFocusNode;
  TextEditingController? telephoneTextController;
  String? Function(BuildContext, String?)? telephoneTextControllerValidator;
  // State field(s) for DescriptionObjet widget.
  FocusNode? descriptionObjetFocusNode;
  TextEditingController? descriptionObjetTextController;
  String? Function(BuildContext, String?)?
      descriptionObjetTextControllerValidator;
  // State field(s) for NumBordereau widget.
  FocusNode? numBordereauFocusNode;
  TextEditingController? numBordereauTextController;
  String? Function(BuildContext, String?)? numBordereauTextControllerValidator;
  // State field(s) for NomHDV widget.
  FocusNode? nomHDVFocusNode;
  TextEditingController? nomHDVTextController;
  String? Function(BuildContext, String?)? nomHDVTextControllerValidator;
  // State field(s) for AdresseRetrait widget.
  FocusNode? adresseRetraitFocusNode;
  TextEditingController? adresseRetraitTextController;
  String? Function(BuildContext, String?)?
      adresseRetraitTextControllerValidator;
  // State field(s) for CodePostalRetrait widget.
  FocusNode? codePostalRetraitFocusNode;
  TextEditingController? codePostalRetraitTextController;
  String? Function(BuildContext, String?)?
      codePostalRetraitTextControllerValidator;
  // State field(s) for VilleRetrait widget.
  FocusNode? villeRetraitFocusNode;
  TextEditingController? villeRetraitTextController;
  String? Function(BuildContext, String?)? villeRetraitTextControllerValidator;
  // State field(s) for AdressedelivraisonL1 widget.
  FocusNode? adressedelivraisonL1FocusNode;
  TextEditingController? adressedelivraisonL1TextController;
  String? Function(BuildContext, String?)?
      adressedelivraisonL1TextControllerValidator;
  // State field(s) for AdressedelivraisonL2 widget.
  FocusNode? adressedelivraisonL2FocusNode;
  TextEditingController? adressedelivraisonL2TextController;
  String? Function(BuildContext, String?)?
      adressedelivraisonL2TextControllerValidator;
  // State field(s) for NBordereau widget.
  FocusNode? nBordereauFocusNode1;
  TextEditingController? nBordereauTextController1;
  String? Function(BuildContext, String?)? nBordereauTextController1Validator;
  // State field(s) for NBordereau widget.
  FocusNode? nBordereauFocusNode2;
  TextEditingController? nBordereauTextController2;
  String? Function(BuildContext, String?)? nBordereauTextController2Validator;
  // State field(s) for PaysLivraison widget.
  FocusNode? paysLivraisonFocusNode;
  TextEditingController? paysLivraisonTextController;
  String? Function(BuildContext, String?)? paysLivraisonTextControllerValidator;
  // State field(s) for TelephoneLivraison widget.
  FocusNode? telephoneLivraisonFocusNode;
  TextEditingController? telephoneLivraisonTextController;
  String? Function(BuildContext, String?)?
      telephoneLivraisonTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController17;
  String? Function(BuildContext, String?)? textController17Validator;
  // Stores action output result for [Backend Call - API (CreateAirtableQuote)] action in Button widget.
  ApiCallResponse? apiResultkhq;
  // Stores action output result for [Stripe Payment] action in Button widget.
  String? paymentId;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nomFocusNode?.dispose();
    nomTextController?.dispose();

    prenomFocusNode?.dispose();
    prenomTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    telephoneFocusNode?.dispose();
    telephoneTextController?.dispose();

    descriptionObjetFocusNode?.dispose();
    descriptionObjetTextController?.dispose();

    numBordereauFocusNode?.dispose();
    numBordereauTextController?.dispose();

    nomHDVFocusNode?.dispose();
    nomHDVTextController?.dispose();

    adresseRetraitFocusNode?.dispose();
    adresseRetraitTextController?.dispose();

    codePostalRetraitFocusNode?.dispose();
    codePostalRetraitTextController?.dispose();

    villeRetraitFocusNode?.dispose();
    villeRetraitTextController?.dispose();

    adressedelivraisonL1FocusNode?.dispose();
    adressedelivraisonL1TextController?.dispose();

    adressedelivraisonL2FocusNode?.dispose();
    adressedelivraisonL2TextController?.dispose();

    nBordereauFocusNode1?.dispose();
    nBordereauTextController1?.dispose();

    nBordereauFocusNode2?.dispose();
    nBordereauTextController2?.dispose();

    paysLivraisonFocusNode?.dispose();
    paysLivraisonTextController?.dispose();

    telephoneLivraisonFocusNode?.dispose();
    telephoneLivraisonTextController?.dispose();

    textFieldFocusNode?.dispose();
    textController17?.dispose();
  }
}
