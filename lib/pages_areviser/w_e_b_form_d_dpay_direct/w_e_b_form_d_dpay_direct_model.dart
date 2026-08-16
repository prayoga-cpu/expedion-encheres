import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'w_e_b_form_d_dpay_direct_widget.dart' show WEBFormDDpayDirectWidget;
import 'package:flutter/material.dart';

class WEBFormDDpayDirectModel
    extends FlutterFlowModel<WEBFormDDpayDirectWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Destination widget.
  String? destinationValue;
  FormFieldController<String>? destinationValueController;
  // State field(s) for Poids widget.
  int? poidsValue;
  FormFieldController<int>? poidsValueController;
  // State field(s) for Dimension widget.
  String? dimensionValue;
  FormFieldController<String>? dimensionValueController;
  // State field(s) for Nom widget.
  FocusNode? nomFocusNode;
  TextEditingController? nomTextController;
  String? Function(BuildContext, String?)? nomTextControllerValidator;
  // State field(s) for Prenom widget.
  FocusNode? prenomFocusNode;
  TextEditingController? prenomTextController;
  String? Function(BuildContext, String?)? prenomTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for Telephone widget.
  FocusNode? telephoneFocusNode;
  TextEditingController? telephoneTextController;
  String? Function(BuildContext, String?)? telephoneTextControllerValidator;
  // State field(s) for Comentaire widget.
  FocusNode? comentaireFocusNode;
  TextEditingController? comentaireTextController;
  String? Function(BuildContext, String?)? comentaireTextControllerValidator;
  bool isDataUploading_uploadDataBordereauDD = false;
  FFUploadedFile uploadedLocalFile_uploadDataBordereauDD =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataBordereauDD = '';

  bool isDataUploading_uploadDataPhotoDD = false;
  FFUploadedFile uploadedLocalFile_uploadDataPhotoDD =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataPhotoDD = '';

  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  PaymentsRecord? payment;
  // Stores action output result for [Backend Call - API (CreatePaymentIntent)] action in Button widget.
  ApiCallResponse? paymentIntent;
  // Stores action output result for [Backend Call - API (AirtableQuotePayDirect)] action in Button widget.
  ApiCallResponse? apiResultty6;
  // Stores action output result for [Backend Call - API (CreatePaymentAitable)] action in Button widget.
  ApiCallResponse? apiResultfuj;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nomFocusNode?.dispose();
    nomTextController?.dispose();

    prenomFocusNode?.dispose();
    prenomTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    telephoneFocusNode?.dispose();
    telephoneTextController?.dispose();

    comentaireFocusNode?.dispose();
    comentaireTextController?.dispose();
  }
}
