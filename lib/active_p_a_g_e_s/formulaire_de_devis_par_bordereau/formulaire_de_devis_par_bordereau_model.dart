import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'formulaire_de_devis_par_bordereau_widget.dart'
    show FormulaireDeDevisParBordereauWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FormulaireDeDevisParBordereauModel
    extends FlutterFlowModel<FormulaireDeDevisParBordereauWidget> {
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
  // State field(s) for Commentaire widget.
  FocusNode? commentaireFocusNode;
  TextEditingController? commentaireTextController;
  String? Function(BuildContext, String?)? commentaireTextControllerValidator;
  bool isDataUploading_uploadDataBordereau = false;
  FFUploadedFile uploadedLocalFile_uploadDataBordereau =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataBordereau = '';

  bool isDataUploading_uploadDataPhoto = false;
  FFUploadedFile uploadedLocalFile_uploadDataPhoto =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataPhoto = '';

  // Stores action output result for [Backend Call - API (CreateAirtableQuoteFromDoc)] action in Button widget.
  ApiCallResponse? apiResultyx5;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    commentaireFocusNode?.dispose();
    commentaireTextController?.dispose();
  }
}
