import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'se_connecter_widget.dart' show SeConnecterWidget;

class SeConnecterModel extends FlutterFlowModel<SeConnecterWidget> {
  final formKey = GlobalKey<FormState>();

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  FocusNode? motDePasseFocusNode;
  TextEditingController? motDePasseTextController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailFocusNode?.dispose();
    emailTextController?.dispose();

    motDePasseFocusNode?.dispose();
    motDePasseTextController?.dispose();
  }
}
