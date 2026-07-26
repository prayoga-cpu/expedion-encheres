import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'formulaire_demande_de_devis_retrait_aux_encheres_widget.dart'
    show FormulaireDemandeDeDevisRetraitAuxEncheresWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FormulaireDemandeDeDevisRetraitAuxEncheresModel
    extends FlutterFlowModel<FormulaireDemandeDeDevisRetraitAuxEncheresWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Prnom widget.
  FocusNode? prnomFocusNode;
  TextEditingController? prnomTextController;
  String? Function(BuildContext, String?)? prnomTextControllerValidator;
  // State field(s) for Nom widget.
  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;
  String? Function(BuildContext, String?)? nomTextControllerValidator;
  // State field(s) for E-mail widget.
  FocusNode? eMailFocusNode;
  TextEditingController? eMailTextController;
  String? Function(BuildContext, String?)? eMailTextControllerValidator;
  // State field(s) for Tlphone widget.
  FocusNode? tlphoneFocusNode;
  TextEditingController? tlphoneTextController;
  String? Function(BuildContext, String?)? tlphoneTextControllerValidator;
  // State field(s) for Assuanceoupas widget.
  String? assuanceoupasValue;
  FormFieldController<String>? assuanceoupasValueController;
  // State field(s) for Adressederetrait widget.
  FocusNode? adressederetraitFocusNode;
  TextEditingController? adressederetraitTextController;
  String? Function(BuildContext, String?)?
      adressederetraitTextControllerValidator;
  // State field(s) for Codepostal widget.
  FocusNode? codepostalFocusNode;
  TextEditingController? codepostalTextController;
  String? Function(BuildContext, String?)? codepostalTextControllerValidator;
  // State field(s) for Lieuderetrait widget.
  FocusNode? lieuderetraitFocusNode;
  TextEditingController? lieuderetraitTextController;
  String? Function(BuildContext, String?)? lieuderetraitTextControllerValidator;
  // State field(s) for Nomdelamaisondeventes widget.
  FocusNode? nomdelamaisondeventesFocusNode;
  TextEditingController? nomdelamaisondeventesTextController;
  String? Function(BuildContext, String?)?
      nomdelamaisondeventesTextControllerValidator;
  // State field(s) for Tlphonederetrait widget.
  FocusNode? tlphonederetraitFocusNode;
  TextEditingController? tlphonederetraitTextController;
  String? Function(BuildContext, String?)?
      tlphonederetraitTextControllerValidator;
  // State field(s) for Montant widget.
  FocusNode? montantFocusNode;
  TextEditingController? montantTextController;
  String? Function(BuildContext, String?)? montantTextControllerValidator;
  // State field(s) for Tranche widget.
  String? trancheValue;
  FormFieldController<String>? trancheValueController;
  // State field(s) for Datedevente widget.
  FocusNode? datedeventeFocusNode;
  TextEditingController? datedeventeTextController;
  String? Function(BuildContext, String?)? datedeventeTextControllerValidator;
  bool isDataUploading_uploadDataBordereauFDDencheres = false;
  FFUploadedFile uploadedLocalFile_uploadDataBordereauFDDencheres =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataBordereauFDDencheres = '';

  // State field(s) for NBordereau widget.
  FocusNode? nBordereauFocusNode;
  TextEditingController? nBordereauTextController;
  String? Function(BuildContext, String?)? nBordereauTextControllerValidator;
  // State field(s) for Bordereauacquitte widget.
  String? bordereauacquitteValue;
  FormFieldController<String>? bordereauacquitteValueController;
  // State field(s) for Descriptionobjet widget.
  FocusNode? descriptionobjetFocusNode;
  TextEditingController? descriptionobjetTextController;
  String? Function(BuildContext, String?)?
      descriptionobjetTextControllerValidator;
  // State field(s) for Longueur widget.
  FocusNode? longueurFocusNode;
  TextEditingController? longueurTextController;
  String? Function(BuildContext, String?)? longueurTextControllerValidator;
  // State field(s) for Largeur widget.
  FocusNode? largeurFocusNode;
  TextEditingController? largeurTextController;
  String? Function(BuildContext, String?)? largeurTextControllerValidator;
  // State field(s) for Hauteur widget.
  FocusNode? hauteurFocusNode;
  TextEditingController? hauteurTextController;
  String? Function(BuildContext, String?)? hauteurTextControllerValidator;
  // State field(s) for Poidsdelobjetkg widget.
  FocusNode? poidsdelobjetkgFocusNode;
  TextEditingController? poidsdelobjetkgTextController;
  String? Function(BuildContext, String?)?
      poidsdelobjetkgTextControllerValidator;
  // State field(s) for Emballeoupas widget.
  String? emballeoupasValue;
  FormFieldController<String>? emballeoupasValueController;
  bool isDataUploading_uploadDataImageDDRencheres = false;
  FFUploadedFile uploadedLocalFile_uploadDataImageDDRencheres =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataImageDDRencheres = '';

  // State field(s) for Adressedelivraison widget.
  FocusNode? adressedelivraisonFocusNode;
  TextEditingController? adressedelivraisonTextController;
  String? Function(BuildContext, String?)?
      adressedelivraisonTextControllerValidator;
  // State field(s) for adresselivraisonL2 widget.
  FocusNode? adresselivraisonL2FocusNode;
  TextEditingController? adresselivraisonL2TextController;
  String? Function(BuildContext, String?)?
      adresselivraisonL2TextControllerValidator;
  // State field(s) for Codepostallivraison widget.
  FocusNode? codepostallivraisonFocusNode;
  TextEditingController? codepostallivraisonTextController;
  String? Function(BuildContext, String?)?
      codepostallivraisonTextControllerValidator;
  // State field(s) for Villelivraison widget.
  FocusNode? villelivraisonFocusNode;
  TextEditingController? villelivraisonTextController;
  String? Function(BuildContext, String?)?
      villelivraisonTextControllerValidator;
  // State field(s) for telephonelivason widget.
  FocusNode? telephonelivasonFocusNode;
  TextEditingController? telephonelivasonTextController;
  String? Function(BuildContext, String?)?
      telephonelivasonTextControllerValidator;
  // State field(s) for nomDestinataire widget.
  FocusNode? nomDestinataireFocusNode;
  TextEditingController? nomDestinataireTextController;
  String? Function(BuildContext, String?)?
      nomDestinataireTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController24;
  String? Function(BuildContext, String?)? textController24Validator;
  // Stores action output result for [Backend Call - API (CreateAirtableQuote)] action in Button widget.
  ApiCallResponse? apiResultpf2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    prnomFocusNode?.dispose();
    prnomTextController?.dispose();

    nomFocusNode?.dispose();
    nomTextController?.dispose();

    eMailFocusNode?.dispose();
    eMailTextController?.dispose();

    tlphoneFocusNode?.dispose();
    tlphoneTextController?.dispose();

    adressederetraitFocusNode?.dispose();
    adressederetraitTextController?.dispose();

    codepostalFocusNode?.dispose();
    codepostalTextController?.dispose();

    lieuderetraitFocusNode?.dispose();
    lieuderetraitTextController?.dispose();

    nomdelamaisondeventesFocusNode?.dispose();
    nomdelamaisondeventesTextController?.dispose();

    tlphonederetraitFocusNode?.dispose();
    tlphonederetraitTextController?.dispose();

    montantFocusNode?.dispose();
    montantTextController?.dispose();

    datedeventeFocusNode?.dispose();
    datedeventeTextController?.dispose();

    nBordereauFocusNode?.dispose();
    nBordereauTextController?.dispose();

    descriptionobjetFocusNode?.dispose();
    descriptionobjetTextController?.dispose();

    longueurFocusNode?.dispose();
    longueurTextController?.dispose();

    largeurFocusNode?.dispose();
    largeurTextController?.dispose();

    hauteurFocusNode?.dispose();
    hauteurTextController?.dispose();

    poidsdelobjetkgFocusNode?.dispose();
    poidsdelobjetkgTextController?.dispose();

    adressedelivraisonFocusNode?.dispose();
    adressedelivraisonTextController?.dispose();

    adresselivraisonL2FocusNode?.dispose();
    adresselivraisonL2TextController?.dispose();

    codepostallivraisonFocusNode?.dispose();
    codepostallivraisonTextController?.dispose();

    villelivraisonFocusNode?.dispose();
    villelivraisonTextController?.dispose();

    telephonelivasonFocusNode?.dispose();
    telephonelivasonTextController?.dispose();

    nomDestinataireFocusNode?.dispose();
    nomDestinataireTextController?.dispose();

    textFieldFocusNode?.dispose();
    textController24?.dispose();
  }
}
