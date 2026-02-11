import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../models/message.dart';
import '../utils/chat_ui.dart';

class ChatMessage extends StatefulWidget {
  final Message message;
  final ChatMessageBuilder<AudioMessage> audioBuilder;
  final ChatMessageBuilder<Message> deletedBuilder;
  final ChatMessageBuilder<ImageMessage> imageBuilder;
  final ChatMessageBuilder<LinkMessage> linkBuilder;
  final ChatMessageBuilder<TextMessage> textBuilder;
  final ChatMessageBuilder<VideoMessage> videoBuilder;

  const ChatMessage({
    super.key,
    required this.message,
    required this.audioBuilder,
    required this.deletedBuilder,
    required this.imageBuilder,
    required this.linkBuilder,
    required this.textBuilder,
    required this.videoBuilder,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  bool _hasMarkedSeen = false;

  void _changed(ChatVisibilityInfo info) {
    if (_hasMarkedSeen) return;
    if (info.visibleFraction > 0.5) {
      _hasMarkedSeen = true;
      ChatManager.i.seen(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isRemovedByMe) {
      return SizedBox();
    }
    return RoomManager.i.uiConfigs.visibilityDetectorBuilder(
      context,
      'msg_${widget.message.id}',
      _buildLayout(context),
      _changed,
    );
  }

  Widget _buildLayout(BuildContext context) {
    final msg = widget.message;
    if (msg.isDeleted || msg.isDeletedByMe) {
      return widget.deletedBuilder(context, msg);
    }
    switch (msg) {
      case AudioMessage():
        return widget.audioBuilder(context, msg);
      case ImageMessage():
        return widget.imageBuilder(context, msg);
      case LinkMessage():
        return widget.linkBuilder(context, msg);
      case TextMessage():
        return widget.textBuilder(context, msg);
      case VideoMessage():
        return widget.videoBuilder(context, msg);
      default:
        return SizedBox.shrink();
    }
  }
}
