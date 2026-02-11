import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

const _kPath = "chats/typings";

class ChatTypingService extends ChatTypingDelegate {
  final _ref = FirebaseDatabase.instance.ref(_kPath);

  @override
  Future<void> end(String uid) {
    return _ref.child(uid).remove();
  }

  @override
  Future<void> start(String roomId, String uid) {
    return _ref.child(uid).set(roomId);
  }

  @override
  Stream<Typing> stream(String uid) {
    return _ref.child(uid).onValue.map((event) {
      final key = event.snapshot.key;
      final value = event.snapshot.value;
      if (key == null || value is! String || value.isEmpty) {
        return Typing.empty();
      }
      return Typing(id: key, roomId: value);
    });
  }
}
