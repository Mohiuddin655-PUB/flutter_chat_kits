import '../models/typing.dart' show Typing;

abstract class ChatTypingDelegate {
  Future<void> start(String roomId, String uid);

  Future<void> end(String uid);

  Stream<Typing> stream(String uid);
}
