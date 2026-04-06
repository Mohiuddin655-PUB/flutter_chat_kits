import 'dart:async';

import 'package:flutter/material.dart';

abstract class BaseNotifier extends ChangeNotifier with WidgetsBindingObserver {
  final Duration pausedDurationWhenAppBackground;
  final Future<bool> connection;
  final Stream<bool> connectivity;
  Timer? _pausedTimer;
  StreamSubscription? _subscription;
  bool _active = true;
  bool _paused = false;
  bool _connected = false;
  String me = '';

  bool get isActive => _active;

  bool get isLoggedIn => me.isNotEmpty;

  bool get isConnected => _connected;

  bool get isPaused => _paused;

  void _onPaused() {
    _pausedTimer?.cancel();
    _pausedTimer = Timer(pausedDurationWhenAppBackground, () {
      _pausedTimer?.cancel();
      _paused = true;
      paused();
    });
  }

  BaseNotifier(
    this.pausedDurationWhenAppBackground,
    this.connection,
    this.connectivity,
  ) {
    void setup(bool v) {
      _connected = v;
      notify();
      if (_connected) {
        if (isLoggedIn) run();
      } else {
        stop();
      }
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      connection.then(setup);
      _subscription = connectivity.listen(setup);
    });
  }

  void connected() {
    _connected = true;
    notifyListeners();
    run();
  }

  void disconnected() {
    _connected = false;
    notifyListeners();
    stop();
  }

  void attach(String uid, {bool? connected}) {
    me = uid;
    notifyListeners();
    _connected = connected ?? _connected;
    if (_connected) run();
  }

  void detach() {
    me = '';
    notifyListeners();
    stop();
  }

  void run();

  void stop();

  void paused();

  void background();

  void foreground();

  void notify() => notifyListeners();

  @protected
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final status = state == AppLifecycleState.resumed;
    if (_active == status) return;
    _active = status;
    if (_active) {
      _pausedTimer?.cancel();
      _paused = false;
      foreground();
    } else {
      background();
      _onPaused();
    }
  }

  @protected
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _pausedTimer?.cancel();
    stop();
    super.dispose();
  }
}
