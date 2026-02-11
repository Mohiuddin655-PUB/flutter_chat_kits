import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatMessageReplySnippet extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;

  const ChatMessageReplySnippet({
    super.key,
    required this.message,
    this.onTap,
  });

  String _getPreviewText(Message message) {
    switch (message) {
      case AudioMessage():
        return '🎵 Voice message';
      case ImageMessage():
        return '📷 Photo';
      case LinkMessage():
        return message.link.length > 40
            ? '${message.link.substring(0, 40)}...'
            : message.link;
      case TextMessage():
        return message.text.length > 40
            ? '${message.text.substring(0, 40)}...'
            : message.text;
      case VideoMessage():
        return '🎥 Video';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    final senderName = isMe ? 'You' : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white : Colors.blue,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : Colors.blue[700],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getPreviewText(message),
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
