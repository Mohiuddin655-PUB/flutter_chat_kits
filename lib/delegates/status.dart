import '../models/status.dart' show Status;

abstract class ChatStatusDelegate {
  Future<void> online(String uid, Map<String, dynamic> value);

  Future<void> offline(String uid, Map<String, dynamic> value);

  Stream<Status> stream(String uid);
}
