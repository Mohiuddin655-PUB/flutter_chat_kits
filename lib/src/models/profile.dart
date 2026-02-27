import 'package:equatable/equatable.dart';

import '../utils/parser.dart';

typedef ProfileExtra = Map<String, dynamic>;

final class ProfileKeys {
  const ProfileKeys._();

  static const id = 'id';
  static const name = 'name';
  static const photo = 'photo';
  static const platform = 'platform';
  static const token = 'token';
  static const room = 'room';
  static const extra = 'extra';
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
    final ex = source[ProfileKeys.extra];
    final id = source[ProfileKeys.id];
    final name = source[ProfileKeys.name];
    final photo = source[ProfileKeys.photo];
    final platform = source[ProfileKeys.platform];
    final room = source[ProfileKeys.room];
    final token = source[ProfileKeys.token];
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
    return {
      if (id.isNotEmpty) ProfileKeys.id: id,
      if ((name ?? '').isNotEmpty) ProfileKeys.name: name,
      if ((photo ?? '').isNotEmpty) ProfileKeys.photo: photo,
      if (platform.isNotEmpty) ProfileKeys.platform: platform,
      if ((room ?? '').isNotEmpty) ProfileKeys.room: room,
      if (token.isNotEmpty) ProfileKeys.token: token,
      if (extra.isNotEmpty) ProfileKeys.extra: extra,
    };
  }

  @override
  List<Object?> get props {
    return [id, name, photo, platform, room, token, extra];
  }
}
