import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class ChatInboxDirect extends StatefulWidget {
  final Profile profile;
  final DirectRoom room;
  final Status status;
  final Typing? typing;

  const ChatInboxDirect({
    super.key,
    required this.profile,
    required this.room,
    required this.status,
    required this.typing,
  });

  @override
  State<ChatInboxDirect> createState() => _ChatInboxDirectState();
}

class _ChatInboxDirectState extends State<ChatInboxDirect>
    with SingleTickerProviderStateMixin {
  late final controller = SlidableController(this);

  bool get isOnline => widget.status.isOnline;

  bool get isTyping => widget.typing != null && !widget.typing!.isEmpty;

  bool get isMe => widget.room.isSentByMe;

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
    final unseenCount = widget.room.unseenCount;
    final isTyping = this.isTyping;
    final lastMessagePreview = widget.room.formattedLastMessage(
      sender: widget.profile.name,
      isTyping: isTyping,
    );
    final hasUnseenMessages = unseenCount > 0;
    final activeIndicator =
        _getActiveIndicator(widget.status.lastSeen.timestampOrNull);

    final isMuted = widget.room.isMutedByMe;

    return InkWell(
      onTap: () => RoomManager.i.connect(context, widget.room),
      child: Slidable(
        controller: controller,
        direction: Axis.horizontal,
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            Spacer(),
            GestureDetector(
              onTap: () {
                controller.close();
                if (widget.room.isMutedByMe) {
                  RoomManager.i.unmute(widget.room);
                } else {
                  RoomManager.i.mute(widget.room);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    isMuted
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_on_outlined,
                    color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                controller.close();
                RoomManager.i.leave(widget.room);
              },
              child: Container(
                width: 40,
                height: 40,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group_remove, color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.profile.photo != null
                        ? NetworkImage(widget.profile.photo!)
                        : null,
                    child: widget.profile.photo == null
                        ? Text(
                            widget.profile.name?[0].toUpperCase() ?? "?",
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
                            widget.profile.name ?? "?",
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
                          _formatTime(widget.room.updatedAt.timestampOrNull),
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
                        if (isMuted)
                          Icon(
                            Icons.notifications_off_outlined,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
