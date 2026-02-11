import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import 'profile.dart';

final class TypingKeys {
  const TypingKeys._();

  static const roomId = 'roomId';
}

class Typing extends Equatable {
  final String id;
  final String roomId;

  bool get isEmpty => id.isEmpty || roomId.isEmpty;

  Profile get profile => RoomManager.i.profileFor(id);

  const Typing.empty() : this._();

  const Typing._({this.id = '', this.roomId = ''});

  const Typing({required this.id, required this.roomId});

  @override
  List<Object?> get props {
    return [id, roomId];
  }
}
