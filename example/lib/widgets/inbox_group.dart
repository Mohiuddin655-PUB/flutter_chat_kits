import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:intl/intl.dart';

class ChatInboxGroup extends StatelessWidget {
  final Profile profile;
  final GroupRoom room;
  final Status status;
  final List<Typing> typings;

  const ChatInboxGroup({
    super.key,
    required this.profile,
    required this.room,
    required this.status,
    required this.typings,
  });

  bool get isOnline => status.isOnline;

  bool get isTyping => typings.isNotEmpty;

  bool get isMe => room.isSentByMe;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  Widget? _getActiveIndicator(DateTime? lastOnline) {
    if (isOnline) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }

    if (lastOnline == null) return null;

    final difference = DateTime.now().difference(lastOnline);
    final minutes = difference.inMinutes;

    if (minutes < 1) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }

    if (minutes < 60) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${minutes}m',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final unseenCount = room.unseenCount;
    final isTyping = this.isTyping;
    final lastMessagePreview = room.formattedLastMessage(
      sender: profile.name,
      isTyping: isTyping,
    );
    final hasUnseenMessages = unseenCount > 0;
    final activeIndicator =
        _getActiveIndicator(status.lastSeen.timestampOrNull);

    return InkWell(
      onTap: () => RoomManager.i.open(context, room),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profile.photo != null
                      ? NetworkImage(profile.photo!)
                      : null,
                  child: profile.photo == null
                      ? Text(
                          profile.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (activeIndicator != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: activeIndicator,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnseenMessages
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(room.updatedAt.timestampOrNull),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnseenMessages
                              ? Colors.blue[600]
                              : Colors.grey[600],
                          fontWeight: hasUnseenMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessagePreview,
                          style: TextStyle(
                            fontSize: 14,
                            color: isTyping
                                ? Colors.blue[600]
                                : (hasUnseenMessages
                                    ? Colors.black87
                                    : Colors.grey[700]),
                            fontWeight: hasUnseenMessages
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontStyle: isTyping ? FontStyle.italic : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unseenCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unseenCount > 99 ? '99+' : unseenCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
