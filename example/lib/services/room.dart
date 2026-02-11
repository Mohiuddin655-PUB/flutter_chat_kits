import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

const kChatRoomsPath = "rooms";

class ChatRoomService extends ChatRoomDelegate {
  final _ref = FirebaseFirestore.instance.collection(kChatRoomsPath);

  @override
  Future<void> create(String roomId, Map<String, dynamic> value) async {
    return _ref.doc(roomId).set(value, SetOptions(merge: true));
  }

  @override
  Future<Room> get(String roomId) {
    return _ref.doc(roomId).get().then((event) {
      final data = event.data();
      if (!event.exists || data == null || data.isEmpty) return Room.empty();
      final value = Room.parse(event.data());
      return value;
    });
  }

  @override
  Future<void> update(String roomId, Map<String, dynamic> value) async {
    return _ref.doc(roomId).update(value);
  }

  @override
  Stream<List<Room>> stream(String uid) {
    return _ref
        .where(RoomKeys.participants, arrayContains: uid)
        .orderBy(RoomKeys.updatedAt, descending: true)
        .snapshots()
        .map((event) {
      final value = event.docs.map((e) => Room.parse(e.data())).toList();
      return value;
    });
  }
}
