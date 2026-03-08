import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ScansRecord extends FirestoreRecord {
  ScansRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "owner" field.
  DocumentReference? _owner;
  DocumentReference? get owner => _owner;
  bool hasOwner() => _owner != null;

  // "product_image" field.
  String? _productImage;
  String get productImage => _productImage ?? '';
  bool hasProductImage() => _productImage != null;

  // "product_name" field.
  String? _productName;
  String get productName => _productName ?? '';
  bool hasProductName() => _productName != null;

  // "brand_name" field.
  String? _brandName;
  String get brandName => _brandName ?? '';
  bool hasBrandName() => _brandName != null;

  // "ingredients" field.
  String? _ingredients;
  String get ingredients => _ingredients ?? '';
  bool hasIngredients() => _ingredients != null;

  // "warnings" field.
  List<String>? _warnings;
  List<String> get warnings => _warnings ?? const [];
  bool hasWarnings() => _warnings != null;

  // "benefits" field.
  List<String>? _benefits;
  List<String> get benefits => _benefits ?? const [];
  bool hasBenefits() => _benefits != null;

  // "recommendation" field.
  String? _recommendation;
  String get recommendation => _recommendation ?? '';
  bool hasRecommendation() => _recommendation != null;

  // "impact_for_user" field.
  String? _impactForUser;
  String get impactForUser => _impactForUser ?? '';
  bool hasImpactForUser() => _impactForUser != null;

  // "health_score" field.
  String? _healthScore;
  String get healthScore => _healthScore ?? '';
  bool hasHealthScore() => _healthScore != null;

  // "scan_date" field.
  DateTime? _scanDate;
  DateTime? get scanDate => _scanDate;
  bool hasScanDate() => _scanDate != null;

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

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

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  void _initializeFields() {
    _owner = snapshotData['owner'] as DocumentReference?;
    _productImage = snapshotData['product_image'] as String?;
    _productName = snapshotData['product_name'] as String?;
    _brandName = snapshotData['brand_name'] as String?;
    _ingredients = snapshotData['ingredients'] as String?;
    _warnings = getDataList(snapshotData['warnings']);
    _benefits = getDataList(snapshotData['benefits']);
    _recommendation = snapshotData['recommendation'] as String?;
    _impactForUser = snapshotData['impact_for_user'] as String?;
    _healthScore = snapshotData['health_score'] as String?;
    _scanDate = snapshotData['scan_date'] as DateTime?;
    _userId = snapshotData['user_id'] as String?;
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('scans');

  static Stream<ScansRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ScansRecord.fromSnapshot(s));

  static Future<ScansRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ScansRecord.fromSnapshot(s));

  static ScansRecord fromSnapshot(DocumentSnapshot snapshot) => ScansRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ScansRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ScansRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ScansRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ScansRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createScansRecordData({
  DocumentReference? owner,
  String? productImage,
  String? productName,
  String? brandName,
  String? ingredients,
  List<String>? warnings,
  List<String>? benefits,
  String? recommendation,
  String? impactForUser,
  String? healthScore,
  DateTime? scanDate,
  String? userId,
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'owner': owner,
      'product_image': productImage,
      'product_name': productName,
      'brand_name': brandName,
      'ingredients': ingredients,
      'warnings': warnings,
      'benefits': benefits,
      'recommendation': recommendation,
      'impact_for_user': impactForUser,
      'health_score': healthScore,
      'scan_date': scanDate,
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
    }.withoutNulls,
  );

  return firestoreData;
}

class ScansRecordDocumentEquality implements Equality<ScansRecord> {
  const ScansRecordDocumentEquality();

  @override
  bool equals(ScansRecord? e1, ScansRecord? e2) {
    return e1?.owner == e2?.owner &&
        e1?.productImage == e2?.productImage &&
      e1?.productName == e2?.productName &&
      e1?.brandName == e2?.brandName &&
        e1?.ingredients == e2?.ingredients &&
      const ListEquality().equals(e1?.warnings, e2?.warnings) &&
      const ListEquality().equals(e1?.benefits, e2?.benefits) &&
      e1?.recommendation == e2?.recommendation &&
      e1?.impactForUser == e2?.impactForUser &&
        e1?.healthScore == e2?.healthScore &&
        e1?.scanDate == e2?.scanDate &&
        e1?.userId == e2?.userId &&
        e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber;
  }

  @override
  int hash(ScansRecord? e) => const ListEquality().hash([
        e?.owner,
        e?.productImage,
        e?.productName,
        e?.brandName,
        e?.ingredients,
        e?.warnings,
        e?.benefits,
        e?.recommendation,
        e?.impactForUser,
        e?.healthScore,
        e?.scanDate,
        e?.userId,
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber
      ]);

  @override
  bool isValidKey(Object? o) => o is ScansRecord;
}
