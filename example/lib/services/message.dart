import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import 'room.dart';

const kChatMessagesPath = "messages";

class ChatMessageService extends ChatMessageDelegate {
  final _db = FirebaseFirestore.instance;
  final _st = FirebaseStorage.instance;
  late final _ref = _db.collection(kChatRoomsPath);
  late final _refSt = _st.ref(kChatRoomsPath);

  @override
  Future<void> create(
    String roomId,
    String msgId,
    Map<String, dynamic> value,
  ) async {
    await _ref.doc(roomId).collection(kChatMessagesPath).doc(msgId).set(value);
  }

  @override
  Future<void> delete(String roomId, String id) async {
    final ref = _ref.doc(roomId).collection(kChatMessagesPath).doc(id);
    await ref.delete();
  }

  @override
  Future<void> deletes(Iterable<Message> messages) async {
    final batch = _db.batch();
    for (final msg in messages) {
      final ref =
          _ref.doc(msg.roomId).collection(kChatMessagesPath).doc(msg.id);
      batch.delete(ref);
    }
    await batch.commit();
  }

  @override
  Future<void> update(
    String roomId,
    String id,
    Map<String, dynamic> value,
  ) async {
    final ref = _ref.doc(roomId).collection(kChatMessagesPath).doc(id);
    await ref.update(value);
  }

  @override
  Future<void> updates(
    String roomId,
    Map<String, Map<String, dynamic>> values,
  ) async {
    final batch = _db.batch();
    for (final entry in values.entries) {
      final ref = _ref.doc(roomId).collection(kChatMessagesPath).doc(entry.key);
      batch.update(ref, entry.value);
    }
    await batch.commit();
  }

  @override
  Stream<List<Message>> stream(String roomId) {
    return _ref
        .doc(roomId)
        .collection(kChatMessagesPath)
        .snapshots()
        .map((event) {
      final value = event.docs.map((e) => Message.parse(e.data())).toList();
      return value;
    });
  }

  @override
  Future<String> upload(MessageUploadData data) async {
    final file = File(data.path);
    final contentType = data.contentType;
    final ref = _refSt
        .child(data.roomId)
        .child(kChatMessagesPath)
        .child(data.msgId)
        .child(data.name);
    await ref.putFile(
      file,
      contentType != null ? SettableMetadata(contentType: contentType) : null,
    );
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Future<void> deleteFromStorage(String url) async {
    await FirebaseStorage.instance.refFromURL(url).delete();
  }
}
