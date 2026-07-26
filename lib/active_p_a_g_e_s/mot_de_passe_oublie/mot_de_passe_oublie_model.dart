import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'mot_de_passe_oublie_widget.dart' show MotDePasseOublieWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MotDePasseOublieModel extends FlutterFlowModel<MotDePasseOublieWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for EmailRecuperation widget.
  FocusNode? emailRecuperationFocusNode;
  TextEditingController? emailRecuperationTextController;
  String? Function(BuildContext, String?)?
      emailRecuperationTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailRecuperationFocusNode?.dispose();
    emailRecuperationTextController?.dispose();
  }
}
