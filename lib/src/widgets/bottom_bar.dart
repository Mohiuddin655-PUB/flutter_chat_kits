import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../utils/chat_ui.dart';
import 'input.dart';

class ChatBottomBar extends StatelessWidget {
  final ChatManager manager;
  final TextEditingController? textEditingController;

  const ChatBottomBar({
    super.key,
    required this.manager,
    this.textEditingController,
  });

  ChatUiConfigs get i => RoomManager.i.uiConfigs;

  void _replyCancel() => manager.reply(null);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, child) {
        return _buildLayout(context, [
          _buildReplyMessagePreview(context),
          _buildInput(context),
        ]);
      },
    );
  }

  Widget _buildLayout(BuildContext context, List<Widget> children) {
    if (i.chatBottomBarBuilder == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return i.chatBottomBarBuilder!(context, children);
  }

  Widget _buildInput(BuildContext context) {
    if (manager.room.isLeaveByMe) {
      return _buildLeaveFromRoomMessage(context);
    }
    if (manager.room.isBlockByMe) {
      return _buildBlockedMessage(context);
    }
    return ChatInput(manager: manager, controller: textEditingController);
  }

  Widget _buildBlockedMessage(BuildContext context) {
    if (i.blockedInputBuilder == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: const Text("You're unable to send message"),
      );
    }
    return i.blockedInputBuilder!(context);
  }

  Widget _buildLeaveFromRoomMessage(BuildContext context) {
    if (i.leaveFromRoomBuilder == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: const Text("You left this room"),
      );
    }
    return i.leaveFromRoomBuilder!(context);
  }

  Widget _buildReplyMessagePreview(BuildContext context) {
    if (i.replayMessageReplyBuilder == null) {
      return const SizedBox.shrink();
    }
    final reply = manager.replyMsg;
    if (reply == null) {
      return const SizedBox.shrink();
    }
    return i.replayMessageReplyBuilder!(
      context,
      reply,
      _replyCancel,
    );
  }
}
