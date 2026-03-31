import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import '../utils/parser.dart';

typedef ProfileExtra = Map<String, dynamic>;

class ProfileKeys {
  final String id;
  final String name;
  final String photo;
  final String platform;
  final String token;
  final String room;
  final String extra;

  static ProfileKeys get i => RoomManager.i.modelConfigs.profileKeys;

  const ProfileKeys({
    this.id = 'profile_id',
    this.name = 'display_name',
    this.photo = 'display_photo',
    this.platform = 'platform',
    this.token = 'device_token',
    this.room = 'active_room',
    this.extra = 'profile_extra',
  });
}

class Profile extends Equatable {
  final String id;
  final String? name;
  final String? photo;
  final String platform;
  final String token;
  final String? room;
  final ProfileExtra extra;

  bool get isEmpty {
    return id.isEmpty ||
        (name ?? '').isEmpty ||
        platform.isEmpty ||
        token.isEmpty;
  }

  String? get nameSymbol {
    return (name ?? '').isEmpty ? null : name![0].toUpperCase();
  }

  bool isActiveRoom(String roomId) {
    return roomId == room;
  }

  const Profile.empty() : this(id: '', name: '', platform: '', token: '');

  const Profile({
    required this.id,
    required this.name,
    this.photo,
    required this.platform,
    this.room,
    required this.token,
    this.extra = const {},
  });

  factory Profile.parse(Object? source, {ProfileExtra? extra}) {
    if (source is Profile) return source;
    if (source is! Map) return Profile.empty();
    final keys = ProfileKeys.i;
    final ex = source[keys.extra];
    final id = source[keys.id];
    final name = source[keys.name];
    final photo = source[keys.photo];
    final platform = source[keys.platform];
    final room = source[keys.room];
    final token = source[keys.token];
    return Profile(
      extra: extra ?? (ex is Map ? ex.parse() : {}),
      id: id is String && id.isNotEmpty ? id : '',
      name: name is String && name.isNotEmpty ? name : null,
      photo: photo is String && photo.isNotEmpty ? photo : null,
      platform: platform is String && platform.isNotEmpty ? platform : '',
      room: room is String && room.isNotEmpty ? room : null,
      token: token is String && token.isNotEmpty ? token : '',
    );
  }

  Map<String, dynamic> get source {
    final keys = ProfileKeys.i;
    return {
      if (id.isNotEmpty) keys.id: id,
      if ((name ?? '').isNotEmpty) keys.name: name,
      if ((photo ?? '').isNotEmpty) keys.photo: photo,
      if (platform.isNotEmpty) keys.platform: platform,
      if ((room ?? '').isNotEmpty) keys.room: room,
      if (token.isNotEmpty) keys.token: token,
      if (extra.isNotEmpty) keys.extra: extra,
    };
  }

  @override
  List<Object?> get props {
    return [id, name, photo, platform, room, token, extra];
  }
}
