import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'w_e_b_form_d_devis_widget.dart' show WEBFormDDevisWidget;
import 'package:flutter/material.dart';

class WEBFormDDevisModel extends FlutterFlowModel<WEBFormDDevisWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for QueSouhaitezVous widget.
  String? queSouhaitezVousValue;
  FormFieldController<String>? queSouhaitezVousValueController;
  // State field(s) for AssuranceADV widget.
  String? assuranceADVValue;
  FormFieldController<String>? assuranceADVValueController;
  // State field(s) for Tranche widget.
  String? trancheValue;
  FormFieldController<String>? trancheValueController;
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
  // State field(s) for telephone widget.
  FocusNode? telephoneFocusNode;
  TextEditingController? telephoneTextController;
  String? Function(BuildContext, String?)? telephoneTextControllerValidator;
  // State field(s) for Commentaire widget.
  FocusNode? commentaireFocusNode;
  TextEditingController? commentaireTextController;
  String? Function(BuildContext, String?)? commentaireTextControllerValidator;

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

    commentaireFocusNode?.dispose();
    commentaireTextController?.dispose();
  }
}
