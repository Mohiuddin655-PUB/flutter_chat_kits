import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'actions.dart';
import 'reply_snippet.dart';

class ChatMessageBubble extends StatefulWidget {
  final Message message;
  final Widget child;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late final controller = SlidableController(this);

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isSentByMe;
    return GestureDetector(
      onLongPress: () {
        ChatMessageContextMenu.show(context, widget.message);
      },
      child: Slidable(
        controller: controller,
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          extentRatio: 0.1,
          children: [
            GestureDetector(
              onTap: () {
                controller.close();
                ChatManager.i.reply(widget.message);
              },
              child: Icon(
                Icons.reply_outlined,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.isForwarded ||
                          widget.message.isEdited ||
                          widget.message.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.message.isForwarded) ...[
                                Icon(
                                  Icons.forward,
                                  size: 12,
                                  color:
                                      isMe ? Colors.white70 : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Forwarded',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (widget.message.isForwarded &&
                                  (widget.message.isEdited ||
                                      widget.message.isPinned))
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (widget.message.isPinned) ...[
                                Icon(
                                  Icons.push_pin,
                                  size: 12,
                                  color:
                                      isMe ? Colors.white70 : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (widget.message.isPinned &&
                                  widget.message.isEdited)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (widget.message.isEdited) ...[
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color:
                                      isMe ? Colors.white70 : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edited',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (widget.message.replyId.isNotEmpty)
                        _buildReplySnippet(context, isMe),
                      widget.child,
                      if (widget.message.reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children:
                                widget.message.reactions.entries.map((entry) {
                              return GestureDetector(
                                onTap: () {
                                  ChatManager.i.react(widget.message, null);
                                },
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe) _buildStatusIcon(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final status = widget.message.status;
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatus.deleting:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red,
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 16,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.grey,
        );
      case MessageStatus.seen:
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue,
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildReplySnippet(BuildContext context, bool isMe) {
    final replyMessage = widget.message.replyMessage;
    if (replyMessage.isEmpty) return SizedBox.shrink();
    return ChatMessageReplySnippet(
      message: replyMessage,
      onTap: () {},
    );
  }
}
