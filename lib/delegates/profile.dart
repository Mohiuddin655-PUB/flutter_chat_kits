import '../models/profile.dart' show Profile;

abstract class ChatProfileDelegate {
  Future<void> update(String uid, Map<String, dynamic> value);

  Stream<Profile> stream(String uid);
}
