import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:share_plus/share_plus.dart';

class ChatMessageContextMenu extends StatefulWidget {
  final ChatManager manager;
  final Message message;

  const ChatMessageContextMenu({
    super.key,
    required this.manager,
    required this.message,
  });

  static void show(BuildContext context, ChatManager manager, Message message) {
    showModalBottomSheet(
      isDismissible: true,
      context: context,
      builder: (c) => ChatMessageContextMenu(
        manager: manager,
        message: message,
      ),
    );
  }

  @override
  State<ChatMessageContextMenu> createState() => _ChatMessageContextMenuState();
}

class _ChatMessageContextMenuState extends State<ChatMessageContextMenu> {
  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMe = msg.isSentByMe;
    final isDeletedForEveryone = msg.shouldRemove;

    final content = msg is TextMessage
        ? msg.text
        : msg is LinkMessage
            ? msg.link
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDeletedForEveryone) ...[
            _buildReactionRow(context),
            const Divider(),
            _buildMenuItem(
              context,
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                widget.manager.reply(msg);
              },
            ),
            if (isMe && (msg is TextMessage || msg is LinkMessage))
              _buildMenuItem(
                context,
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            if (content.isNotEmpty)
              _buildMenuItem(
                context,
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: content));
                },
              ),
            _buildMenuItem(
              context,
              icon: Icons.push_pin_outlined,
              label: msg.isPinned ? 'Unpin' : 'Pin',
              onTap: () {
                Navigator.pop(context);
                widget.manager.togglePin(msg);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.forward,
              label: 'Forward',
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(context);
              },
            ),
            if (widget.message.type == MessageType.image ||
                widget.message.type == MessageType.video ||
                widget.message.type == MessageType.audio)
              _buildMenuItem(
                context,
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  Navigator.pop(context);
                  _shareMessage(context);
                },
              ),
          ],
          if (isDeletedForEveryone)
            _buildMenuItem(
              context,
              icon: Icons.delete_sweep,
              label: 'Remove',
              onTap: () {
                Navigator.pop(context);
                widget.manager.remove(msg);
              },
              textColor: Colors.red,
            )
          else if (isMe)
            _buildMenuItem(
              context,
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
              textColor: Colors.red,
            )
          else
            _buildMenuItem(
              context,
              icon: Icons.delete_outline,
              label: 'Delete for me',
              onTap: () {
                Navigator.pop(context);
                widget.manager.deleteForMe(msg);
              },
              textColor: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildReactionRow(BuildContext context) {
    final msg = widget.message;
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((reaction) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.manager.react(msg, reaction);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Text(
                reaction,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        label,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isMe = widget.message.isSentByMe;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              ListTile(
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  widget.manager.delete(
                    widget.message,
                  );
                },
              ),
            ListTile(
              title: const Text('Delete for me'),
              onTap: () {
                Navigator.pop(dialogContext);
                widget.manager.deleteForMe(widget.message);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(BuildContext context) async {}

  void _shareMessage(BuildContext context) {
    final msg = widget.message;
    final urls = [
      if (msg is AudioMessage) msg.url,
      if (msg is ImageMessage) ...msg.urls,
      if (msg is VideoMessage) msg.url,
    ];
    final caption = [
      if (msg is ImageMessage) msg.caption,
      if (msg is VideoMessage) msg.caption,
    ].firstOrNull;

    if (urls.length == 1) {
      SharePlus.instance.share(ShareParams(
        uri: Uri.tryParse(urls.first),
        text: caption,
      ));
    } else if (urls.isNotEmpty) {
      SharePlus.instance.share(ShareParams(
        uri: Uri.tryParse(urls.first),
        text: caption,
      ));
    }
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.message.content);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              widget.manager.edit(widget.message, newContent);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
