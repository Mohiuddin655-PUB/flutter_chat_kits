import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import 'chat_board.dart';
import 'input.dart';

class ChatBody extends StatelessWidget {
  const ChatBody({super.key});

  void _replyCancel() => ChatManager.i.reply(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ChatBoard()),
        _buildReplyMessagePreview(context),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    if (ChatManager.i.room.value.isLeaveByMe) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text("You're unable to send message"),
      );
    }
    if (ChatManager.i.room.value.isBlockByMe) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text("You're unable to send message"),
      );
    }
    return ChatInput();
  }

  Widget _buildReplyMessagePreview(BuildContext context) {
    if (RoomManager.i.uiConfigs.replayMessageReplyBuilder == null) {
      return SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: ChatManager.i,
      builder: (context, child) {
        final reply = ChatManager.i.replyMsg;
        if (reply == null) {
          return SizedBox.shrink();
        }
        return RoomManager.i.uiConfigs.replayMessageReplyBuilder!(
          context,
          reply,
          _replyCancel,
        );
      },
    );
  }
}
