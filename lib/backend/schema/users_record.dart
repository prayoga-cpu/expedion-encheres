import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "Nom" field.
  String? _nom;
  String get nom => _nom ?? '';
  bool hasNom() => _nom != null;

  // "Prenom" field.
  String? _prenom;
  String get prenom => _prenom ?? '';
  bool hasPrenom() => _prenom != null;

  // "UserType" field.
  String? _userType;
  String get userType => _userType ?? '';
  bool hasUserType() => _userType != null;

  // "adresseClientL1" field.
  String? _adresseClientL1;
  String get adresseClientL1 => _adresseClientL1 ?? '';
  bool hasAdresseClientL1() => _adresseClientL1 != null;

  // "adresseClientL2" field.
  String? _adresseClientL2;
  String get adresseClientL2 => _adresseClientL2 ?? '';
  bool hasAdresseClientL2() => _adresseClientL2 != null;

  // "codePostalClient" field.
  String? _codePostalClient;
  String get codePostalClient => _codePostalClient ?? '';
  bool hasCodePostalClient() => _codePostalClient != null;

  // "villeClient" field.
  String? _villeClient;
  String get villeClient => _villeClient ?? '';
  bool hasVilleClient() => _villeClient != null;

  // "adresseLivraisonL1" field.
  String? _adresseLivraisonL1;
  String get adresseLivraisonL1 => _adresseLivraisonL1 ?? '';
  bool hasAdresseLivraisonL1() => _adresseLivraisonL1 != null;

  // "adresseLivraisonL2" field.
  String? _adresseLivraisonL2;
  String get adresseLivraisonL2 => _adresseLivraisonL2 ?? '';
  bool hasAdresseLivraisonL2() => _adresseLivraisonL2 != null;

  // "codePotalLivraison" field.
  String? _codePotalLivraison;
  String get codePotalLivraison => _codePotalLivraison ?? '';
  bool hasCodePotalLivraison() => _codePotalLivraison != null;

  // "villeLivraison" field.
  String? _villeLivraison;
  String get villeLivraison => _villeLivraison ?? '';
  bool hasVilleLivraison() => _villeLivraison != null;

  // "paysLivraison" field.
  String? _paysLivraison;
  String get paysLivraison => _paysLivraison ?? '';
  bool hasPaysLivraison() => _paysLivraison != null;

  // "paysClient" field.
  String? _paysClient;
  String get paysClient => _paysClient ?? '';
  bool hasPaysClient() => _paysClient != null;

  // "telephoneClient" field.
  String? _telephoneClient;
  String get telephoneClient => _telephoneClient ?? '';
  bool hasTelephoneClient() => _telephoneClient != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "compteVerifie" field.
  bool? _compteVerifie;
  bool get compteVerifie => _compteVerifie ?? false;
  bool hasCompteVerifie() => _compteVerifie != null;

  // "AirtableUserID" field.
  String? _airtableUserID;
  String get airtableUserID => _airtableUserID ?? '';
  bool hasAirtableUserID() => _airtableUserID != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _nom = snapshotData['Nom'] as String?;
    _prenom = snapshotData['Prenom'] as String?;
    _userType = snapshotData['UserType'] as String?;
    _adresseClientL1 = snapshotData['adresseClientL1'] as String?;
    _adresseClientL2 = snapshotData['adresseClientL2'] as String?;
    _codePostalClient = snapshotData['codePostalClient'] as String?;
    _villeClient = snapshotData['villeClient'] as String?;
    _adresseLivraisonL1 = snapshotData['adresseLivraisonL1'] as String?;
    _adresseLivraisonL2 = snapshotData['adresseLivraisonL2'] as String?;
    _codePotalLivraison = snapshotData['codePotalLivraison'] as String?;
    _villeLivraison = snapshotData['villeLivraison'] as String?;
    _paysLivraison = snapshotData['paysLivraison'] as String?;
    _paysClient = snapshotData['paysClient'] as String?;
    _telephoneClient = snapshotData['telephoneClient'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _compteVerifie = snapshotData['compteVerifie'] as bool?;
    _airtableUserID = snapshotData['AirtableUserID'] as String?;
  }

  static CollectionReference get collection => FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: '(default)')
      .collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? nom,
  String? prenom,
  String? userType,
  String? adresseClientL1,
  String? adresseClientL2,
  String? codePostalClient,
  String? villeClient,
  String? adresseLivraisonL1,
  String? adresseLivraisonL2,
  String? codePotalLivraison,
  String? villeLivraison,
  String? paysLivraison,
  String? paysClient,
  String? telephoneClient,
  String? phoneNumber,
  bool? compteVerifie,
  String? airtableUserID,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'Nom': nom,
      'Prenom': prenom,
      'UserType': userType,
      'adresseClientL1': adresseClientL1,
      'adresseClientL2': adresseClientL2,
      'codePostalClient': codePostalClient,
      'villeClient': villeClient,
      'adresseLivraisonL1': adresseLivraisonL1,
      'adresseLivraisonL2': adresseLivraisonL2,
      'codePotalLivraison': codePotalLivraison,
      'villeLivraison': villeLivraison,
      'paysLivraison': paysLivraison,
      'paysClient': paysClient,
      'telephoneClient': telephoneClient,
      'phone_number': phoneNumber,
      'compteVerifie': compteVerifie,
      'AirtableUserID': airtableUserID,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.nom == e2?.nom &&
        e1?.prenom == e2?.prenom &&
        e1?.userType == e2?.userType &&
        e1?.adresseClientL1 == e2?.adresseClientL1 &&
        e1?.adresseClientL2 == e2?.adresseClientL2 &&
        e1?.codePostalClient == e2?.codePostalClient &&
        e1?.villeClient == e2?.villeClient &&
        e1?.adresseLivraisonL1 == e2?.adresseLivraisonL1 &&
        e1?.adresseLivraisonL2 == e2?.adresseLivraisonL2 &&
        e1?.codePotalLivraison == e2?.codePotalLivraison &&
        e1?.villeLivraison == e2?.villeLivraison &&
        e1?.paysLivraison == e2?.paysLivraison &&
        e1?.paysClient == e2?.paysClient &&
        e1?.telephoneClient == e2?.telephoneClient &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.compteVerifie == e2?.compteVerifie &&
        e1?.airtableUserID == e2?.airtableUserID;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.nom,
        e?.prenom,
        e?.userType,
        e?.adresseClientL1,
        e?.adresseClientL2,
        e?.codePostalClient,
        e?.villeClient,
        e?.adresseLivraisonL1,
        e?.adresseLivraisonL2,
        e?.codePotalLivraison,
        e?.villeLivraison,
        e?.paysLivraison,
        e?.paysClient,
        e?.telephoneClient,
        e?.phoneNumber,
        e?.compteVerifie,
        e?.airtableUserID
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
