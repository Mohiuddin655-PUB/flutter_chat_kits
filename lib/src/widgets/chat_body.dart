import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatBody extends StatelessWidget {
  final ChatManager manager;

  const ChatBody({super.key, required this.manager});

  ChatUiConfigs get i => RoomManager.i.uiConfigs;

  void _replyCancel() => manager.reply(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ChatBoard(manager: manager)),
        _buildReplyMessagePreview(context),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, child) {
        if (manager.room.isLeaveByMe) {
          return _buildLeaveFromRoomMessage(context);
        }
        if (manager.room.isBlockByMe) {
          return _buildBlockedMessage(context);
        }
        return ChatInput(manager: manager);
      },
    );
  }

  Widget _buildBlockedMessage(BuildContext context) {
    if (i.blockedInputBuilder == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text("You're unable to send message"),
      );
    }
    return i.blockedInputBuilder!(context);
  }

  Widget _buildLeaveFromRoomMessage(BuildContext context) {
    if (i.leaveFromRoomBuilder == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text("You're unable to send message"),
      );
    }
    return i.leaveFromRoomBuilder!(context);
  }

  Widget _buildReplyMessagePreview(BuildContext context) {
    if (i.replayMessageReplyBuilder == null) {
      return SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: manager,
      builder: (context, child) {
        final reply = manager.replyMsg;
        if (reply == null) {
          return SizedBox.shrink();
        }
        return i.replayMessageReplyBuilder!(
          context,
          reply,
          _replyCancel,
        );
      },
    );
  }
}
