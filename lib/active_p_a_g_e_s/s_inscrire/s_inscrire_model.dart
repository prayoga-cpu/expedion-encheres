import 'package:flutter/material.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 's_inscrire_widget.dart' show SInscrireWidget;

class SInscrireModel extends FlutterFlowModel<SInscrireWidget> {
  final formKey = GlobalKey<FormState>();

  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;

  FocusNode? prenomFocusNode;
  TextEditingController? prenomTextController;

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  FocusNode? motDePasseFocusNode;
  TextEditingController? motDePasseTextController;

  FocusNode? motDePasseConfirmeFocusNode;
  TextEditingController? motDePasseConfirmeTextController;

  // Billing address: line 1, line 2, postcode, city, country, phone.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController4;
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController5;
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController6;
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController7;
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController8;
  FocusNode? textFieldFocusNode6;
  TextEditingController? textController9;

  // Delivery address, in the same order.
  FocusNode? textFieldFocusNode7;
  TextEditingController? textController10;
  FocusNode? textFieldFocusNode8;
  TextEditingController? textController11;
  FocusNode? textFieldFocusNode9;
  TextEditingController? textController12;
  FocusNode? textFieldFocusNode10;
  TextEditingController? textController13;
  FocusNode? textFieldFocusNode11;
  TextEditingController? textController14;
  FocusNode? textFieldFocusNode12;
  TextEditingController? textController15;

  /// Result of the GetAirtableUserID call made after a Firebase sign-up.
  ApiCallResponse? airtableUserID;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    for (final node in [
      nomFocusNode,
      prenomFocusNode,
      emailFocusNode,
      motDePasseFocusNode,
      motDePasseConfirmeFocusNode,
      textFieldFocusNode1,
      textFieldFocusNode2,
      textFieldFocusNode3,
      textFieldFocusNode4,
      textFieldFocusNode5,
      textFieldFocusNode6,
      textFieldFocusNode7,
      textFieldFocusNode8,
      textFieldFocusNode9,
      textFieldFocusNode10,
      textFieldFocusNode11,
      textFieldFocusNode12,
    ]) {
      node?.dispose();
    }

    for (final controller in [
      nomTextController,
      prenomTextController,
      emailTextController,
      motDePasseTextController,
      motDePasseConfirmeTextController,
      textController4,
      textController5,
      textController6,
      textController7,
      textController8,
      textController9,
      textController10,
      textController11,
      textController12,
      textController13,
      textController14,
      textController15,
    ]) {
      controller?.dispose();
    }
  }
}
