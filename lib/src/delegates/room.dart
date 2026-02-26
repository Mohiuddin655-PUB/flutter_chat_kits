import '../models/room.dart';

abstract class ChatRoomDelegate {
  Future<void> create(String roomId, Map<String, dynamic> value);

  Future<Room> get(String roomId);

  Future<void> update(String roomId, Map<String, dynamic> value);

  Future<void> delete(String roomId);

  Stream<List<Room>> stream(String uid);
}
