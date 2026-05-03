import 'dart:convert' show utf8;
import 'dart:math' show Random;

import 'package:crypto/crypto.dart' show sha256;

class ChatHelper {
  ChatHelper._();

  static final Random _random = Random.secure();

  static String generateThreadId(String me, String friend) {
    final userIds = [me, friend]..sort();
    final combined = '${userIds[0]}:${userIds[1]}';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return 't_${hash.toString().substring(0, 20)}';
  }

  static String generateGroupId() {
    final timePart = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(900000) + 100000;
    return 'g_$timePart$randomPart';
  }

  static String generateMessageId() {
    final timePart = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(900000) + 100000;
    return 'm_$timePart$randomPart';
  }
}
