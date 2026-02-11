import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';

class ChatAppbar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const ChatAppbar({super.key, this.height = kToolbarHeight});

  @override
  Widget build(BuildContext context) {
    final m = ChatManager.i;
    return ListenableBuilder(
      listenable: Listenable.merge([m.profile, m.status, m.typings]),
      builder: (context, child) {
        final profile = m.profile.value;
        final status = m.status.value;
        final typings = m.typings.value;
        return RoomManager.i.uiConfigs.chatAppbarBuilder(
          context,
          profile,
          status,
          typings,
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
