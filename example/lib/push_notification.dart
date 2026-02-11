import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const kPushNotificationChannel = 'push_notification_channel';

class PushNotifications {
  const PushNotifications._();

  static const projectId = 'YOUR_FIREBASE_PROJECT_ID';

  static const json = {};

  static final String baseUrl =
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

  static String _token = '';

  static Future<String?> serviceToken([bool fresh = false]) async {
    try {
      if (!fresh && _token.isNotEmpty) return _token;
      final raw = await rootBundle.loadString(
        'assets/secrets/push_notification.json',
      );
      final accountCredentials = ServiceAccountCredentials.fromJson(raw);
      final client = await clientViaServiceAccount(accountCredentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);
      final credentials = client.credentials;
      client.close();
      _token = credentials.accessToken.data;
      return _token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _regenerateTokenIfNotValid() async {
    final isValid = _token.isEmpty ? false : await validateToken(_token);
    if (isValid) return;
    serviceToken(true);
  }

  static Future<Map<String, dynamic>?> send({
    required String id,
    required String token,
    required String title,
    required String body,
    required String sourceType,
    required String platformType,
    Map<String, String>? data,
  }) async {
    final accessToken = await PushNotifications.serviceToken();
    if (accessToken == null || accessToken.isEmpty) return null;
    Map<String, dynamic> message = {};
    if (platformType == 'ios') {
      message = {
        "message": {
          "token": token,

          // iOS visible notification
          "notification": {"title": title, "body": body},

          // iOS APNs configuration
          "apns": {
            "headers": {
              "apns-priority": "10", // 10 = immediate
              "apns-push-type": "alert", // mandatory for iOS 13+
            },
            "payload": {
              "aps": {
                "alert": {"title": title, "body": body},
                "sound": "default",
                "badge": 1,
              },
            },
          },

          // custom data payload
          "data": {
            "id": id,
            "title": title,
            "body": body,
            "channelKey": kPushNotificationChannel,
            "nKey": kPushNotificationChannel,
            "sourceType": sourceType,
            if (data != null) ...data,
          },
        },
      };
    } else {
      message = {
        "message": {
          "token": token,
          "data": {
            "id": id,
            "title": title,
            "body": body,
            "channelKey": kPushNotificationChannel,
            "sourceType": sourceType,
            if (data != null) ...data,
          },
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        log('Message sent successfully: $result');
      } else {
        log('Error sending message: $result');
      }
      _regenerateTokenIfNotValid();
      return result;
    } catch (e) {
      log('HTTP request error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> topic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final accessToken = await serviceToken();
    if (accessToken == null || accessToken.isEmpty) return null;
    final message = {
      'message': {
        'topic': topic,
        'notification': {'title': title, 'body': body},
        if (data != null) 'data': data,
      },
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        log('Message sent to topic successfully: $result');
      } else {
        log('Error sending message to topic: $result');
      }
      _regenerateTokenIfNotValid();
      return result;
    } catch (e) {
      log('HTTP request error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> multicast({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final accessToken = await serviceToken();
    if (accessToken == null || accessToken.isEmpty) return null;
    final results = <Map<String, dynamic>>[];
    for (String token in tokens) {
      final message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          if (data != null) 'data': data,
        },
      };

      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(message),
        );

        final result = jsonDecode(response.body);
        results.add({
          'token': token,
          'result': result,
          'success': response.statusCode == 200,
        });

        log('Token: $token, Success: ${response.statusCode == 200}');
      } catch (e) {
        log('Error sending to token $token: $e');
        results.add({'token': token, 'error': e.toString(), 'success': false});
      }
    }
    _regenerateTokenIfNotValid();
    return {'results': results};
  }

  static Future<bool> validateToken(String accessToken) async {
    final testMessage = {
      'message': {
        'token': 'test_token',
        'notification': {'title': 'Test', 'body': 'Test message'},
      },
      'validate_only': true,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(testMessage),
      );
      return response.statusCode != 401 && response.statusCode != 403;
    } catch (e) {
      log('Error validating token: $e');
      return false;
    }
  }
}

/// Usage example
// void main() async {
//   try {
//     final s = await PushNotifications.send(
//       token:
//           'eC56oLP9TvG_56RYai86z6:APA91bHE0Cb1SaVMaiCyaOwDERagSPKwXSC7wAqoihPndJnN6wl53syaUcsjgIs_ZpzmCB8-PyhNN2JIQRa2NkJraQKfAPGi1wh9P58vrniBhQH0Yqkiy68',
//       title: 'Test Title',
//       body: 'Test message body',
//       data: {'customKey': 'customValue'},
//       id: '',
//       sourceType: 'abc',
//       platformType: 'ios',
//     );
//     log(s.toString());
//   } catch (e) {
//     print('Error in main: $e');
//   }
// }
