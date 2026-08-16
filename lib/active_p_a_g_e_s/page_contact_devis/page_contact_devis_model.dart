import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'page_contact_devis_widget.dart' show PageContactDevisWidget;
import 'package:flutter/material.dart';

class PageContactDevisModel extends FlutterFlowModel<PageContactDevisWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Nom widget.
  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;
  String? Function(BuildContext, String?)? nomTextControllerValidator;
  // State field(s) for prenom widget.
  FocusNode? prenomFocusNode;
  TextEditingController? prenomTextController;
  String? Function(BuildContext, String?)? prenomTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode1;
  TextEditingController? emailTextController1;
  String? Function(BuildContext, String?)? emailTextController1Validator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode2;
  TextEditingController? emailTextController2;
  String? Function(BuildContext, String?)? emailTextController2Validator;
  // State field(s) for Sujet widget.
  FocusNode? sujetFocusNode;
  TextEditingController? sujetTextController;
  String? Function(BuildContext, String?)? sujetTextControllerValidator;
  // State field(s) for Message widget.
  FocusNode? messageFocusNode;
  TextEditingController? messageTextController;
  String? Function(BuildContext, String?)? messageTextControllerValidator;
  // Stores action output result for [Backend Call - API (PostMessage)] action in Button widget.
  ApiCallResponse? apiResultp6c;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nomFocusNode?.dispose();
    nomTextController?.dispose();

    prenomFocusNode?.dispose();
    prenomTextController?.dispose();

    emailFocusNode1?.dispose();
    emailTextController1?.dispose();

    emailFocusNode2?.dispose();
    emailTextController2?.dispose();

    sujetFocusNode?.dispose();
    sujetTextController?.dispose();

    messageFocusNode?.dispose();
    messageTextController?.dispose();
  }
}
