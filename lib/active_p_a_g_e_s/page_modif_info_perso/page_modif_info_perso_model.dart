import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'page_modif_info_perso_widget.dart' show PageModifInfoPersoWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PageModifInfoPersoModel
    extends FlutterFlowModel<PageModifInfoPersoWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Nom widget.
  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;
  String? Function(BuildContext, String?)? nomTextControllerValidator;
  // State field(s) for Prenom widget.
  FocusNode? prenomFocusNode;
  TextEditingController? prenomTextController;
  String? Function(BuildContext, String?)? prenomTextControllerValidator;
  // State field(s) for Telephone widget.
  FocusNode? telephoneFocusNode;
  TextEditingController? telephoneTextController;
  String? Function(BuildContext, String?)? telephoneTextControllerValidator;
  // State field(s) for ADclientL1 widget.
  FocusNode? aDclientL1FocusNode;
  TextEditingController? aDclientL1TextController;
  String? Function(BuildContext, String?)? aDclientL1TextControllerValidator;
  // State field(s) for ADclientL2 widget.
  FocusNode? aDclientL2FocusNode;
  TextEditingController? aDclientL2TextController;
  String? Function(BuildContext, String?)? aDclientL2TextControllerValidator;
  // State field(s) for CodePostalClient widget.
  FocusNode? codePostalClientFocusNode;
  TextEditingController? codePostalClientTextController;
  String? Function(BuildContext, String?)?
      codePostalClientTextControllerValidator;
  // State field(s) for villeClient widget.
  FocusNode? villeClientFocusNode;
  TextEditingController? villeClientTextController;
  String? Function(BuildContext, String?)? villeClientTextControllerValidator;
  // State field(s) for PaysClient widget.
  FocusNode? paysClientFocusNode;
  TextEditingController? paysClientTextController;
  String? Function(BuildContext, String?)? paysClientTextControllerValidator;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // State field(s) for ADliv1 widget.
  FocusNode? aDliv1FocusNode;
  TextEditingController? aDliv1TextController;
  String? Function(BuildContext, String?)? aDliv1TextControllerValidator;
  // State field(s) for ADliv2 widget.
  FocusNode? aDliv2FocusNode;
  TextEditingController? aDliv2TextController;
  String? Function(BuildContext, String?)? aDliv2TextControllerValidator;
  // State field(s) for CodePostalLiv widget.
  FocusNode? codePostalLivFocusNode;
  TextEditingController? codePostalLivTextController;
  String? Function(BuildContext, String?)? codePostalLivTextControllerValidator;
  // State field(s) for VilleLivraison widget.
  FocusNode? villeLivraisonFocusNode;
  TextEditingController? villeLivraisonTextController;
  String? Function(BuildContext, String?)?
      villeLivraisonTextControllerValidator;
  // State field(s) for PaysLivraison widget.
  FocusNode? paysLivraisonFocusNode;
  TextEditingController? paysLivraisonTextController;
  String? Function(BuildContext, String?)? paysLivraisonTextControllerValidator;
  // State field(s) for TelLivraision widget.
  FocusNode? telLivraisionFocusNode;
  TextEditingController? telLivraisionTextController;
  String? Function(BuildContext, String?)? telLivraisionTextControllerValidator;
  // Stores action output result for [Backend Call - API (UpdateProfilinfo)] action in Button widget.
  ApiCallResponse? apiResultljs;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nomFocusNode?.dispose();
    nomTextController?.dispose();

    prenomFocusNode?.dispose();
    prenomTextController?.dispose();

    telephoneFocusNode?.dispose();
    telephoneTextController?.dispose();

    aDclientL1FocusNode?.dispose();
    aDclientL1TextController?.dispose();

    aDclientL2FocusNode?.dispose();
    aDclientL2TextController?.dispose();

    codePostalClientFocusNode?.dispose();
    codePostalClientTextController?.dispose();

    villeClientFocusNode?.dispose();
    villeClientTextController?.dispose();

    paysClientFocusNode?.dispose();
    paysClientTextController?.dispose();

    aDliv1FocusNode?.dispose();
    aDliv1TextController?.dispose();

    aDliv2FocusNode?.dispose();
    aDliv2TextController?.dispose();

    codePostalLivFocusNode?.dispose();
    codePostalLivTextController?.dispose();

    villeLivraisonFocusNode?.dispose();
    villeLivraisonTextController?.dispose();

    paysLivraisonFocusNode?.dispose();
    paysLivraisonTextController?.dispose();

    telLivraisionFocusNode?.dispose();
    telLivraisionTextController?.dispose();
  }
}
