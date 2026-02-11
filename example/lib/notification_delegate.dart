import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_notification.dart';

StreamSubscription? _msgSubscription;

class NotificationDelegate {
  const NotificationDelegate._();

  static Future<void> _show(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;
    final channel = (!kIsWeb && Platform.isAndroid
            ? notification?.android?.channelId
            : null) ??
        data['channelKey'];
    final title = notification?.title ?? data['title'];
    final body = notification?.body ?? data['body'];
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: channel is String && channel.isNotEmpty
            ? channel
            : kPushNotificationChannel,
        title: title is String ? title : title ?? '',
        body: body is String ? body : body ?? '',
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }

  static Future<void> initialized() async {
    _msgSubscription?.cancel();
    _msgSubscription = FirebaseMessaging.onMessage.listen(_show);
    FirebaseMessaging.onBackgroundMessage(_show);
  }

  static Future<void> opened(ReceivedAction action, String? source) async {
    final payload = action.payload ?? {};
    if (payload.isEmpty) return;
    if (source == 'chat') {
      final id = payload['roomId'] ?? '';
      log("ROOM_ID: $id");
    }
  }

  static Future<void> clicked(ReceivedAction action) async {}

  static Future<void> created(ReceivedNotification notification) async {}

  static Future<void> dismissed(ReceivedAction action) async {}

  static Future<void> displayed(ReceivedNotification notification) async {}
}
