import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChattingMessageText extends StatelessWidget {
  final TextMessage message;

  const ChattingMessageText({super.key, required this.message});

  bool get isMe => message.isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Text(
      message.text,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }
}
