import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import '../push_notification.dart';

const kChatPushNotificationRoomId = "roomId";
const kChatPushNotificationSourceType = "chat";

class ChatNotificationService extends ChatNotificationDelegate {
  @override
  Future<String?> deviceToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> send(ChatNotificationContent content) async {
    await PushNotifications.send(
      id: content.id,
      token: content.token,
      title: content.title,
      body: content.body,
      sourceType: kChatPushNotificationSourceType,
      platformType: content.platform,
      data: {kChatPushNotificationRoomId: content.roomId},
    );
  }
}
