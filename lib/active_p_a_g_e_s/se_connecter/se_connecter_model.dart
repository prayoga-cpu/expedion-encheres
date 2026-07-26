import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'se_connecter_widget.dart' show SeConnecterWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SeConnecterModel extends FlutterFlowModel<SeConnecterWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for motDePasse widget.
  FocusNode? motDePasseFocusNode;
  TextEditingController? motDePasseTextController;
  late bool motDePasseVisibility;
  String? Function(BuildContext, String?)? motDePasseTextControllerValidator;

  @override
  void initState(BuildContext context) {
    motDePasseVisibility = false;
  }

  @override
  void dispose() {
    emailFocusNode?.dispose();
    emailTextController?.dispose();

    motDePasseFocusNode?.dispose();
    motDePasseTextController?.dispose();
  }
}
