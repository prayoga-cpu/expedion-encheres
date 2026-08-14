import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'mot_de_passe_oublie_widget.dart' show MotDePasseOublieWidget;

class MotDePasseOublieModel extends FlutterFlowModel<MotDePasseOublieWidget> {
  final formKey = GlobalKey<FormState>();

  FocusNode? emailRecuperationFocusNode;
  TextEditingController? emailRecuperationTextController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailRecuperationFocusNode?.dispose();
    emailRecuperationTextController?.dispose();
  }
}
