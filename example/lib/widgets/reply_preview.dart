import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatReplyMessagePreview extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const ChatReplyMessagePreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  String _getPreviewText() {
    final msg = message;
    switch (msg) {
      case AudioMessage():
        return '🎵 Voice message';
      case ImageMessage():
        return '📷 Photo';
      case LinkMessage():
        return msg.link.length > 50
            ? '${msg.link.substring(0, 50)}...'
            : msg.link;
      case TextMessage():
        return msg.text.length > 50
            ? '${msg.text.substring(0, 50)}...'
            : msg.text;
      case VideoMessage():
        return '🎥 Video';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    final senderName = isMe ? 'You' : 'Other User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPreviewText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
