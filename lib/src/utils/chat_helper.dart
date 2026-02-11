import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class ChatHelper {
  ChatHelper._();

  static String generateThreadId(String me, String friend) {
    final userIds = [me, friend]..sort();
    final combined = '${userIds[0]}:${userIds[1]}';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return 't_${hash.toString().substring(0, 20)}';
  }

  static String generateGroupId() {
    final random = Random.secure();
    final randomPart = random.nextInt(900000) + 100000;
    final timePart = DateTime.now().microsecondsSinceEpoch;
    return 'g_$timePart$randomPart';
  }

  static String generateMessageId() {
    final timePart = DateTime.now().microsecondsSinceEpoch;
    return '$timePart';
  }
}
