import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import '../utils/field_value.dart';

class StatusKeys {
  final String isOnline;
  final String lastSeen;

  static StatusKeys get i => RoomManager.i.modelConfigs.statusKeys;

  const StatusKeys({this.isOnline = 'isOnline', this.lastSeen = 'lastSeen'});
}

class Status extends Equatable {
  final bool isOnline;
  final ChatValueTimestamp lastSeen;

  const Status.empty() : this._(lastSeen: const ChatValueTimestamp());

  const Status._({this.isOnline = false, required this.lastSeen});

  const Status({required this.isOnline, required this.lastSeen});

  factory Status.parse(Object? source) {
    if (source is Status) return source;
    if (source is! Map) return Status.empty();
    final keys = StatusKeys.i;
    final isOnline = source[keys.isOnline];
    final lastSeen = source[keys.lastSeen];
    return Status._(
      isOnline: isOnline is bool ? isOnline : false,
      lastSeen: ChatValueTimestamp.parse(lastSeen),
    );
  }

  Map<String, dynamic> get source {
    final keys = StatusKeys.i;
    return {
      if (isOnline) keys.isOnline: isOnline,
      if (!lastSeen.isEmpty) keys.lastSeen: lastSeen,
    };
  }

  @override
  List<Object?> get props {
    return [isOnline, lastSeen];
  }
}
