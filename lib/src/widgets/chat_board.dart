import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import 'messages.dart';

class ChatBoard extends StatefulWidget {
  final ChatManager manager;
  final double scrollThreshold;

  const ChatBoard({
    super.key,
    required this.manager,
    this.scrollThreshold = 100,
  });

  @override
  State<ChatBoard> createState() => _ChatBoardState();
}

class _ChatBoardState extends State<ChatBoard> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  bool _showScrollDownButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final atBottom = _scrollController.offset <= widget.scrollThreshold;
      if (_isAtBottom != atBottom) {
        setState(() {
          _isAtBottom = atBottom;
          _showScrollDownButton = !atBottom;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
            ),
            if (_showScrollDownButton) _buildScrollDownButton(context),
          ],
        );
      },
    );
  }

  Widget _buildScrollDownButton(BuildContext context) {
    if (RoomManager.i.uiConfigs.scrollDownButtonBuilder == null) {
      return SizedBox.shrink();
    }
    final unseen = widget.manager.unseens;
    return RoomManager.i.uiConfigs.scrollDownButtonBuilder!(
      context,
      unseen,
      _scrollToBottom,
    );
  }
}
