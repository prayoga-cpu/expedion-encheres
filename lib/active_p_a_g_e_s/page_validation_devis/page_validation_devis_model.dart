import '/active_p_a_g_e_s/liste_a_p_p_b_a_r/liste_a_p_p_b_a_r_widget.dart';
import '/active_p_a_g_e_s/paiement/paiement_widget.dart';
import '/auth/base_auth_user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'page_validation_devis_widget.dart' show PageValidationDevisWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PageValidationDevisModel
    extends FlutterFlowModel<PageValidationDevisWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (CreatePaymentIntent)] action in Payer widget.
  ApiCallResponse? apiResultz01ADV;
  // Stores action output result for [Backend Call - API (CreatePaymentAitable)] action in Payer widget.
  ApiCallResponse? apiResult1uqadv;
  // Stores action output result for [Backend Call - API (CreatePaymentIntent)] action in Payer widget.
  ApiCallResponse? apiResultz01STD;
  // Stores action output result for [Backend Call - API (CreatePaymentAitable)] action in Payer widget.
  ApiCallResponse? apiResult1uqstd;
  // Stores action output result for [Backend Call - API (UpdateDevisValider)] action in Confirmer widget.
  ApiCallResponse? apiResulth44;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
