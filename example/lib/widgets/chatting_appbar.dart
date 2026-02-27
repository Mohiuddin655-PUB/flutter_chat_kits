import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:intl/intl.dart';

class ChattingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatAppbarConfigs configs;

  const ChattingAppBar({
    super.key,
    required this.configs,
  });

  String _getLastOnlineText(DateTime? lastOnline) {
    if (lastOnline == null) return '';

    final difference = DateTime.now().difference(lastOnline);
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (minutes < 1) return 'Active now';
    if (minutes < 60) return 'Active ${minutes}m ago';
    if (hours < 24) return 'Active ${hours}h ago';
    if (days == 1) return 'Active yesterday';
    return 'Active ${DateFormat('MMM d').format(lastOnline)}';
  }

  @override
  Widget build(BuildContext context) {
    final activeIndicator =
        _buildActiveIndicator(configs.status.lastSeen.timestampOrNull);
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                backgroundImage: configs.profile.photo != null
                    ? NetworkImage(configs.profile.photo!)
                    : null,
                child: configs.profile.photo == null
                    ? Text(
                        configs.profile.name?[0].toUpperCase() ?? "?",
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
                Text(
                  configs.profile.name ?? '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  configs.isTyping
                      ? "Typing..."
                      : configs.status.isOnline == true
                          ? 'Active now'
                          : _getLastOnlineText(
                              configs.status.lastSeen.timestampOrNull),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActiveIndicator(DateTime? lastOnline) {
    if (configs.status.isOnline) {
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
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
