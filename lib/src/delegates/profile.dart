import '../models/profile.dart';

abstract class ChatProfileDelegate {
  Future<void> update(String uid, Map<String, dynamic> value);

  Stream<Profile> stream(String uid);
}
