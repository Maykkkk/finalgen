import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatsRecord extends FirestoreRecord {
  ChatsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  DocumentReference? _userId;
  DocumentReference? get userId => _userId;
  bool hasUserId() => _userId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updatedAt" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "lastMessagePreview" field.
  String? _lastMessagePreview;
  String get lastMessagePreview => _lastMessagePreview ?? '';
  bool hasLastMessagePreview() => _lastMessagePreview != null;

  // "pinned" field.
  bool? _pinned;
  bool get pinned => _pinned ?? false;
  bool hasPinned() => _pinned != null;

  // "archived" field.
  bool? _archived;
  bool get archived => _archived ?? false;
  bool hasArchived() => _archived != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as DocumentReference?;
    _title = snapshotData['title'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _updatedAt = snapshotData['updatedAt'] as DateTime?;
    _lastMessagePreview = snapshotData['lastMessagePreview'] as String?;
    _pinned = snapshotData['pinned'] as bool?;
    _archived = snapshotData['archived'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('chats');

  static Stream<ChatsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatsRecord.fromSnapshot(s));

  static Future<ChatsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatsRecord.fromSnapshot(s));

  static ChatsRecord fromSnapshot(DocumentSnapshot snapshot) => ChatsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatsRecordData({
  DocumentReference? userId,
  String? title,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? lastMessagePreview,
  bool? pinned,
  bool? archived,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessagePreview': lastMessagePreview,
      'pinned': pinned,
      'archived': archived,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatsRecordDocumentEquality implements Equality<ChatsRecord> {
  const ChatsRecordDocumentEquality();

  @override
  bool equals(ChatsRecord? e1, ChatsRecord? e2) {
    return e1?.userId == e2?.userId &&
        e1?.title == e2?.title &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.lastMessagePreview == e2?.lastMessagePreview &&
        e1?.pinned == e2?.pinned &&
        e1?.archived == e2?.archived;
  }

  @override
  int hash(ChatsRecord? e) => const ListEquality().hash([
        e?.userId,
        e?.title,
        e?.createdAt,
        e?.updatedAt,
        e?.lastMessagePreview,
        e?.pinned,
        e?.archived
      ]);

  @override
  bool isValidKey(Object? o) => o is ChatsRecord;
}
