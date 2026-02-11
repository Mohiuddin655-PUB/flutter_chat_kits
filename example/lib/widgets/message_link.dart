import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChattingMessageLink extends StatelessWidget {
  final LinkMessage message;

  const ChattingMessageLink({super.key, required this.message});

  bool get isMe => message.isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Text(
      message.link,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }
}
