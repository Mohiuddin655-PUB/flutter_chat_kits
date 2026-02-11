import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

const kChatUsersPath = "users";

class ChatProfileService extends ChatProfileDelegate {
  final _ref = FirebaseFirestore.instance.collection(kChatUsersPath);

  @override
  Future<void> update(String uid, Map<String, dynamic> value) async {
    await _ref.doc(uid).update(value);
  }

  @override
  Stream<Profile> stream(String uid) {
    return _ref.doc(uid).snapshots().map((event) {
      final value = Profile.parse(event.data());
      return value;
    });
  }
}
