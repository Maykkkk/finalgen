import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MessagesRecord extends FirestoreRecord {
  MessagesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "senderId" field.
  String? _senderId;
  String get senderId => _senderId ?? '';
  bool hasSenderId() => _senderId != null;

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  bool hasText() => _text != null;

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  bool hasRole() => _role != null;

  // "response" field.
  String? _response;
  String get response => _response ?? '';
  bool hasResponse() => _response != null;

  // "feedback" field.
  String? _feedback;
  String get feedback => _feedback ?? '';
  bool hasFeedback() => _feedback != null;

  // "needsContinuation" field.
  bool? _needsContinuation;
  bool get needsContinuation => _needsContinuation ?? false;
  bool hasNeedsContinuation() => _needsContinuation != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _senderId = snapshotData['senderId'] as String?;
    _text = snapshotData['text'] as String?;
    _role = snapshotData['role'] as String?;
    _response = snapshotData['response'] as String?;
    _feedback = snapshotData['feedback'] as String?;
    _needsContinuation = snapshotData['needsContinuation'] as bool?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('messages')
          : FirebaseFirestore.instance.collectionGroup('messages');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('messages').doc(id);

  static Stream<MessagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MessagesRecord.fromSnapshot(s));

  static Future<MessagesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MessagesRecord.fromSnapshot(s));

  static MessagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MessagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MessagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MessagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MessagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MessagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMessagesRecordData({
  DateTime? createdAt,
  String? senderId,
  String? text,
  String? role,
  String? response,
  String? feedback,
  bool? needsContinuation,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'createdAt': createdAt,
      'senderId': senderId,
      'text': text,
      'role': role,
      'response': response,
      'feedback': feedback,
      'needsContinuation': needsContinuation,
    }.withoutNulls,
  );

  return firestoreData;
}

class MessagesRecordDocumentEquality implements Equality<MessagesRecord> {
  const MessagesRecordDocumentEquality();

  @override
  bool equals(MessagesRecord? e1, MessagesRecord? e2) {
    return e1?.createdAt == e2?.createdAt &&
        e1?.senderId == e2?.senderId &&
        e1?.text == e2?.text &&
        e1?.role == e2?.role &&
        e1?.response == e2?.response &&
        e1?.feedback == e2?.feedback &&
        e1?.needsContinuation == e2?.needsContinuation;
  }

  @override
  int hash(MessagesRecord? e) => const ListEquality().hash([
        e?.createdAt,
        e?.senderId,
        e?.text,
        e?.role,
        e?.response,
        e?.feedback,
        e?.needsContinuation
      ]);

  @override
  bool isValidKey(Object? o) => o is MessagesRecord;
}
