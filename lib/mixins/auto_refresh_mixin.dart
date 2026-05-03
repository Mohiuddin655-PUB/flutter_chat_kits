import 'dart:async';

import '../core/room_manager_base.dart';

mixin AutoRefreshMixin on RoomManagerBase {
  Timer? _autoRefreshTimer;
  DateTime _lastUpdate = DateTime.now();

  Duration get autoRefreshInterval => const Duration(minutes: 1);

  void startAutoRefresh() {
    stopAutoRefresh();
    _lastUpdate = DateTime.now();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      final elapsed = DateTime.now().difference(_lastUpdate);
      if (elapsed >= autoRefreshInterval) notify();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void notifyListeners() {
    _lastUpdate = DateTime.now();
    super.notifyListeners();
  }
}
