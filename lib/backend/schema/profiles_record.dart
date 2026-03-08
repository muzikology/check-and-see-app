import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProfilesRecord extends FirestoreRecord {
  ProfilesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "age" field.
  int? _age;
  int get age => _age ?? 0;
  bool hasAge() => _age != null;

  // "skin_type" field.
  String? _skinType;
  String get skinType => _skinType ?? '';
  bool hasSkinType() => _skinType != null;

  // "allergies" field.
  String? _allergies;
  String get allergies => _allergies ?? '';
  bool hasAllergies() => _allergies != null;

  // "diet_type" field.
  String? _dietType;
  String get dietType => _dietType ?? '';
  bool hasDietType() => _dietType != null;

  // "weight_goal" field.
  String? _weightGoal;
  String get weightGoal => _weightGoal ?? '';
  bool hasWeightGoal() => _weightGoal != null;

  // "skin_concerns" field.
  String? _skinConcerns;
  String get skinConcerns => _skinConcerns ?? '';
  bool hasSkinConcerns() => _skinConcerns != null;

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
    _age = castToType<int>(snapshotData['age']);
    _skinType = snapshotData['skin_type'] as String?;
    _allergies = snapshotData['allergies'] as String?;
    _dietType = snapshotData['diet_type'] as String?;
    _weightGoal = snapshotData['weight_goal'] as String?;
    _skinConcerns = snapshotData['skin_concerns'] as String?;
    _userId = snapshotData['user_id'] as String?;
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('profiles');

  static Stream<ProfilesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProfilesRecord.fromSnapshot(s));

  static Future<ProfilesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ProfilesRecord.fromSnapshot(s));

  static ProfilesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProfilesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProfilesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProfilesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProfilesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProfilesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProfilesRecordData({
  int? age,
  String? skinType,
  String? allergies,
  String? dietType,
  String? weightGoal,
  String? skinConcerns,
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
      'age': age,
      'skin_type': skinType,
      'allergies': allergies,
      'diet_type': dietType,
      'weight_goal': weightGoal,
      'skin_concerns': skinConcerns,
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

class ProfilesRecordDocumentEquality implements Equality<ProfilesRecord> {
  const ProfilesRecordDocumentEquality();

  @override
  bool equals(ProfilesRecord? e1, ProfilesRecord? e2) {
    return e1?.age == e2?.age &&
        e1?.skinType == e2?.skinType &&
        e1?.allergies == e2?.allergies &&
        e1?.dietType == e2?.dietType &&
        e1?.weightGoal == e2?.weightGoal &&
        e1?.skinConcerns == e2?.skinConcerns &&
        e1?.userId == e2?.userId &&
        e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber;
  }

  @override
  int hash(ProfilesRecord? e) => const ListEquality().hash([
        e?.age,
        e?.skinType,
        e?.allergies,
        e?.dietType,
        e?.weightGoal,
        e?.skinConcerns,
        e?.userId,
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber
      ]);

  @override
  bool isValidKey(Object? o) => o is ProfilesRecord;
}
