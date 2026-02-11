import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatScrollDownButton extends StatelessWidget {
  final List<Message> unseens;
  final VoidCallback onGo;

  const ChatScrollDownButton({
    super.key,
    required this.unseens,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        onPressed: onGo,
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.black87,
        ),
      ),
    );
  }
}
