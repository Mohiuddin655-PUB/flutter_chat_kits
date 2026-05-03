import 'package:equatable/equatable.dart' show Equatable;

import '../core/room_manager.dart' show RoomManager;
import '../utils/enum_parser.dart' show ChatEnumParser;
import '../utils/field_value.dart' show ChatValueTimestamp;
import '../utils/parser.dart' show ChatListParser, MapParser;
import 'message.dart' show MessageStatus;

typedef RoomExtra = Map<String, dynamic>;

// ── Keys ──────────────────────────────────────────────────────────────────────

class RoomKeys {
  final String id;
  final String friendId;
  final String participants;
  final String leaves;
  final String createdAt;
  final String createdBy;
  final String name;
  final String photo;
  final String isBot;
  final String isGroup;
  final String isDeleted;
  final String isVerified;
  final String lastMessage;
  final String lastMessageId;
  final String lastMessageSenderId;
  final String lastMessageDeleted;
  final String lastMessageStatuses;
  final String unseenCount;
  final String updatedAt;
  final String mutes;
  final String archives;
  final String blocks;
  final String pins;
  final String removes;
  final String restricts;
  final String extra;

  static RoomKeys get i => RoomManager.i.modelConfigs.roomKeys;

  const RoomKeys({
    this.id = 'id',
    this.friendId = 'friendId',
    this.participants = 'participants',
    this.leaves = 'leaves',
    this.createdAt = 'createdAt',
    this.createdBy = 'createdBy',
    this.name = 'name',
    this.photo = 'photo',
    this.isBot = 'isBot',
    this.isGroup = 'isGroup',
    this.isDeleted = 'isDeleted',
    this.isVerified = 'isVerified',
    this.lastMessage = 'lastMessage',
    this.lastMessageId = 'lastMessageId',
    this.lastMessageSenderId = 'lastMessageSenderId',
    this.lastMessageDeleted = 'lastMessageDeleted',
    this.lastMessageStatuses = 'lastMessageStatuses',
    this.unseenCount = 'unseenCount',
    this.updatedAt = 'updatedAt',
    this.mutes = 'mutes',
    this.archives = 'archives',
    this.blocks = 'blocks',
    this.pins = 'pins',
    this.removes = 'removes',
    this.restricts = 'restricts',
    this.extra = 'extra',
  });
}

// ── Room ──────────────────────────────────────────────────────────────────────

class Room extends Equatable {
  // ── Fields ─────────────────────────────────────────────────────────────────

  final Set<String> archives;
  final Set<String> blocks;
  final ChatValueTimestamp createdAt;
  final String createdBy;
  final RoomExtra extra;
  final String id;
  final bool isBot;
  final bool isDeleted;
  final bool isGroup;
  final bool isLocal;
  final bool isVerified;
  final String? lastMessage;
  final bool lastMessageDeleted;
  final String lastMessageId;
  final String lastMessageSenderId;
  final Map<String, MessageStatus> lastMessageStatuses;
  final Set<String> leaves;
  final Set<String> mutes;
  final Set<String> participants;
  final Set<String> pins;
  final Map<String, String> removes;
  final Set<String> restricts;
  final ChatValueTimestamp updatedAt;
  final Map<String, int> _unseenCounts;

  // ── Getters ────────────────────────────────────────────────────────────────

  String get me => RoomManager.i.me;

  bool get isEmpty => id.isEmpty || participants.isEmpty;

  bool get isAdminByMe => createdBy == me;

  bool get isArchivedByMe => archives.contains(me);

  bool get isBlockedByMe => blocks.contains(me);

  bool get isLeaveByMe => leaves.contains(me);

  bool get isMutedByMe => mutes.contains(me);

  bool get isPinnedByMe => pins.contains(me);

  bool get isRestrictedByMe => restricts.contains(me);

  bool get isSentByMe => lastMessageSenderId == me;

  bool get isRemovedByMe {
    return removes.containsKey(me) && removes[me] == lastMessageId;
  }

  Map<String, int> get unseenCounts => _unseenCounts;

  int get unseenCount => _unseenCounts[me] ?? 0;

  String? get lastMessageStatus => lastMessageStatuses[me]?.name;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String formattedLastMessage({
    String? sender,
    bool isTyping = false,
    String Function(String key, String value)? formatter,
  }) {
    if (isTyping) return 'Typing...';

    final isMe = lastMessageSenderId == me;

    if (isMe && lastMessageStatus == MessageStatus.sending.name) {
      return 'Sending...';
    }

    final resolvedSender = sender ?? '';

    if (lastMessageDeleted) {
      return '${isMe ? 'You' : resolvedSender} deleted a message';
    }

    String msg = lastMessage ?? '';

    if (formatter != null) {
      if (msg.contains('{SENDER_OR_EMPTY}')) {
        msg = formatter('{SENDER_OR_EMPTY}', msg);
      }
      if (msg.contains('{SENDER}')) {
        msg = formatter('{SENDER}', msg);
      }
      return msg;
    }

    return msg
        .replaceAll('{SENDER_OR_EMPTY}', isMe ? 'You: ' : '')
        .replaceAll('{SENDER}', isMe ? 'You' : resolvedSender);
  }

  // ── Constructors ───────────────────────────────────────────────────────────

  const Room({
    this.archives = const {},
    this.blocks = const {},
    this.createdAt = const ChatValueTimestamp(),
    this.createdBy = '',
    this.extra = const {},
    this.id = '',
    this.isBot = false,
    this.isDeleted = false,
    this.isGroup = false,
    this.isLocal = false,
    this.isVerified = false,
    this.lastMessage,
    this.lastMessageDeleted = false,
    this.lastMessageId = '',
    this.lastMessageSenderId = '',
    this.lastMessageStatuses = const {},
    this.leaves = const {},
    this.mutes = const {},
    this.participants = const {},
    this.pins = const {},
    this.removes = const {},
    this.restricts = const {},
    this.updatedAt = const ChatValueTimestamp(),
    Map<String, int> unseenCounts = const {},
  }) : _unseenCounts = unseenCounts;

  const Room.empty() : this();

  // ── Parse ──────────────────────────────────────────────────────────────────

  factory Room.parse(Object? source, {RoomExtra? extra}) {
    if (source is Room) return source;
    if (source is! Map) return const Room.empty();

    final keys = RoomKeys.i;

    final isBot = source[keys.isBot];
    final isGroup = source[keys.isGroup];
    final archives = source[keys.archives];
    final blocks = source[keys.blocks];
    final createdAt = source[keys.createdAt];
    final createdBy = source[keys.createdBy];
    final ex = source[keys.extra];
    final id = source[keys.id];
    final isDeleted = source[keys.isDeleted];
    final isVerified = source[keys.isVerified];
    final lastMessage = source[keys.lastMessage];
    final lastMessageDeleted = source[keys.lastMessageDeleted];
    final lastMessageId = source[keys.lastMessageId];
    final lastMessageSenderId = source[keys.lastMessageSenderId];
    final lastMessageStatuses = source[keys.lastMessageStatuses];
    final leaves = source[keys.leaves];
    final mutes = source[keys.mutes];
    final participants = source[keys.participants];
    final pins = source[keys.pins];
    final removes = source[keys.removes];
    final restricts = source[keys.restricts];
    final unseenCounts = source[keys.unseenCount];
    final updatedAt = source[keys.updatedAt];

    final mIsGroup = isGroup is bool ? isGroup : false;

    final room = Room(
      isLocal: false,
      isBot: isBot is bool ? isBot : false,
      isGroup: mIsGroup,
      archives: archives is Iterable ? archives.parsedStrings.toSet() : {},
      blocks: blocks is Iterable ? blocks.parsedStrings.toSet() : {},
      createdAt: ChatValueTimestamp.parse(createdAt),
      createdBy: createdBy is String && createdBy.isNotEmpty ? createdBy : '',
      extra: extra ?? (ex is Map ? ex.parse() : {}),
      id: id is String && id.isNotEmpty ? id : '',
      isDeleted: isDeleted is bool ? isDeleted : false,
      isVerified: isVerified is bool ? isVerified : false,
      lastMessage:
          lastMessage is String && lastMessage.isNotEmpty ? lastMessage : null,
      lastMessageDeleted:
          lastMessageDeleted is bool ? lastMessageDeleted : false,
      lastMessageId: lastMessageId is String && lastMessageId.isNotEmpty
          ? lastMessageId
          : '',
      lastMessageSenderId:
          lastMessageSenderId is String ? lastMessageSenderId : '',
      lastMessageStatuses: lastMessageStatuses is Map
          ? MessageStatus.values.references(lastMessageStatuses)
          : {},
      leaves: leaves is Iterable ? leaves.parsedStrings.toSet() : {},
      mutes: mutes is Iterable ? mutes.parsedStrings.toSet() : {},
      participants:
          participants is Iterable ? participants.parsedStrings.toSet() : {},
      pins: pins is Iterable ? pins.parsedStrings.toSet() : {},
      removes: removes is Map ? removes.parse() : {},
      restricts: restricts is Iterable ? restricts.parsedStrings.toSet() : {},
      unseenCounts: unseenCounts is Map ? unseenCounts.parse() : {},
      updatedAt: ChatValueTimestamp.parse(updatedAt),
    );

    if (mIsGroup) {
      final name = source[keys.name];
      final photo = source[keys.photo];
      return GroupRoom.from(
        room,
        name: name is String && name.isNotEmpty ? name : null,
        photo: photo is String && photo.isNotEmpty ? photo : null,
      );
    }

    return DirectRoom.from(room);
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

  Room copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isBot,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    bool? isVerified,
    bool clearLastMessage = false,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
    Map<String, int>? unseenCounts,
    ChatValueTimestamp? updatedAt,
  }) {
    final mArchives = {...archives};
    if (isArchived != null) {
      isArchived ? mArchives.add(me) : mArchives.remove(me);
    }

    final mBlocks = {...this.blocks};
    if (isBlocked != null && blocks != null && blocks.isNotEmpty) {
      isBlocked ? mBlocks.addAll(blocks) : mBlocks.removeAll(blocks);
    }

    final mLeaves = {...leaves};
    if (isLeaved != null) {
      isLeaved ? mLeaves.add(me) : mLeaves.remove(me);
    }

    final mMutes = {...mutes};
    if (isMuted != null) {
      isMuted ? mMutes.add(me) : mMutes.remove(me);
    }

    final mPins = {...pins};
    if (isPinned != null) {
      isPinned ? mPins.add(me) : mPins.remove(me);
    }

    final mParticipants = {...this.participants};
    if (isAddMember != null &&
        participants != null &&
        participants.isNotEmpty) {
      isAddMember
          ? mParticipants.addAll(participants)
          : mParticipants.removeAll(participants);
    }

    final mRemoves = {...removes};
    if (isRemoved != null &&
        lastMessageId != null &&
        lastMessageId.isNotEmpty) {
      isRemoved ? mRemoves[me] = lastMessageId : mRemoves.remove(me);
    }

    final mRestricts = {...this.restricts};
    if (isRestricted != null && restricts != null && restricts.isNotEmpty) {
      isRestricted
          ? mRestricts.addAll(restricts)
          : mRestricts.removeAll(restricts);
    }

    return Room(
      archives: mArchives,
      blocks: mBlocks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      extra: extra ?? this.extra,
      id: id ?? this.id,
      isBot: isBot ?? this.isBot,
      isDeleted: isDeleted ?? this.isDeleted,
      isGroup: isGroup ?? this.isGroup,
      isLocal: isLocal ?? this.isLocal,
      isVerified: isVerified ?? this.isVerified,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      lastMessageDeleted: lastMessageDeleted ?? this.lastMessageDeleted,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses ?? this.lastMessageStatuses,
      leaves: mLeaves,
      mutes: mMutes,
      participants: mParticipants,
      pins: mPins,
      removes: mRemoves,
      restricts: mRestricts,
      unseenCounts: unseenCounts ?? _unseenCounts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Source ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> get source {
    final keys = RoomKeys.i;
    return {
      if (id.isNotEmpty) keys.id: id,
      if (createdBy.isNotEmpty) keys.createdBy: createdBy,
      if (!createdAt.isEmpty) keys.createdAt: createdAt,
      if (!updatedAt.isEmpty) keys.updatedAt: updatedAt,
      if (isBot) keys.isBot: isBot,
      if (isDeleted) keys.isDeleted: isDeleted,
      if (isGroup) keys.isGroup: isGroup,
      if (isVerified) keys.isVerified: isVerified,
      if (lastMessageDeleted) keys.lastMessageDeleted: lastMessageDeleted,
      if (lastMessageId.isNotEmpty) keys.lastMessageId: lastMessageId,
      if (lastMessageSenderId.isNotEmpty)
        keys.lastMessageSenderId: lastMessageSenderId,
      if ((lastMessage ?? '').isNotEmpty) keys.lastMessage: lastMessage,
      if (lastMessageStatuses.isNotEmpty)
        keys.lastMessageStatuses: lastMessageStatuses.map(
          (k, v) => MapEntry(k, v.name),
        ),
      if (archives.isNotEmpty) keys.archives: archives.toList(),
      if (blocks.isNotEmpty) keys.blocks: blocks.toList(),
      if (leaves.isNotEmpty) keys.leaves: leaves.toList(),
      if (mutes.isNotEmpty) keys.mutes: mutes.toList(),
      if (participants.isNotEmpty) keys.participants: participants.toList(),
      if (pins.isNotEmpty) keys.pins: pins.toList(),
      if (removes.isNotEmpty) keys.removes: removes,
      if (restricts.isNotEmpty) keys.restricts: restricts.toList(),
      if (_unseenCounts.isNotEmpty) keys.unseenCount: _unseenCounts,
      if (extra.isNotEmpty) keys.extra: extra,
    };
  }

  // ── Equatable ──────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        archives,
        blocks,
        createdAt,
        createdBy,
        extra,
        id,
        isBot,
        isDeleted,
        isGroup,
        isLocal,
        isVerified,
        lastMessage,
        lastMessageDeleted,
        lastMessageId,
        lastMessageSenderId,
        lastMessageStatuses,
        leaves,
        mutes,
        participants,
        pins,
        removes,
        restricts,
        _unseenCounts,
        updatedAt,
      ];
}

// ── DirectRoom ────────────────────────────────────────────────────────────────

class DirectRoom extends Room {
  String get friendId {
    return participants.firstWhere((e) => e != me, orElse: () => '');
  }

  const DirectRoom({
    super.archives,
    super.blocks,
    super.createdAt,
    super.createdBy,
    super.extra,
    super.id,
    super.isBot,
    super.isDeleted,
    super.isLocal,
    super.isVerified,
    super.lastMessage,
    super.lastMessageDeleted,
    super.lastMessageId,
    super.lastMessageSenderId,
    super.lastMessageStatuses,
    super.leaves,
    super.mutes,
    super.participants,
    super.pins,
    super.removes,
    super.restricts,
    super.unseenCounts,
    super.updatedAt,
  }) : super(isGroup: false);

  const DirectRoom.empty() : this();

  factory DirectRoom.from(Room room) {
    return DirectRoom(
      archives: room.archives,
      blocks: room.blocks,
      createdAt: room.createdAt,
      createdBy: room.createdBy,
      extra: room.extra,
      id: room.id,
      isBot: room.isBot,
      isDeleted: room.isDeleted,
      isLocal: room.isLocal,
      isVerified: room.isVerified,
      lastMessage: room.lastMessage,
      lastMessageDeleted: room.lastMessageDeleted,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      leaves: room.leaves,
      mutes: room.mutes,
      participants: room.participants,
      pins: room.pins,
      removes: room.removes,
      restricts: room.restricts,
      unseenCounts: room._unseenCounts,
      updatedAt: room.updatedAt,
    );
  }

  @override
  DirectRoom copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isBot,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    bool? isVerified,
    bool clearLastMessage = false,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
    Map<String, int>? unseenCounts,
    ChatValueTimestamp? updatedAt,
  }) {
    return DirectRoom.from(
      super.copyWith(
        blocks: blocks,
        createdAt: createdAt,
        createdBy: createdBy,
        extra: extra,
        id: id,
        isAddMember: isAddMember,
        isArchived: isArchived,
        isBlocked: isBlocked,
        isBot: isBot,
        isDeleted: isDeleted,
        isGroup: isGroup,
        isLeaved: isLeaved,
        isLocal: isLocal,
        isMuted: isMuted,
        isPinned: isPinned,
        isRemoved: isRemoved,
        isRestricted: isRestricted,
        isVerified: isVerified,
        clearLastMessage: clearLastMessage,
        lastMessage: lastMessage,
        lastMessageDeleted: lastMessageDeleted,
        lastMessageId: lastMessageId,
        lastMessageSenderId: lastMessageSenderId,
        lastMessageStatuses: lastMessageStatuses,
        participants: participants,
        restricts: restricts,
        unseenCounts: unseenCounts,
        updatedAt: updatedAt,
      ),
    );
  }
}

// ── GroupRoom ─────────────────────────────────────────────────────────────────

class GroupRoom extends Room {
  final String? name;
  final String? photo;

  const GroupRoom({
    super.archives,
    super.blocks,
    super.createdAt,
    super.createdBy,
    super.extra,
    super.id,
    super.isBot,
    super.isDeleted,
    super.isLocal,
    super.isVerified,
    super.lastMessage,
    super.lastMessageDeleted,
    super.lastMessageId,
    super.lastMessageSenderId,
    super.lastMessageStatuses,
    super.leaves,
    super.mutes,
    super.participants,
    super.pins,
    super.removes,
    super.restricts,
    super.unseenCounts,
    super.updatedAt,
    this.name,
    this.photo,
  }) : super(isGroup: true);

  const GroupRoom.empty() : this();

  factory GroupRoom.from(Room room, {String? name, String? photo}) {
    return GroupRoom(
      archives: room.archives,
      blocks: room.blocks,
      createdAt: room.createdAt,
      createdBy: room.createdBy,
      extra: room.extra,
      id: room.id,
      isBot: room.isBot,
      isDeleted: room.isDeleted,
      isLocal: room.isLocal,
      isVerified: room.isVerified,
      lastMessage: room.lastMessage,
      lastMessageDeleted: room.lastMessageDeleted,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      leaves: room.leaves,
      mutes: room.mutes,
      participants: room.participants,
      pins: room.pins,
      removes: room.removes,
      restricts: room.restricts,
      unseenCounts: room._unseenCounts,
      updatedAt: room.updatedAt,
      name: name,
      photo: photo,
    );
  }

  @override
  GroupRoom copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isBot,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    bool? isVerified,
    bool clearLastMessage = false,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
    Map<String, int>? unseenCounts,
    ChatValueTimestamp? updatedAt,
    String? name,
    String? photo,
  }) {
    return GroupRoom.from(
      super.copyWith(
        blocks: blocks,
        createdAt: createdAt,
        createdBy: createdBy,
        extra: extra,
        id: id,
        isAddMember: isAddMember,
        isArchived: isArchived,
        isBlocked: isBlocked,
        isBot: isBot,
        isDeleted: isDeleted,
        isGroup: isGroup,
        isLeaved: isLeaved,
        isLocal: isLocal,
        isMuted: isMuted,
        isPinned: isPinned,
        isRemoved: isRemoved,
        isRestricted: isRestricted,
        isVerified: isVerified,
        clearLastMessage: clearLastMessage,
        lastMessage: lastMessage,
        lastMessageDeleted: lastMessageDeleted,
        lastMessageId: lastMessageId,
        lastMessageSenderId: lastMessageSenderId,
        lastMessageStatuses: lastMessageStatuses,
        participants: participants,
        restricts: restricts,
        unseenCounts: unseenCounts,
        updatedAt: updatedAt,
      ),
      name: name ?? this.name,
      photo: photo ?? this.photo,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = RoomKeys.i;
    return {
      ...super.source,
      if ((name ?? '').isNotEmpty) keys.name: name,
      if ((photo ?? '').isNotEmpty) keys.photo: photo,
    };
  }

  @override
  List<Object?> get props => [...super.props, name, photo];
}
