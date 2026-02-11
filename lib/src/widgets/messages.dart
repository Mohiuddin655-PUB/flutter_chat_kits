import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../models/message.dart';
import '../utils/chat_ui.dart';
import 'message.dart';

class ChatMessages extends StatefulWidget {
  final bool shrinkWrap;
  final ScrollController controller;
  final List<Message> messages;
  final EdgeInsets padding;

  const ChatMessages({
    super.key,
    this.shrinkWrap = false,
    required this.controller,
    required this.messages,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  bool _isAtBottom = true;
  int _previousMessageCount = 0;

  ChatUiConfigs get config => RoomManager.i.uiConfigs;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;

    final atBottom = widget.controller.offset <= 100;
    if (_isAtBottom != atBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  @override
  void didUpdateWidget(ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > _previousMessageCount && _isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.hasClients) {
          widget.controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousMessageCount = widget.messages.length;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      shrinkWrap: widget.shrinkWrap,
      controller: widget.controller,
      padding: widget.padding,
      children: [
        _buildTyping(context),
        if (widget.messages.isEmpty)
          _buildNoMessages(context)
        else
          ..._buildMessages(context, widget.messages.reversed.toList()),
        _buildProfile(context),
      ],
    );
  }

  List<Widget> _buildMessages(BuildContext context, List<Message> messages) {
    final widgets = <Widget>[];
    for (int i = 0; i < messages.length; i++) {
      final current = messages[i];
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final cDate = current.createdAt.normalized;
      final nDate = next?.createdAt.normalized;

      widgets.add(
        ChatMessage(
          key: ValueKey(current.id),
          message: current,
          audioBuilder: config.audioBuilder,
          deletedBuilder: config.deletedBuilder,
          imageBuilder: config.imageBuilder,
          linkBuilder: config.linkBuilder,
          textBuilder: config.textBuilder,
          videoBuilder: config.videoBuilder,
        ),
      );

      if (nDate == null || !_isSameDay(cDate, nDate)) {
        widgets.add(
          config.groupDateBuilder(context, current.createdAt.timestamp),
        );
      }
    }

    return widgets;
  }

  Widget _buildNoMessages(BuildContext context) {
    if (config.noMessagesBuilder == null) return SizedBox();
    return config.noMessagesBuilder!(context);
  }

  Widget _buildTyping(BuildContext context) {
    if (config.typingBuilder == null) return SizedBox();
    return ValueListenableBuilder(
      valueListenable: ChatManager.i.typings,
      builder: (context, typings, child) {
        if (typings.isEmpty) return SizedBox.shrink();
        return config.typingBuilder!(context, typings);
      },
    );
  }

  Widget _buildProfile(BuildContext context) {
    if (config.profileBuilder == null) return SizedBox();
    return ListenableBuilder(
      listenable: Listenable.merge([
        ChatManager.i.profile,
        ChatManager.i.status,
      ]),
      builder: (context, child) {
        final profile = ChatManager.i.profile.value;
        final status = ChatManager.i.status.value;
        return config.profileBuilder!(context, profile, status);
      },
    );
  }
}
