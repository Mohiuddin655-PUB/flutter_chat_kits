import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../models/message.dart';
import '../utils/chat_ui.dart';

class ChatMessage extends StatefulWidget {
  final ChatManager manager;
  final Message message;
  final ChatMessageBuilder<AudioMessage>? audioBuilder;
  final ChatMessageBuilder<Message>? deletedBuilder;
  final ChatMessageBuilder<ImageMessage>? imageBuilder;
  final ChatMessageBuilder<LinkMessage>? linkBuilder;
  final ChatMessageBuilder<TextMessage>? textBuilder;
  final ChatMessageBuilder<VideoMessage>? videoBuilder;

  const ChatMessage({
    super.key,
    required this.manager,
    required this.message,
    this.audioBuilder,
    this.deletedBuilder,
    this.imageBuilder,
    this.linkBuilder,
    this.textBuilder,
    this.videoBuilder,
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
      widget.manager.seen(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isRemovedByMe) {
      return SizedBox();
    }
    if (RoomManager.i.uiConfigs.visibilityDetectorBuilder == null) {
      return _buildLayout(context);
    }
    return RoomManager.i.uiConfigs.visibilityDetectorBuilder!(
      context,
      'msg_${widget.message.id}',
      _buildLayout(context),
      _changed,
    );
  }

  Widget _buildLayout(BuildContext context) {
    final msg = widget.message;
    if (msg.isDeleted || msg.isDeletedByMe) {
      return _buildDeletedMessage(context, msg);
    }
    switch (msg) {
      case AudioMessage():
        return _buildAudioMessage(context, msg);
      case ImageMessage():
        return _buildImageMessage(context, msg);
      case LinkMessage():
        return _buildLinkMessage(context, msg);
      case TextMessage():
        return _buildTextMessage(context, msg);
      case VideoMessage():
        return _buildVideoMessage(context, msg);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildAudioMessage(BuildContext context, AudioMessage msg) {
    if (widget.audioBuilder == null) {
      return SizedBox();
    }
    return widget.audioBuilder!(context, widget.manager, msg);
  }

  Widget _buildDeletedMessage(BuildContext context, Message msg) {
    if (widget.deletedBuilder == null) {
      return SizedBox();
    }
    return widget.deletedBuilder!(context, widget.manager, msg);
  }

  Widget _buildImageMessage(BuildContext context, ImageMessage msg) {
    if (widget.imageBuilder == null) {
      return SizedBox();
    }
    return widget.imageBuilder!(context, widget.manager, msg);
  }

  Widget _buildLinkMessage(BuildContext context, LinkMessage msg) {
    if (widget.linkBuilder == null) {
      return SizedBox();
    }
    return widget.linkBuilder!(context, widget.manager, msg);
  }

  Widget _buildTextMessage(BuildContext context, TextMessage msg) {
    if (widget.textBuilder == null) {
      return SizedBox();
    }
    return widget.textBuilder!(context, widget.manager, msg);
  }

  Widget _buildVideoMessage(BuildContext context, VideoMessage msg) {
    if (widget.videoBuilder == null) {
      return SizedBox();
    }
    return widget.videoBuilder!(context, widget.manager, msg);
  }
}
