import 'package:equatable/equatable.dart';

final class ProfileKeys {
  const ProfileKeys._();

  static const id = 'id';
  static const name = 'name';
  static const photo = 'photo';
  static const platform = 'platform';
  static const token = 'token';
  static const room = 'room';
}

class Profile extends Equatable {
  final String id;
  final String name;
  final String? photo;
  final String platform;
  final String token;
  final String? room;

  bool get isEmpty {
    return id.isEmpty || name.isEmpty || platform.isEmpty || token.isEmpty;
  }

  String get nameSymbol => name.isEmpty ? "?" : name[0].toUpperCase();

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
  });

  factory Profile.parse(Object? source) {
    if (source is Profile) return source;
    if (source is! Map) return Profile.empty();
    final id = source[ProfileKeys.id];
    final name = source[ProfileKeys.name];
    final photo = source[ProfileKeys.photo];
    final platform = source[ProfileKeys.platform];
    final room = source[ProfileKeys.room];
    final token = source[ProfileKeys.token];
    return Profile(
      id: id is String && id.isNotEmpty ? id : '',
      name: name is String && name.isNotEmpty ? name : '?',
      photo: photo is String && photo.isNotEmpty ? photo : null,
      platform: platform is String && platform.isNotEmpty ? platform : '',
      room: room is String && room.isNotEmpty ? room : null,
      token: token is String && token.isNotEmpty ? token : '',
    );
  }

  Map<String, dynamic> get source {
    return {
      ProfileKeys.id: id,
      ProfileKeys.name: name,
      ProfileKeys.photo: photo,
      ProfileKeys.platform: platform,
      ProfileKeys.room: room,
      ProfileKeys.token: token,
    };
  }

  @override
  List<Object?> get props {
    return [id, name, photo, platform, room, token];
  }
}
