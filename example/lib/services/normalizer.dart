import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatFieldValueNormalizerService extends ChatFieldValueNormalizer {
  Object? _firebase(Object? raw) {
    if (raw is ChatValueIncrement) {
      return ServerValue.increment(raw.value);
    }
    if (raw is ChatValueTimestamp) {
      return ServerValue.timestamp;
    }
    if (raw is ChatValueDelete) {
      return null;
    }
    if (raw is ChatValueAdd) {
      return null;
    }
    if (raw is ChatValueRemove) {
      return null;
    }
    return null;
  }

  Object? _firestore(Object? raw) {
    if (raw is ChatValueIncrement) {
      return FieldValue.increment(raw.value);
    }
    if (raw is ChatValueTimestamp) {
      return FieldValue.serverTimestamp();
    }
    if (raw is ChatValueDelete) {
      return FieldValue.delete();
    }
    if (raw is ChatValueAdd) {
      return FieldValue.arrayUnion(raw.value);
    }
    if (raw is ChatValueRemove) {
      return FieldValue.arrayRemove(raw.value);
    }
    return null;
  }

  @override
  ChatValueTimestamp timestamp(Object? raw) {
    if (raw is Timestamp) {
      return ChatValueTimestamp.fromDateTime(raw.toDate());
    }
    return ChatValueTimestamp();
  }

  @override
  Object? message(Object? raw) => _firestore(raw);

  @override
  Object? profile(Object? raw) => _firestore(raw);

  @override
  Object? room(Object? raw) => _firestore(raw);

  @override
  Object? status(Object? raw) => _firebase(raw);

  @override
  Object? typing(Object? raw) => _firebase(raw);
}
