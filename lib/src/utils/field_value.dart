import '../managers/room.dart';

abstract class ChatValue {
  const ChatValue();
}

class ChatValueIncrement extends ChatValue {
  final int value;

  const ChatValueIncrement(this.value);
}

class ChatValueAdd extends ChatValue {
  final List<Object?> value;

  const ChatValueAdd(this.value);
}

class ChatValueRemove extends ChatValue {
  final List<Object?> value;

  const ChatValueRemove(this.value);
}

class ChatValueTimestamp extends ChatValue {
  final DateTime? timestampOrNull;

  bool get isEmpty => timestampOrNull == null;

  DateTime get timestamp => timestampOrNull ?? DateTime.now();

  DateTime get normalized {
    final date = timestamp;
    return DateTime(date.year, date.month, date.day);
  }

  const ChatValueTimestamp() : timestampOrNull = null;

  const ChatValueTimestamp._(this.timestampOrNull);

  ChatValueTimestamp.now() : timestampOrNull = DateTime.now();

  factory ChatValueTimestamp.fromDateTime(DateTime dateTime) {
    return ChatValueTimestamp._(dateTime);
  }

  factory ChatValueTimestamp.parse(Object? source) {
    if (source is ChatValueTimestamp) {
      return source;
    }

    if (source is DateTime) {
      return ChatValueTimestamp._(source);
    }
    if (source is String) {
      final timestamp = DateTime.tryParse(source);
      if (timestamp != null) {
        return ChatValueTimestamp._(timestamp);
      }
    } else if (source is num) {
      if (source > 0) {
        return ChatValueTimestamp._(
          DateTime.fromMillisecondsSinceEpoch(source.toInt()),
        );
      }
    } else {
      return RoomManager.i.timestamp(source);
    }
    return ChatValueTimestamp();
  }

  @override
  int get hashCode => timestampOrNull.hashCode;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) return false;
    if (other is! ChatValueTimestamp) return false;
    return other.timestampOrNull == timestampOrNull;
  }
}

class ChatValueDelete extends ChatValue {
  const ChatValueDelete();
}
