import '/flutter_flow/flutter_flow_util.dart';
import 'contact_widget.dart' show ContactWidget;
import 'package:flutter/material.dart';

/// The contact page holds no page-level state any more.
///
/// It used to carry five controllers, five focus nodes, a form key and the
/// stored result of the Airtable `PostMessage` call. All of that belonged to
/// the contact form; the support chat that replaced it keeps its own state in
/// `SupportChatController`, which lives and dies with the widget rather than
/// with the route. The model stays because `createModel` is what every
/// FlutterFlow page is wired to expect.
class ContactModel extends FlutterFlowModel<ContactWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
