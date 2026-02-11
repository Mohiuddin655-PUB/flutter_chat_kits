import 'package:equatable/equatable.dart';

import '../utils/field_value.dart';

final class StatusKeys {
  const StatusKeys._();

  static const isOnline = 'isOnline';
  static const lastSeen = 'lastSeen';
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
    final isOnline = source[StatusKeys.isOnline];
    final lastSeen = source[StatusKeys.lastSeen];
    return Status._(
      isOnline: isOnline is bool ? isOnline : false,
      lastSeen: ChatValueTimestamp.parse(lastSeen),
    );
  }

  Map<String, dynamic> get source {
    return {
      if (isOnline) StatusKeys.isOnline: isOnline,
      if (!lastSeen.isEmpty) StatusKeys.lastSeen: lastSeen,
    };
  }

  @override
  List<Object?> get props {
    return [isOnline, lastSeen];
  }
}
