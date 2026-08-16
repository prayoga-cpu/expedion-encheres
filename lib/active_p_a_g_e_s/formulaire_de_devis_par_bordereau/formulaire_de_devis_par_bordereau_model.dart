import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'formulaire_de_devis_par_bordereau_widget.dart'
    show FormulaireDeDevisParBordereauWidget;
import 'package:flutter/material.dart';

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

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    commentaireFocusNode?.dispose();
    commentaireTextController?.dispose();
  }
}
