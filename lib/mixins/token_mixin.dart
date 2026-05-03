import 'dart:async' show StreamSubscription;

import '../core/room_manager_base.dart' show RoomManagerBase;
import '../models/profile.dart' show UserProfileKeys;
import '../models/room.dart' show RoomKeys;
import '../utils/field_value.dart' show ChatValueDelete;
import '../utils/platform.dart' show currentPlatform;

mixin TokenMixin on RoomManagerBase {
  StreamSubscription<String?>? _tokenRefreshSub;

  String? _lastSavedToken;
  String? _lastSavedFor;

  String _cacheKey(String uid) => 'chat_token:$uid';

  Future<void> registerToken() async {
    if (me.isEmpty) return;
    try {
      _listenForTokenRefresh();

      final token = await notificationDelegate.fetchToken();
      if (token == null || token.isEmpty) return;

      if (_lastSavedFor == me && _lastSavedToken == token) return;

      final cached = await cacheDelegate.read(_cacheKey(me));
      if (cached == token) {
        _lastSavedToken = token;
        _lastSavedFor = me;
        return;
      }

      final valid = await notificationDelegate.isTokenValid(token);
      if (!valid) {
        await _refreshToken();
        return;
      }

      await _saveTokenToProfile(token);
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'TokenMixin.registerToken',
      );
    }
  }

  Future<void> unregisterToken() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    final user = me;
    _lastSavedToken = null;
    _lastSavedFor = null;

    if (user.isEmpty) return;
    try {
      await profileDelegate.update(user, {UserProfileKeys.i.token: ''});
      await cacheDelegate.write(_cacheKey(user), null);
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'TokenMixin.unregisterToken',
      );
    }
  }

  Future<void> wipeToken() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    final user = me;
    _lastSavedToken = null;
    _lastSavedFor = null;

    try {
      if (user.isNotEmpty) {
        await profileDelegate.update(user, {UserProfileKeys.i.token: ''});
        await cacheDelegate.write(_cacheKey(user), null);
      }
      await notificationDelegate.deleteToken();
    } catch (e, st) {
      errorReporter.report(e, stackTrace: st, source: 'TokenMixin.wipeToken');
    }
  }

  Future<void> _refreshToken() async {
    if (me.isEmpty) return;
    try {
      await notificationDelegate.deleteToken();

      final fresh = await notificationDelegate.fetchToken();
      if (fresh == null || fresh.isEmpty) return;

      if (_lastSavedFor == me && _lastSavedToken == fresh) return;

      final cached = await cacheDelegate.read(_cacheKey(me));
      if (cached == fresh) {
        _lastSavedToken = fresh;
        _lastSavedFor = me;
        return;
      }

      final valid = await notificationDelegate.isTokenValid(fresh);
      if (!valid) return;

      await _saveTokenToProfile(fresh);
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'TokenMixin._refreshToken',
      );
    }
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = notificationDelegate.onTokenRefresh.listen(
      (token) async {
        if (me.isEmpty) return;
        if (token == null || token.isEmpty) return;
        if (_lastSavedFor == me && _lastSavedToken == token) return;
        try {
          final cached = await cacheDelegate.read(_cacheKey(me));
          if (cached == token) {
            _lastSavedToken = token;
            _lastSavedFor = me;
            return;
          }
          final valid = await notificationDelegate.isTokenValid(token);
          if (!valid) return;
          await _saveTokenToProfile(token);
        } catch (e, st) {
          errorReporter.report(
            e,
            stackTrace: st,
            source: 'TokenMixin.onTokenRefresh',
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        errorReporter.report(
          error,
          stackTrace: stackTrace,
          source: 'TokenMixin.onTokenRefresh',
        );
      },
    );
  }

  Future<void> _saveTokenToProfile(String token) async {
    await profileDelegate.update(me, {
      UserProfileKeys.i.platform: currentPlatform,
      UserProfileKeys.i.token: token,
    });
    _lastSavedToken = token;
    _lastSavedFor = me;
    await cacheDelegate.write(_cacheKey(me), token);
  }

  Future<void> resetUnseenCount(String roomId) async {
    if (me.isEmpty) return;
    try {
      await roomDelegate.update(
        roomId,
        n.normalize({
          '${RoomKeys.i.unseenCount}.$me': ChatValueDelete(),
        }, n.room),
      );
      notify();
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'TokenMixin.resetUnseenCount',
        context: {'roomId': roomId},
      );
    }
  }
}
