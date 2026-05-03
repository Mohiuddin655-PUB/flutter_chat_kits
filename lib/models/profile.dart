import 'package:equatable/equatable.dart' show Equatable;

import '../core/room_manager.dart' show RoomManager;
import '../utils/parser.dart' show ChatListParser, MapParser;

// ── Types ──────────────────────────────────────────────────────────────────────

typedef ProfileExtra = Map<String, dynamic>;

const kBotPrefix = 'bot';
const _genderTypes = {'male', 'female', 'non-binary'};

// ── Parse Helpers ──────────────────────────────────────────────────────────────

String _str(Object? v) => v is String && v.isNotEmpty ? v : '';

String? _strOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;

List<String> _strList(Object? v) => v is List ? v.parsedStrings : [];

bool _parseBool(Object? v) => v is bool ? v : false;

// ── Keys ───────────────────────────────────────────────────────────────────────

class BotProfileKeys {
  const BotProfileKeys({
    this.id = 'profile_id',
    this.name = 'display_name',
    this.photo = 'display_photo',
    this.age = 'age',
    this.gender = 'gender',
    this.country = 'country',
    this.continent = 'continent',
    this.speakingStyle = 'speakingStyle',
    this.languages = 'languages',
    this.interests = 'interests',
    this.personalityTraits = 'personalityTraits',
    this.favoriteTopics = 'favoriteTopics',
    this.extra = 'profile_extra',
  });

  final String id;
  final String name;
  final String photo;
  final String age;
  final String gender;
  final String country;
  final String continent;
  final String speakingStyle;
  final String languages;
  final String interests;
  final String personalityTraits;
  final String favoriteTopics;
  final String extra;

  static BotProfileKeys get i => RoomManager.i.modelConfigs.botProfileKeys;
}

class UserProfileKeys {
  const UserProfileKeys({
    this.id = 'profile_id',
    this.name = 'display_name',
    this.photo = 'display_photo',
    this.platform = 'platform',
    this.token = 'device_token',
    this.room = 'active_room',
    this.extra = 'profile_extra',
    this.newMessageAlerts = 'new_message_alerts',
    this.newRoomAlerts = 'new_room_alerts',
  });

  final String id;
  final String name;
  final String photo;
  final String platform;
  final String token;
  final String room;
  final String newRoomAlerts;
  final String newMessageAlerts;
  final String extra;

  static UserProfileKeys get i => RoomManager.i.modelConfigs.userProfileKeys;
}

// ── Base ───────────────────────────────────────────────────────────────────────

class Profile extends Equatable {
  const Profile({
    required this.id,
    this.name,
    this.photo,
    this.extra = const {},
  });

  const Profile.empty() : this(id: '', name: '');

  final String id;
  final String? name;
  final String? photo;
  final ProfileExtra extra;

  bool get isBot => id.startsWith(kBotPrefix) || this is BotProfile;

  bool get isEmpty => id.isEmpty;

  String? get nameSymbol =>
      name?.isNotEmpty == true ? name![0].toUpperCase() : null;

  @override
  List<Object?> get props => [id, name, photo, extra];
}

// ── BotProfile ─────────────────────────────────────────────────────────────────

class BotProfile extends Profile {
  const BotProfile({
    required super.id,
    required String super.name,
    super.photo,
    super.extra,
    required this.age,
    required this.gender,
    required this.country,
    required this.continent,
    required this.speakingStyle,
    required this.languages,
    required this.interests,
    required this.personalityTraits,
    required this.favoriteTopics,
  });

  const BotProfile.empty()
      : this(
          id: '',
          name: '',
          photo: null,
          age: 0,
          gender: '',
          country: '',
          continent: '',
          speakingStyle: '',
          languages: const [],
          interests: const [],
          personalityTraits: const [],
          favoriteTopics: const [],
        );

  final int age;
  final String gender;
  final String country;
  final String continent;
  final String speakingStyle;
  final List<String> languages;
  final List<String> interests;
  final List<String> personalityTraits;
  final List<String> favoriteTopics;

  @override
  String get name => super.name ?? '';

  @override
  bool get isEmpty =>
      id.isEmpty ||
      name.isEmpty ||
      gender.isEmpty ||
      country.isEmpty ||
      continent.isEmpty ||
      speakingStyle.isEmpty ||
      languages.isEmpty ||
      interests.isEmpty ||
      personalityTraits.isEmpty ||
      favoriteTopics.isEmpty;

  // ── Parse ────────────────────────────────────────────────────────────────────

  factory BotProfile.parse(Object? source, {ProfileExtra? extra}) {
    if (source is BotProfile) return source;
    if (source is! Map) return const BotProfile.empty();

    final k = BotProfileKeys.i;
    final rawAge = source[k.age];
    final rawGender = source[k.gender];

    final ex = source[k.extra];

    return BotProfile(
      id: _str(source[k.id]),
      name: _str(source[k.name]),
      photo: _strOrNull(source[k.photo]),
      age: rawAge is num && rawAge > 0 ? rawAge.toInt() : 0,
      gender: _genderTypes.contains(rawGender) ? rawGender as String : '',
      country: _str(source[k.country]),
      continent: _str(source[k.continent]),
      speakingStyle: _str(source[k.speakingStyle]),
      languages: _strList(source[k.languages]),
      interests: _strList(source[k.interests]),
      personalityTraits: _strList(source[k.personalityTraits]),
      favoriteTopics: _strList(source[k.favoriteTopics]),
      extra: extra ?? (ex is Map ? ex.parse() : {}),
    );
  }

  // ── CopyWith ─────────────────────────────────────────────────────────────────

  BotProfile copyWith({
    String? id,
    String? name,
    String? photo,
    int? age,
    String? gender,
    String? country,
    String? continent,
    String? speakingStyle,
    List<String>? languages,
    List<String>? interests,
    List<String>? personalityTraits,
    List<String>? favoriteTopics,
    ProfileExtra? extra,
  }) =>
      BotProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        photo: photo ?? this.photo,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        country: country ?? this.country,
        continent: continent ?? this.continent,
        speakingStyle: speakingStyle ?? this.speakingStyle,
        languages: languages ?? this.languages,
        interests: interests ?? this.interests,
        personalityTraits: personalityTraits ?? this.personalityTraits,
        favoriteTopics: favoriteTopics ?? this.favoriteTopics,
        extra: extra ?? this.extra,
      );

  // ── Source ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> get source {
    final k = BotProfileKeys.i;
    return {
      if (id.isNotEmpty) k.id: id,
      if (name.isNotEmpty) k.name: name,
      if (photo != null) k.photo: photo,
      if (age > 0) k.age: age,
      if (gender.isNotEmpty) k.gender: gender,
      if (country.isNotEmpty) k.country: country,
      if (continent.isNotEmpty) k.continent: continent,
      if (speakingStyle.isNotEmpty) k.speakingStyle: speakingStyle,
      if (languages.isNotEmpty) k.languages: languages,
      if (interests.isNotEmpty) k.interests: interests,
      if (personalityTraits.isNotEmpty) k.personalityTraits: personalityTraits,
      if (favoriteTopics.isNotEmpty) k.favoriteTopics: favoriteTopics,
      if (extra.isNotEmpty) k.extra: extra,
    };
  }

  // ── Equatable ────────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        id,
        name,
        photo,
        age,
        gender,
        country,
        continent,
        speakingStyle,
        languages,
        interests,
        personalityTraits,
        favoriteTopics,
        extra,
      ];
}

// ── UserProfile ────────────────────────────────────────────────────────────────

class UserProfile extends Profile {
  const UserProfile({
    required super.id,
    super.name,
    super.photo,
    super.extra,
    required this.platform,
    required this.token,
    this.room,
    this.newMessageAlerts = false,
    this.newRoomAlerts = false,
  });

  const UserProfile.empty() : this(id: '', platform: '', token: '');

  final String platform;
  final String token;
  final String? room;
  final bool newRoomAlerts;
  final bool newMessageAlerts;

  bool isActiveRoom(String roomId) =>
      roomId.isNotEmpty && room != null && room == roomId;

  // ── Parse ────────────────────────────────────────────────────────────────────

  factory UserProfile.parse(Object? source, {ProfileExtra? extra}) {
    if (source is UserProfile) return source;
    if (source is! Map) return const UserProfile.empty();

    final k = UserProfileKeys.i;
    final ex = source[k.extra];

    return UserProfile(
      id: _str(source[k.id]),
      name: _strOrNull(source[k.name]),
      photo: _strOrNull(source[k.photo]),
      platform: _str(source[k.platform]),
      token: _str(source[k.token]),
      room: _strOrNull(source[k.room]),
      newMessageAlerts: _parseBool(source[k.newMessageAlerts]),
      newRoomAlerts: _parseBool(source[k.newRoomAlerts]),
      extra: extra ?? (ex is Map ? ex.parse() : {}),
    );
  }

  // ── CopyWith ─────────────────────────────────────────────────────────────────

  UserProfile copyWith({
    String? id,
    String? name,
    String? photo,
    String? platform,
    String? token,
    String? room,
    bool clearRoom = false,
    bool? newMessageAlerts,
    bool? newRoomAlerts,
    ProfileExtra? extra,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        photo: photo ?? this.photo,
        platform: platform ?? this.platform,
        token: token ?? this.token,
        room: clearRoom ? null : (room ?? this.room),
        newMessageAlerts: newMessageAlerts ?? this.newMessageAlerts,
        newRoomAlerts: newRoomAlerts ?? this.newRoomAlerts,
        extra: extra ?? this.extra,
      );

  // ── Source ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> get source {
    final keys = UserProfileKeys.i;
    return {
      if (id.isNotEmpty) keys.id: id,
      if ((name ?? '').isNotEmpty) keys.name: name,
      if ((photo ?? '').isNotEmpty) keys.photo: photo,
      if (platform.isNotEmpty) keys.platform: platform,
      if ((room ?? '').isNotEmpty) keys.room: room,
      if (token.isNotEmpty) keys.token: token,
      if (newMessageAlerts) keys.newMessageAlerts: newMessageAlerts,
      if (newRoomAlerts) keys.newRoomAlerts: newRoomAlerts,
      if (extra.isNotEmpty) keys.extra: extra,
    };
  }

  // ── Equatable ────────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        id,
        name,
        photo,
        platform,
        room,
        token,
        newRoomAlerts,
        newMessageAlerts,
        extra,
      ];
}
