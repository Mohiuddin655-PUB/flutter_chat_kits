import 'package:flutter/material.dart'
    show
        StatefulWidget,
        PreferredSizeWidget,
        ValueChanged,
        BuildContext,
        Widget,
        State,
        Size,
        kToolbarHeight;

import '../core/chat_manager.dart' show ChatManager;
import '../models/profile.dart' show Profile;
import '../models/status.dart' show Status;
import '../models/typing.dart' show Typing;

// ── Data ──────────────────────────────────────────────────────────────────────

class ChatAppbarData {
  final bool isDeleted;
  final Profile profile;
  final Status status;
  final List<Typing> typings;

  bool get isTyping => typings.isNotEmpty;

  const ChatAppbarData({
    required this.isDeleted,
    required this.profile,
    required this.status,
    required this.typings,
  });
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ChatAppbar extends StatefulWidget implements PreferredSizeWidget {
  final ChatManager manager;
  final double height;
  final ValueChanged<ChatAppbarData>? onChanged;
  final Widget Function(BuildContext context, ChatAppbarData data) builder;

  const ChatAppbar({
    super.key,
    required this.manager,
    required this.builder,
    this.height = kToolbarHeight,
    this.onChanged,
  });

  @override
  State<ChatAppbar> createState() => _ChatAppbarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

// ── State ─────────────────────────────────────────────────────────────────────

class _ChatAppbarState extends State<ChatAppbar> {
  // ── Computed Data ──────────────────────────────────────────────────────────

  ChatManager get _manager => widget.manager;

  ChatAppbarData get _data => ChatAppbarData(
        isDeleted: _manager.isDeleted,
        profile: _manager.profile,
        status: _manager.status,
        typings: List.unmodifiable(_manager.typings),
      );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _subscribe(_manager);
  }

  @override
  void didUpdateWidget(covariant ChatAppbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manager != widget.manager) {
      _unsubscribe(oldWidget.manager);
      _subscribe(_manager);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _unsubscribe(_manager);
    super.dispose();
  }

  // ── Subscription ───────────────────────────────────────────────────────────

  void _subscribe(ChatManager manager) {
    manager.profileNotifier.addListener(_rebuild);
    manager.statusNotifier.addListener(_rebuild);
    manager.typingsNotifier.addListener(_rebuild);
    manager.deletedNotifier.addListener(_rebuild);
  }

  void _unsubscribe(ChatManager manager) {
    manager.profileNotifier.removeListener(_rebuild);
    manager.statusNotifier.removeListener(_rebuild);
    manager.typingsNotifier.removeListener(_rebuild);
    manager.deletedNotifier.removeListener(_rebuild);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged?.call(_data);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data);
  }
}
