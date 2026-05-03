import 'package:equatable/equatable.dart';

import '../core/room_manager.dart';
import 'profile.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

class TypingKeys {
  final String id;
  final String roomId;

  static TypingKeys get i => RoomManager.i.modelConfigs.typingKeys;

  const TypingKeys({this.id = 'id', this.roomId = 'roomId'});
}

// ── Model ─────────────────────────────────────────────────────────────────────

class Typing extends Equatable {
  final String id;
  final String roomId;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isEmpty => id.isEmpty || roomId.isEmpty;

  Profile get profile => RoomManager.i.profileFor(id);

  // ── Constructors ───────────────────────────────────────────────────────────

  const Typing({required this.id, required this.roomId});

  const Typing._({this.id = '', this.roomId = ''});

  const Typing.empty() : this._();

  // ── Parse ──────────────────────────────────────────────────────────────────

  factory Typing.parse(Object? source) {
    if (source is Typing) return source;
    if (source is! Map) return const Typing.empty();

    final keys = TypingKeys.i;
    final id = source[keys.id];
    final roomId = source[keys.roomId];

    return Typing._(
      id: id is String ? id : '',
      roomId: roomId is String ? roomId : '',
    );
  }

  // ── Equatable ──────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [id, roomId];
}
