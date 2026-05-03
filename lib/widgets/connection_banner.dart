import 'package:flutter/material.dart';

import '../core/room_manager.dart';

/// Builder for the connection banner. Receives the current state and
/// queued message count so apps can render their own design.
typedef ChatConnectionBannerBuilder =
    Widget Function(
      BuildContext context,
      ChatConnectionState state,
      int pendingCount,
    );

/// Connection state for banner rendering.
enum ChatConnectionState {
  /// Online and connected. Banner is typically hidden.
  online,

  /// No internet — messages will queue.
  offline,

  /// Reconnecting after an offline period.
  reconnecting,
}

/// Watches RoomManager connectivity + pending queue and rebuilds when
/// either changes. Pass a [builder] to render your own banner UI; or
/// use the default banner via [ChatConnectionBanner.defaultBuilder].
class ChatConnectionBanner extends StatefulWidget {
  /// Custom builder. If null, [defaultBuilder] is used.
  final ChatConnectionBannerBuilder? builder;

  /// Whether to keep showing the banner briefly after reconnect to
  /// communicate "back online" status. Default 2 seconds.
  final Duration reconnectingDuration;

  const ChatConnectionBanner({
    super.key,
    this.builder,
    this.reconnectingDuration = const Duration(seconds: 2),
  });

  /// Default banner — orange when offline, green briefly on reconnect.
  /// Hides when fully online and queue is empty.
  static Widget defaultBuilder(
    BuildContext context,
    ChatConnectionState state,
    int pendingCount,
  ) {
    return _DefaultConnectionBanner(state: state, pendingCount: pendingCount);
  }

  @override
  State<ChatConnectionBanner> createState() => _ChatConnectionBannerState();
}

class _ChatConnectionBannerState extends State<ChatConnectionBanner> {
  bool _wasOffline = false;
  bool _showReconnecting = false;

  @override
  void initState() {
    super.initState();
    _wasOffline = !RoomManager.i.isConnected;
    RoomManager.i.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    RoomManager.i.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;

    final isOnline = RoomManager.i.isConnected;

    // Detect transition: offline → online
    if (_wasOffline && isOnline) {
      setState(() => _showReconnecting = true);
      Future.delayed(widget.reconnectingDuration, () {
        if (!mounted) return;
        setState(() => _showReconnecting = false);
      });
    }

    _wasOffline = !isOnline;
    setState(() {});
  }

  ChatConnectionState get _currentState {
    if (!RoomManager.i.isConnected) return ChatConnectionState.offline;
    if (_showReconnecting) return ChatConnectionState.reconnecting;
    return ChatConnectionState.online;
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder ?? ChatConnectionBanner.defaultBuilder;

    return ValueListenableBuilder<int>(
      valueListenable: RoomManager.i.pendingMessageCountNotifier,
      builder: (context, pendingCount, _) {
        return builder(context, _currentState, pendingCount);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Default banner UI
// ═══════════════════════════════════════════════════════════════════════════

class _DefaultConnectionBanner extends StatelessWidget {
  final ChatConnectionState state;
  final int pendingCount;

  const _DefaultConnectionBanner({
    required this.state,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShow = state != ChatConnectionState.online || pendingCount > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child:
          shouldShow
              ? Container(
                key: ValueKey(state),
                width: double.infinity,
                color: _backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state == ChatConnectionState.reconnecting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    else
                      Icon(_icon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  Color get _backgroundColor {
    return switch (state) {
      ChatConnectionState.offline => Colors.orange.shade700,
      ChatConnectionState.reconnecting => Colors.blue.shade600,
      ChatConnectionState.online => Colors.green.shade600,
    };
  }

  IconData get _icon {
    return switch (state) {
      ChatConnectionState.offline => Icons.cloud_off_rounded,
      ChatConnectionState.reconnecting => Icons.sync_rounded,
      ChatConnectionState.online => Icons.cloud_done_rounded,
    };
  }

  String get _label {
    if (state == ChatConnectionState.offline) {
      if (pendingCount > 0) {
        return 'No connection — $pendingCount message${pendingCount == 1 ? '' : 's'} waiting';
      }
      return 'No connection — messages will send when reconnected';
    }
    if (state == ChatConnectionState.reconnecting) {
      if (pendingCount > 0) {
        return 'Reconnecting — sending $pendingCount message${pendingCount == 1 ? '' : 's'}...';
      }
      return 'Reconnecting...';
    }
    if (pendingCount > 0) {
      return 'Sending $pendingCount message${pendingCount == 1 ? '' : 's'}...';
    }
    return '';
  }
}
