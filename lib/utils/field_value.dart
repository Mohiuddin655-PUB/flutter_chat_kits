import '../core/room_manager.dart';

// ── Base ──────────────────────────────────────────────────────────────────────

abstract class ChatValue {
  const ChatValue();
}

// ── Primitives ────────────────────────────────────────────────────────────────

class ChatValueDelete extends ChatValue {
  const ChatValueDelete();
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

// ── Timestamp ─────────────────────────────────────────────────────────────────

class ChatValueTimestamp extends ChatValue {
  final DateTime? timestampOrNull;

  // ── Constructors ───────────────────────────────────────────────────────────

  /// Empty timestamp — use [isEmpty] before accessing [timestamp].
  const ChatValueTimestamp() : timestampOrNull = null;

  const ChatValueTimestamp._(this.timestampOrNull);

  ChatValueTimestamp.now() : timestampOrNull = DateTime.now();

  factory ChatValueTimestamp.fromDateTime(DateTime dateTime) {
    return ChatValueTimestamp._(dateTime);
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isEmpty => timestampOrNull == null;

  /// Always check [isEmpty] before using this.
  /// Falls back to [DateTime.now] if timestamp is null.
  DateTime get timestamp => timestampOrNull ?? DateTime.now();

  DateTime get normalized {
    final date = timestamp;
    return DateTime(date.year, date.month, date.day);
  }

  // ── Parse ──────────────────────────────────────────────────────────────────

  static ChatValueTimestamp? tryParse(Object? source) {
    if (source is ChatValueTimestamp) return source;
    if (source is DateTime) return ChatValueTimestamp._(source);

    if (source is String) {
      final parsed = DateTime.tryParse(source);
      if (parsed != null) return ChatValueTimestamp._(parsed);
      return null;
    }

    if (source is num && source > 0) {
      return ChatValueTimestamp._(
        DateTime.fromMillisecondsSinceEpoch(source.toInt()),
      );
    }

    return null;
  }

  static ChatValueTimestamp parse(Object? source) {
    return tryParse(source) ?? RoomManager.i.timestamp(source);
  }

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  int get hashCode => timestampOrNull.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ChatValueTimestamp &&
        other.timestampOrNull == timestampOrNull;
  }
}
