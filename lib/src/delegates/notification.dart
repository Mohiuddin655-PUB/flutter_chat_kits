class ChatNotificationContent {
  final String id;
  final String roomId;
  final String title;
  final String body;
  final String token;
  final String platform;

  const ChatNotificationContent({
    required this.id,
    required this.roomId,
    required this.title,
    required this.body,
    required this.token,
    required this.platform,
  });
}

abstract class ChatNotificationDelegate {
  Future<String?> deviceToken();

  Future<void> send(ChatNotificationContent content);
}
