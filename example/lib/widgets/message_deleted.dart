import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChattingMessageDeleted extends StatelessWidget {
  final Message message;

  const ChattingMessageDeleted({super.key, required this.message});

  bool get isMe => message.isSentByMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block,
          size: 14,
          color: isMe ? Colors.white70 : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          'This message was deleted',
          style: TextStyle(
            color: isMe ? Colors.white70 : Colors.grey[600],
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
