import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'mes_devis_widget.dart' show MesDevisWidget;

class MesDevisModel extends FlutterFlowModel<MesDevisWidget> {
  /// The bordereau-number search box.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
