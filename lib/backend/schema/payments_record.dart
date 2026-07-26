import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PaymentsRecord extends FirestoreRecord {
  PaymentsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "currency" field.
  String? _currency;
  String get currency => _currency ?? '';
  bool hasCurrency() => _currency != null;

  // "orderId" field.
  String? _orderId;
  String get orderId => _orderId ?? '';
  bool hasOrderId() => _orderId != null;

  // "Description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "amount" field.
  int? _amount;
  int get amount => _amount ?? 0;
  bool hasAmount() => _amount != null;

  // "sessionId" field.
  String? _sessionId;
  String get sessionId => _sessionId ?? '';
  bool hasSessionId() => _sessionId != null;

  void _initializeFields() {
    _status = snapshotData['status'] as String?;
    _userId = snapshotData['userId'] as String?;
    _currency = snapshotData['currency'] as String?;
    _orderId = snapshotData['orderId'] as String?;
    _description = snapshotData['Description'] as String?;
    _amount = castToType<int>(snapshotData['amount']);
    _sessionId = snapshotData['sessionId'] as String?;
  }

  static CollectionReference get collection => FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: '(default)')
      .collection('payments');

  static Stream<PaymentsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PaymentsRecord.fromSnapshot(s));

  static Future<PaymentsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PaymentsRecord.fromSnapshot(s));

  static PaymentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PaymentsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PaymentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PaymentsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PaymentsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PaymentsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPaymentsRecordData({
  String? status,
  String? userId,
  String? currency,
  String? orderId,
  String? description,
  int? amount,
  String? sessionId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'status': status,
      'userId': userId,
      'currency': currency,
      'orderId': orderId,
      'Description': description,
      'amount': amount,
      'sessionId': sessionId,
    }.withoutNulls,
  );

  return firestoreData;
}

class PaymentsRecordDocumentEquality implements Equality<PaymentsRecord> {
  const PaymentsRecordDocumentEquality();

  @override
  bool equals(PaymentsRecord? e1, PaymentsRecord? e2) {
    return e1?.status == e2?.status &&
        e1?.userId == e2?.userId &&
        e1?.currency == e2?.currency &&
        e1?.orderId == e2?.orderId &&
        e1?.description == e2?.description &&
        e1?.amount == e2?.amount &&
        e1?.sessionId == e2?.sessionId;
  }

  @override
  int hash(PaymentsRecord? e) => const ListEquality().hash([
        e?.status,
        e?.userId,
        e?.currency,
        e?.orderId,
        e?.description,
        e?.amount,
        e?.sessionId
      ]);

  @override
  bool isValidKey(Object? o) => o is PaymentsRecord;
}
