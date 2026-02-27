import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import 'messages.dart';

class ChatBoard extends StatefulWidget {
  final ChatManager manager;
  final double? scrollToBottomThreshold;
  final Curve? scrollToBottomAnimationCurve;
  final Duration? scrollToBottomAnimationDuration;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const ChatBoard({
    super.key,
    required this.manager,
    this.scrollToBottomThreshold,
    this.scrollToBottomAnimationCurve,
    this.scrollToBottomAnimationDuration,
    this.controller,
    this.padding,
  });

  @override
  State<ChatBoard> createState() => _ChatBoardState();
}

class _ChatBoardState extends State<ChatBoard> {
  late ScrollController _scrollController;
  bool _showScrollDownButton = false;

  @override
  void initState() {
    _scrollController = widget.controller ?? ScrollController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChatBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) _scrollController.dispose();
      _scrollController = widget.controller ?? ScrollController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: widget.scrollToBottomAnimationDuration ??
          const Duration(milliseconds: 300),
      curve: widget.scrollToBottomAnimationCurve ?? Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.manager,
      builder: (context, child) {
        final messages = widget.manager.messages;
        return Stack(
          fit: StackFit.expand,
          children: [
            ChatMessages(
              manager: widget.manager,
              messages: messages,
              controller: _scrollController,
              padding: widget.padding,
              scrollToBottomThreshold: widget.scrollToBottomThreshold,
              onHasNewMessage: (v) {
                setState(() {
                  _showScrollDownButton = v;
                });
              },
            ),
            if (_showScrollDownButton) _buildScrollDownButton(context),
          ],
        );
      },
    );
  }

  Widget _buildScrollDownButton(BuildContext context) {
    if (RoomManager.i.uiConfigs.scrollDownButtonBuilder == null) {
      return const SizedBox.shrink();
    }
    final unseen = widget.manager.unseens;
    return RoomManager.i.uiConfigs.scrollDownButtonBuilder!(
      context,
      unseen,
      _scrollToBottom,
    );
  }
}
