import 'package:flutter/material.dart'
    show
        Widget,
        BuildContext,
        StatefulWidget,
        State,
        SizedBox,
        ValueListenableBuilder;

import '../core/room_manager.dart' show RoomManager;
import '../models/profile.dart' show Profile;
import '../models/room.dart' show DirectRoom, GroupRoom, Room;
import '../models/status.dart' show Status;
import '../models/typing.dart' show Typing;
import '../models/visibility.dart' show VisibilityInfo;

// ── Types ─────────────────────────────────────────────────────────────────────

typedef ChatInboxVisibilityCallback = void Function(VisibilityInfo info);

typedef ChatInboxDirectBuilder = Widget Function(
  BuildContext context,
  DirectRoom room,
  Profile profile,
  Status status,
  Typing? typing,
);

typedef ChatInboxGroupBuilder = Widget Function(
  BuildContext context,
  GroupRoom room,
  Profile profile,
  Status status,
  List<Typing> typings,
);

typedef ChatInboxVisibilityBuilder = Widget Function(
  BuildContext context,
  String id,
  Widget child,
  ChatInboxVisibilityCallback callback,
);

// ── Widget ────────────────────────────────────────────────────────────────────

class ChatInbox extends StatefulWidget {
  final Room room;
  final double visibilityThreshold;
  final ChatInboxDirectBuilder directBuilder;
  final ChatInboxGroupBuilder groupBuilder;
  final ChatInboxVisibilityBuilder? visibilityDetectorBuilder;

  const ChatInbox({
    super.key,
    required this.room,
    required this.directBuilder,
    required this.groupBuilder,
    this.visibilityDetectorBuilder,
    this.visibilityThreshold = 0.5,
  });

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _ChatInboxState extends State<ChatInbox> {
  bool get _hasVisibilityDetector => widget.visibilityDetectorBuilder != null;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!_hasVisibilityDetector) RoomManager.i.visible(widget.room);
  }

  @override
  void didUpdateWidget(covariant ChatInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      RoomManager.i.invisible(oldWidget.room);
      if (!_hasVisibilityDetector) RoomManager.i.visible(widget.room);
    }
  }

  @override
  void dispose() {
    RoomManager.i.invisible(widget.room);
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction > widget.visibilityThreshold) {
      RoomManager.i.visible(widget.room);
    } else {
      RoomManager.i.invisible(widget.room);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.room.isEmpty) return const SizedBox.shrink();

    final notifier = RoomManager.i.roomNotifier(widget.room.id);

    final content = ValueListenableBuilder<Room>(
      valueListenable: notifier,
      builder: (context, room, _) => _buildContent(room),
    );

    if (!_hasVisibilityDetector) return content;

    return widget.visibilityDetectorBuilder!(
      context,
      widget.room.id,
      content,
      _onVisibilityChanged,
    );
  }

  Widget _buildContent(Room room) {
    if (room.isEmpty) return const SizedBox.shrink();

    final profile = RoomManager.i.profileFromRoom(room);
    final status = RoomManager.i.statusFromRoom(room);
    final typings = RoomManager.i.typingsFromRoom(room);

    return switch (room) {
      DirectRoom() => widget.directBuilder(
          context,
          room,
          profile,
          status,
          typings.firstOrNull,
        ),
      GroupRoom() => widget.groupBuilder(
          context,
          room,
          profile,
          status,
          typings,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
