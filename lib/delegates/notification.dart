import '../models/profile.dart';

class ChatNotificationContent {
  final String id;
  final String roomId;
  final String title;
  final String body;
  final String token;
  final String platform;
  final Profile? profile;
  final int retryCount;
  final DateTime? expiresAt;

  const ChatNotificationContent({
    required this.id,
    required this.roomId,
    required this.title,
    required this.body,
    required this.token,
    required this.platform,
    this.profile,
    this.retryCount = 0,
    this.expiresAt,
  });

  bool get isValid => token.isNotEmpty;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  ChatNotificationContent copyWith({int? retryCount}) {
    return ChatNotificationContent(
      id: id,
      roomId: roomId,
      title: title,
      body: body,
      token: token,
      platform: platform,
      profile: profile,
      retryCount: retryCount ?? this.retryCount,
      expiresAt: expiresAt,
    );
  }
}

abstract class ChatNotificationDelegate {
  Stream<String?> get onTokenRefresh;

  Future<bool> isTokenValid(String? token);

  Future<String?> fetchToken();

  Future<void> deleteToken();

  Future<void> sendNotification(ChatNotificationContent content);
}
