import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

import 'notification_delegate.dart';
import 'push_notification.dart';

@pragma('vm:entry-point')
class InAppNotifications {
  InAppNotifications._();

  static const idBasicChannel = "basic_channel";

  static bool initialized = false;

  static AwesomeNotifications get _n => AwesomeNotifications();

  static Future<bool> get isPermissionAllow async {
    try {
      if (kIsWeb) return true;
      return _n.isNotificationAllowed();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isPermissionNotAllow async {
    return !(await isPermissionAllow);
  }

  static Future<bool> requestPermission() async {
    if (await isPermissionNotAllow) {
      return _n.requestPermissionToSendNotifications();
    }
    return true;
  }

  static Future<void> channel(NotificationChannel channel) async {
    if (!initialized) return;
    try {
      return await _n.setChannel(channel);
    } catch (_) {}
  }

  static Future<void> channels(Iterable<NotificationChannel> values) async {
    if (!initialized) return;
    try {
      await Future.wait(values.map(channel));
    } catch (_) {}
  }

  static Future<void> cancelNotificationsByChannelKey(String channelKey) async {
    if (!initialized) return;
    await _n.cancelNotificationsByChannelKey(channelKey);
  }

  static Future<void> cancelSchedulesByChannelKey(String channelKey) async {
    if (!initialized) return;
    await _n.cancelSchedulesByChannelKey(channelKey);
  }

  static Future<bool> createFromMap(Map<String, dynamic> value) async {
    if (!initialized) return false;
    return _n.createNotificationFromJsonData(value);
  }

  static void dispose() {}

  static ReceivedAction? initialReceivedAction;

  @pragma('vm:entry-point')
  static Future<void> _clicked(ReceivedAction receivedAction) async {
    final notificationId = receivedAction.id ?? 0;
    log("Notification clicked: $notificationId");
    String? channelKey = receivedAction.channelKey;
    String? sourceType = receivedAction.payload?['sourceType'];
    String? pChannelKey = receivedAction.payload?['channelKey'] ??
        receivedAction.payload?['nKey'];
    if ([channelKey, pChannelKey].contains(kPushNotificationChannel)) {
      NotificationDelegate.opened(receivedAction, sourceType);
    } else {
      NotificationDelegate.clicked(receivedAction);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _created(ReceivedNotification notification) async {
    log('Notification created: ${notification.title}');
    NotificationDelegate.created(notification);
  }

  @pragma('vm:entry-point')
  static Future<void> _displayed(
    ReceivedNotification receivedNotification,
  ) async {
    log('Notification displayed: ${receivedNotification.title}');
    NotificationDelegate.displayed(receivedNotification);
  }

  @pragma('vm:entry-point')
  static Future<void> _received(ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.title}');
    NotificationDelegate.dismissed(receivedAction);
  }

  @pragma('vm:entry-point')
  static Future<void> init({bool request = true}) async {
    if (kIsWeb) return;

    if (await isPermissionNotAllow) {
      if (!request) return;
      await requestPermission();
    }

    if (await isPermissionNotAllow) {
      return;
    }

    await _n.cancelAll();
    initialized = await _n.initialize(
      null,
      [
        NotificationChannel(
          channelKey: kPushNotificationChannel,
          channelName: 'Push notification channel',
          channelDescription: 'test',
        ),
      ],
      debug: true,
    );

    _n.getInitialNotificationAction().then((action) {
      if (action != null) {
        initialReceivedAction = action;
        _clicked(action);
      }
    });

    await _n.resetGlobalBadge();

    _n.setListeners(
      onActionReceivedMethod: _clicked,
      onNotificationCreatedMethod: _created,
      onNotificationDisplayedMethod: _displayed,
      onDismissActionReceivedMethod: _received,
    );

    NotificationDelegate.initialized();
  }
}
