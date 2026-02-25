import 'package:flutter/material.dart';

import '../managers/room.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/status.dart';
import '../models/typing.dart';
import '../utils/chat_ui.dart';

class ChatInbox extends StatefulWidget {
  final Room room;

  const ChatInbox({super.key, required this.room});

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  ChatUiConfigs get i => RoomManager.i.uiConfigs;

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
    if (i.visibilityDetectorBuilder == null) {
      return _buildLayout();
    }
    return i.visibilityDetectorBuilder!(
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
        return _buildDirectInbox(room, profile, status, typing.firstOrNull);

      case GroupRoom():
        final status = RoomManager.i.statusFromRoom(room);
        final typings = RoomManager.i.typingsFromRoom(room);
        final profile = RoomManager.i.profileFromRoom(room);
        return _buildGroupInbox(
          room,
          profile,
          status,
          typings,
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildDirectInbox(
    DirectRoom room,
    Profile profile,
    Status status,
    Typing? typing,
  ) {
    if (i.directInboxBuilder == null) {
      return SizedBox.shrink();
    }
    return i.directInboxBuilder!(
      context,
      room,
      profile,
      status,
      typing,
    );
  }

  Widget _buildGroupInbox(
    GroupRoom room,
    Profile profile,
    Status status,
    List<Typing> typings,
  ) {
    if (i.groupInboxBuilder == null) {
      return SizedBox.shrink();
    }
    return i.groupInboxBuilder!(
      context,
      room,
      profile,
      status,
      typings,
    );
  }
}
