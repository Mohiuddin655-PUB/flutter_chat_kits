import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

const _kPath = "chats/statuses";

class ChatStatusService extends ChatStatusDelegate {
  final _db = FirebaseDatabase.instance;
  late final _ref = _db.ref(_kPath);

  @override
  Future<void> offline(String uid, Map<String, dynamic> value) async {
    await _ref.child(uid).update(value);
  }

  @override
  Future<void> online(String uid, Map<String, dynamic> value) async {
    await _ref.child(uid).update(value);
  }

  @override
  Stream<Status> stream(String uid) {
    return _db.ref('$_kPath/$uid').onValue.map((event) {
      final value = event.snapshot.value;
      return Status.parse(value);
    });
  }
}
