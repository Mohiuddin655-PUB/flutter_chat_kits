import 'package:flutter/material.dart';

import '../core/chat_manager.dart';
import '../models/message.dart';
import '../models/visibility.dart';
import 'visibility_scope.dart';

// ── Types ─────────────────────────────────────────────────────────────────────

typedef ChatMessageBuilder<T extends Message> =
    Widget Function(BuildContext context, T message);

typedef ChatMessageVisibilityCallback = void Function(VisibilityInfo info);

typedef ChatMessageVisibilityDetectorBuilder =
    Widget Function(
      BuildContext context,
      String id,
      Widget child,
      ChatMessageVisibilityCallback callback,
    );

// ── Widget ────────────────────────────────────────────────────────────────────

class ChatMessage extends StatefulWidget {
  final ChatManager manager;
  final Message message;
  final double visibilityThreshold;
  final ChatMessageVisibilityDetectorBuilder? visibilityDetectorBuilder;
  final ChatMessageBuilder<AudioMessage>? audioBuilder;
  final ChatMessageBuilder<CustomMessage>? customBuilder;
  final ChatMessageBuilder<Message>? deletedBuilder;
  final ChatMessageBuilder<ImageMessage>? imageBuilder;
  final ChatMessageBuilder<LinkMessage>? linkBuilder;
  final ChatMessageBuilder<TextMessage>? textBuilder;
  final ChatMessageBuilder<VideoMessage>? videoBuilder;

  const ChatMessage({
    super.key,
    required this.manager,
    required this.message,
    this.visibilityThreshold = 0.5,
    this.visibilityDetectorBuilder,
    this.audioBuilder,
    this.customBuilder,
    this.deletedBuilder,
    this.imageBuilder,
    this.linkBuilder,
    this.textBuilder,
    this.videoBuilder,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _ChatMessageState extends State<ChatMessage> {
  final ValueNotifier<bool> _visibleNotifier = ValueNotifier(false);

  bool get _isVisible => _visibleNotifier.value;

  @override
  void didUpdateWidget(covariant ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final messageChanged = oldWidget.message.id != widget.message.id;
    final managerChanged = oldWidget.manager != widget.manager;

    if (messageChanged || managerChanged) {
      if (_visibleNotifier.value) {
        oldWidget.manager.invisible(oldWidget.message);
      }
      _visibleNotifier.value = false;
    }
  }

  @override
  void dispose() {
    if (_isVisible) widget.manager.invisible(widget.message);
    _visibleNotifier.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final nowVisible = info.visibleFraction > widget.visibilityThreshold;
    if (_isVisible == nowVisible) return;

    _visibleNotifier.value = nowVisible;

    if (nowVisible) {
      widget.manager.visible(widget.message);
    } else {
      widget.manager.invisible(widget.message);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.message.isRemovedByMe) return const SizedBox.shrink();

    final content = ChatVisibilityScope(
      notifier: _visibleNotifier,
      child: _buildLayout(context),
    );

    if (widget.visibilityDetectorBuilder == null) return content;

    return widget.visibilityDetectorBuilder!(
      context,
      'msg_${widget.message.id}',
      content,
      _onVisibilityChanged,
    );
  }

  Widget _buildLayout(BuildContext context) {
    final msg = widget.message;

    if (msg.isDeleted || msg.isDeletedByMe) {
      return _build(context, msg, widget.deletedBuilder);
    }

    return switch (msg) {
      AudioMessage() => _build(context, msg, widget.audioBuilder),
      CustomMessage() => _build(context, msg, widget.customBuilder),
      ImageMessage() => _build(context, msg, widget.imageBuilder),
      LinkMessage() => _build(context, msg, widget.linkBuilder),
      TextMessage() => _build(context, msg, widget.textBuilder),
      VideoMessage() => _build(context, msg, widget.videoBuilder),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _build<T extends Message>(
    BuildContext context,
    T msg,
    ChatMessageBuilder<T>? builder,
  ) {
    if (builder == null) return const SizedBox.shrink();
    return builder(context, msg);
  }
}
