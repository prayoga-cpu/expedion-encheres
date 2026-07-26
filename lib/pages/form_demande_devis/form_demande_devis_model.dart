import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'form_demande_devis_widget.dart' show FormDemandeDevisWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FormDemandeDevisModel extends FlutterFlowModel<FormDemandeDevisWidget> {
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
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for Telephone widget.
  FocusNode? telephoneFocusNode;
  TextEditingController? telephoneTextController;
  String? Function(BuildContext, String?)? telephoneTextControllerValidator;
  bool isDataUploading_uploadDataCID = false;
  FFUploadedFile uploadedLocalFile_uploadDataCID =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for QueSouhaitezVous widget.
  String? queSouhaitezVousValue;
  FormFieldController<String>? queSouhaitezVousValueController;
  // State field(s) for AssuranceADVOuPas widget.
  String? assuranceADVOuPasValue;
  FormFieldController<String>? assuranceADVOuPasValueController;
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
  // State field(s) for NomHDV widget.
  FocusNode? nomHDVFocusNode;
  TextEditingController? nomHDVTextController;
  String? Function(BuildContext, String?)? nomHDVTextControllerValidator;
  // State field(s) for TelephoneDeRetrait widget.
  FocusNode? telephoneDeRetraitFocusNode;
  TextEditingController? telephoneDeRetraitTextController;
  String? Function(BuildContext, String?)?
      telephoneDeRetraitTextControllerValidator;
  // State field(s) for MontantMarchandise widget.
  FocusNode? montantMarchandiseFocusNode;
  TextEditingController? montantMarchandiseTextController;
  String? Function(BuildContext, String?)?
      montantMarchandiseTextControllerValidator;
  // State field(s) for TrancheTarif widget.
  String? trancheTarifValue;
  FormFieldController<String>? trancheTarifValueController;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for NBordereau widget.
  FocusNode? nBordereauFocusNode;
  TextEditingController? nBordereauTextController;
  String? Function(BuildContext, String?)? nBordereauTextControllerValidator;
  // State field(s) for descriptionObjet widget.
  FocusNode? descriptionObjetFocusNode;
  TextEditingController? descriptionObjetTextController;
  String? Function(BuildContext, String?)?
      descriptionObjetTextControllerValidator;
  // State field(s) for LongueurObjet widget.
  FocusNode? longueurObjetFocusNode;
  TextEditingController? longueurObjetTextController;
  String? Function(BuildContext, String?)? longueurObjetTextControllerValidator;
  // State field(s) for LargeurObjet widget.
  FocusNode? largeurObjetFocusNode;
  TextEditingController? largeurObjetTextController;
  String? Function(BuildContext, String?)? largeurObjetTextControllerValidator;
  // State field(s) for HauteurObjet widget.
  FocusNode? hauteurObjetFocusNode;
  TextEditingController? hauteurObjetTextController;
  String? Function(BuildContext, String?)? hauteurObjetTextControllerValidator;
  // State field(s) for PoidsObjet widget.
  FocusNode? poidsObjetFocusNode1;
  TextEditingController? poidsObjetTextController1;
  String? Function(BuildContext, String?)? poidsObjetTextController1Validator;
  // State field(s) for PoidsObjet widget.
  FocusNode? poidsObjetFocusNode2;
  TextEditingController? poidsObjetTextController2;
  String? Function(BuildContext, String?)? poidsObjetTextController2Validator;

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

    adresseRetraitFocusNode?.dispose();
    adresseRetraitTextController?.dispose();

    codePostalRetraitFocusNode?.dispose();
    codePostalRetraitTextController?.dispose();

    villeRetraitFocusNode?.dispose();
    villeRetraitTextController?.dispose();

    nomHDVFocusNode?.dispose();
    nomHDVTextController?.dispose();

    telephoneDeRetraitFocusNode?.dispose();
    telephoneDeRetraitTextController?.dispose();

    montantMarchandiseFocusNode?.dispose();
    montantMarchandiseTextController?.dispose();

    nBordereauFocusNode?.dispose();
    nBordereauTextController?.dispose();

    descriptionObjetFocusNode?.dispose();
    descriptionObjetTextController?.dispose();

    longueurObjetFocusNode?.dispose();
    longueurObjetTextController?.dispose();

    largeurObjetFocusNode?.dispose();
    largeurObjetTextController?.dispose();

    hauteurObjetFocusNode?.dispose();
    hauteurObjetTextController?.dispose();

    poidsObjetFocusNode1?.dispose();
    poidsObjetTextController1?.dispose();

    poidsObjetFocusNode2?.dispose();
    poidsObjetTextController2?.dispose();
  }
}
