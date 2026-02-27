import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../utils/chat_ui.dart';

class ChatAppbar extends StatelessWidget implements PreferredSizeWidget {
  final ChatManager manager;
  final double height;

  const ChatAppbar({
    super.key,
    required this.manager,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (RoomManager.i.uiConfigs.chatAppbarBuilder == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: Listenable.merge([
        manager.profile,
        manager.status,
        manager.typings,
      ]),
      builder: (context, child) {
        final profile = manager.profile.value;
        final status = manager.status.value;
        final typings = manager.typings.value;
        return RoomManager.i.uiConfigs.chatAppbarBuilder!(
          context,
          ChatAppbarConfigs(
            manager: manager,
            profile: profile,
            status: status,
            typings: typings,
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => RoomManager.i.uiConfigs.chatAppbarBuilder == null
      ? Size.zero
      : Size.fromHeight(height);
}
