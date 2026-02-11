import 'package:flutter/material.dart';

import '../managers/room.dart';
import '../models/room.dart';
import '../utils/chat_ui.dart';

class ChatInbox extends StatefulWidget {
  final Room room;

  const ChatInbox({super.key, required this.room});

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  void _onChanged(ChatVisibilityInfo info) {
    if (info.visibleFraction <= 0.5) {
      return;
    }
    RoomManager.i.visible(widget.room);
  }

  @override
  void dispose() {
    RoomManager.i.invisible(widget.room);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoomManager.i.uiConfigs.visibilityDetectorBuilder(
      context,
      widget.room.id,
      _buildLayout(),
      _onChanged,
    );
  }

  Widget _buildLayout() {
    final room = widget.room;
    if (room.isEmpty) return SizedBox.shrink();
    switch (room) {
      case DirectRoom():
        final friendId = room.friendId;
        final status = RoomManager.i.statusFor(friendId);
        final typing = RoomManager.i.typingsFromRoom(room);
        final profile = RoomManager.i.profileFor(friendId);
        return RoomManager.i.uiConfigs.directInboxBuilder(
          context,
          room,
          profile,
          status,
          typing.firstOrNull,
        );

      case GroupRoom():
        final status = RoomManager.i.statusFromRoom(room);
        final typings = RoomManager.i.typingsFromRoom(room);
        final profile = RoomManager.i.profileFromRoom(room);
        return RoomManager.i.uiConfigs.groupInboxBuilder(
          context,
          room,
          profile,
          status,
          typings,
        );
      default:
        return SizedBox.shrink();
    }
  }
}
