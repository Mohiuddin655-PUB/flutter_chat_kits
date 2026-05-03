abstract class ChatCacheDelegate {
  Future<String?> read(String key);

  Future<bool> write(String key, String? value);
}
