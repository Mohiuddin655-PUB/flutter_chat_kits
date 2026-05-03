import 'dart:async' show Timer, StreamSubscription;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, protected, mustCallSuper, kDebugMode, debugPrint;
import 'package:flutter/material.dart'
    show WidgetsBindingObserver, AppLifecycleState, WidgetsBinding;

abstract class BaseNotifier extends ChangeNotifier with WidgetsBindingObserver {
  // ── Configuration ──────────────────────────────────────────────────────────

  final Duration pausedDurationWhenAppBackground;
  final Future<bool> connection;
  final Stream<bool> connectivity;

  // ── Internal State ─────────────────────────────────────────────────────────

  String _me = '';
  bool _active = true;
  bool _paused = false;
  bool _connected = false;
  bool _disposed = false;
  bool _running = false;
  bool _started = false;

  Timer? _pausedTimer;
  StreamSubscription<bool>? _subscription;

  Timer? _connectivityDebounceTimer;
  bool? _pendingConnectivity;

  // ── Getters ────────────────────────────────────────────────────────────────

  String get me => _me;

  bool get isActive => _active;

  bool get isPaused => _paused;

  bool get isConnected => _connected;

  bool get isLoggedIn => _me.isNotEmpty;

  bool get isRunning => _running;

  bool get isStarted => _started;

  bool get _canRun => _connected && isLoggedIn;

  /// Debounces rapid connectivity flaps (Wi-Fi transitions, tower hopping).
  /// Without this, every flicker would tear down + restart all subscriptions.
  Duration get connectivityDebounce => const Duration(milliseconds: 750);

  // ── Constructor ────────────────────────────────────────────────────────────

  BaseNotifier({
    required this.pausedDurationWhenAppBackground,
    required this.connection,
    required this.connectivity,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  void attach(String uid, {bool? connected}) {
    if (uid.isEmpty) return;
    _ensureStarted();
    _me = uid;
    _connected = connected ?? _connected;
    _safeNotify();
    _tryRun();
  }

  void detach() {
    _me = '';
    _running = false;
    _cancelPauseTimer();
    _safeNotify();
    stop();
  }

  void connected() {
    _connected = true;
    _safeNotify();
    _tryRun();
  }

  void disconnected() {
    _connected = false;
    _running = false;
    _safeNotify();
    stop();
  }

  void notify() => _safeNotify();

  // ═══════════════════════════════════════════════════════════════════════════
  // Abstract Hooks
  // ═══════════════════════════════════════════════════════════════════════════

  void run();

  void stop();

  void paused();

  void background();

  void foreground();

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @protected
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    final isResumed = state == AppLifecycleState.resumed;
    if (_active == isResumed) return;

    _active = isResumed;

    if (_active) {
      _cancelPauseTimer();
      _paused = false;
      foreground();
      _tryRun();
    } else {
      background();
      _schedulePause();
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _cancelPauseTimer();
    stop();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  void _ensureStarted() async {
    if (_started || _disposed) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    _subscription = connectivity.listen(_onConnectivityChanged);
    try {
      final initial = await connection;
      if (_disposed) return;
      _onConnectivityChanged(initial);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[BaseNotifier] initial connection check failed: $e\n$st');
      }
    }
  }

  void _tryRun() {
    if (_disposed || !_canRun || _running) return;
    _running = true;
    run();
  }

  void _onConnectivityChanged(bool isConnected) {
    if (_disposed) return;

    _pendingConnectivity = isConnected;
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = Timer(connectivityDebounce, () {
      if (_disposed) return;
      final pending = _pendingConnectivity;
      _pendingConnectivity = null;
      if (pending == null) return;
      _applyConnectivity(pending);
    });
  }

  void _applyConnectivity(bool isConnected) {
    if (_disposed) return;
    if (_connected == isConnected) return;

    _connected = isConnected;
    _safeNotify();
    if (_connected) {
      _tryRun();
    } else {
      _running = false;
      stop();
    }
  }

  void _schedulePause() {
    _cancelPauseTimer();
    _pausedTimer = Timer(pausedDurationWhenAppBackground, () {
      if (_disposed || _active) return;
      _paused = true;
      paused();
    });
  }

  void _cancelPauseTimer() {
    _pausedTimer?.cancel();
    _pausedTimer = null;
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }
}
