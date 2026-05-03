import '../delegates/ai.dart' show ChatAiDelegate;
import '../delegates/cache.dart' show ChatCacheDelegate;
import '../delegates/error_reporter.dart'
    show ChatErrorReporter, DefaultChatErrorReporter;
import '../delegates/message.dart' show ChatMessageDelegate;
import '../delegates/normalizer.dart' show ChatFieldValueNormalizer;
import '../delegates/notification.dart' show ChatNotificationDelegate;
import '../delegates/profile.dart' show ChatProfileDelegate;
import '../delegates/room.dart' show ChatRoomDelegate;
import '../delegates/settings.dart'
    show ChatUserSettingsDelegate, ChatSilentNotification;
import '../delegates/status.dart' show ChatStatusDelegate;
import '../delegates/typing.dart' show ChatTypingDelegate;
import '../mixins/auto_refresh_mixin.dart' show AutoRefreshMixin;
import '../mixins/bot_response_mixin.dart' show BotResponseMixin;
import '../mixins/manager_lifecycle_mixin.dart' show ManagerLifecycleMixin;
import '../mixins/message_mixin.dart' show MessageMixin;
import '../mixins/notification_mixin.dart' show NotificationMixin;
import '../mixins/offline_queue_mixin.dart' show OfflineQueueMixin;
import '../mixins/participant_mixin.dart' show ParticipantMixin;
import '../mixins/presence_mixin.dart' show PresenceMixin;
import '../mixins/room_crud_mixin.dart' show RoomCrudMixin;
import '../mixins/room_toggle_mixin.dart' show RoomToggleMixin;
import '../mixins/room_update_mixin.dart' show RoomUpdateMixin;
import '../mixins/subscription_mixin.dart' show SubscriptionMixin;
import '../mixins/token_mixin.dart' show TokenMixin;
import '../models/message.dart' show Message;
import '../models/profile.dart' show Profile;
import '../utils/model_configs.dart' show ChatModelConfigs;
import 'chat_manager.dart' show ChatManagerMessaging;
import 'room_manager_base.dart'
    show
        RoomManagerBase,
        OnChatPageOpeningCallback,
        VerifyToSendMessage,
        OnDeniedToSendMessage;

class RoomManager extends RoomManagerBase
    with
        SubscriptionMixin,
        ManagerLifecycleMixin,
        RoomCrudMixin,
        RoomUpdateMixin,
        RoomToggleMixin,
        ParticipantMixin,
        PresenceMixin,
        NotificationMixin,
        OfflineQueueMixin,
        MessageMixin,
        TokenMixin,
        BotResponseMixin,
        AutoRefreshMixin {
  // ── Constructor ────────────────────────────────────────────────────────────

  RoomManager._({
    required super.pausedDurationWhenAppBackground,
    required super.connection,
    required super.connectivity,
    required this.botEnabled,
    required this.syncTokenEnabled,
    required this.fetchGroupUserProfiles,
    required this.preloadInboxMetadataCount,
    required this.maxCachedManagers,
    required this.modelConfigs,
    required ChatAiDelegate ai,
    required ChatCacheDelegate cache,
    required ChatRoomDelegate room,
    required ChatMessageDelegate message,
    required ChatStatusDelegate status,
    required ChatTypingDelegate typing,
    required ChatProfileDelegate profile,
    required ChatNotificationDelegate notification,
    required ChatUserSettingsDelegate settings,
    required ChatFieldValueNormalizer normalizer,
    required ChatErrorReporter errorReporter,
  })  : _ai = ai,
        _cache = cache,
        _room = room,
        _message = message,
        _status = status,
        _typing = typing,
        _profile = profile,
        _notification = notification,
        _settings = settings,
        _errorReporter = errorReporter,
        _n = normalizer;

  // ── Singleton ─────────────────────────────────────────────────────────────

  static RoomManager? _instance;

  static RoomManager get i {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'RoomManager.init() must be called before accessing RoomManager.i.',
      );
    }
    return instance;
  }

  static void init({
    bool botEnabled = false,
    bool syncTokenEnabled = false,
    bool fetchGroupUserProfiles = false,
    int preloadInboxMetadataCount = 10,
    int maxCachedManagers = 10,
    Duration pausedDurationWhenAppBackground = const Duration(minutes: 2),
    required Future<bool> connection,
    required Stream<bool> connectivity,
    required ChatAiDelegate ai,
    required ChatCacheDelegate cache,
    required ChatRoomDelegate room,
    required ChatMessageDelegate message,
    required ChatStatusDelegate status,
    required ChatTypingDelegate typing,
    required ChatProfileDelegate profile,
    required ChatNotificationDelegate notification,
    required ChatUserSettingsDelegate settings,
    required ChatFieldValueNormalizer normalizer,
    ChatModelConfigs modelConfigs = const ChatModelConfigs(),
    ChatErrorReporter errorReporter = const DefaultChatErrorReporter(),
  }) {
    _instance?.dispose();
    _instance = RoomManager._(
      botEnabled: botEnabled,
      syncTokenEnabled: syncTokenEnabled,
      pausedDurationWhenAppBackground: pausedDurationWhenAppBackground,
      connection: connection,
      connectivity: connectivity,
      fetchGroupUserProfiles: fetchGroupUserProfiles,
      preloadInboxMetadataCount: preloadInboxMetadataCount,
      maxCachedManagers: maxCachedManagers,
      modelConfigs: modelConfigs,
      ai: ai,
      cache: cache,
      room: room,
      message: message,
      status: status,
      typing: typing,
      profile: profile,
      notification: notification,
      settings: settings,
      normalizer: normalizer,
      errorReporter: errorReporter,
    );
  }

  // ── Dependencies ──────────────────────────────────────────────────────────

  @override
  final bool fetchGroupUserProfiles;

  @override
  final ChatModelConfigs modelConfigs;

  @override
  final bool botEnabled;

  @override
  final bool syncTokenEnabled;

  @override
  final int preloadInboxMetadataCount;

  @override
  final int maxCachedManagers;

  final ChatFieldValueNormalizer _n;
  final ChatAiDelegate _ai;
  final ChatCacheDelegate _cache;
  final ChatRoomDelegate _room;
  final ChatMessageDelegate _message;
  final ChatStatusDelegate _status;
  final ChatTypingDelegate _typing;
  final ChatProfileDelegate _profile;
  final ChatNotificationDelegate _notification;
  final ChatUserSettingsDelegate _settings;
  final ChatErrorReporter _errorReporter;

  @override
  ChatFieldValueNormalizer get n => _n;

  @override
  ChatAiDelegate get aiDelegate => _ai;

  @override
  ChatCacheDelegate get cacheDelegate => _cache;

  @override
  ChatRoomDelegate get roomDelegate => _room;

  @override
  ChatMessageDelegate get messageDelegate => _message;

  @override
  ChatStatusDelegate get statusDelegate => _status;

  @override
  ChatTypingDelegate get typingDelegate => _typing;

  @override
  ChatProfileDelegate get profileDelegate => _profile;

  @override
  ChatNotificationDelegate get notificationDelegate => _notification;

  @override
  ChatUserSettingsDelegate get settingsDelegate => _settings;

  @override
  ChatErrorReporter get errorReporter => _errorReporter;

  // ═══════════════════════════════════════════════════════════════════════════
  // Login / Logout
  // ═══════════════════════════════════════════════════════════════════════════

  void login(String uid, {bool? connected}) {
    if (uid.isEmpty) return;
    if (me == uid) return;
    if (me.isNotEmpty) logout();
    attach(uid, connected: connected);
    if (syncTokenEnabled) registerToken();
  }

  void logout() {
    if (me.isEmpty) return;
    if (syncTokenEnabled) unregisterToken();
    detach();
    _clearUserData();
    notify();
  }

  void _clearUserData() {
    mappedRooms = {};
    mappedProfiles = {};
    mappedStatuses = {};
    mappedTypings = {};
    activeParticipants = {};
    loading = true;
    error = false;
    disposeAllRoomNotifiers();
    clearOfflineQueue();
    clearFailedMessages();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BaseNotifier Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void attach(String uid, {bool? connected}) {
    super.attach(uid, connected: connected);
    markAsOnline(true);
  }

  @override
  void detach() {
    markAsOnline(false);
    super.detach();
  }

  @override
  void run() {
    startListening();
    startMeProfileListener();
    startAutoRefresh();
    drainOfflineQueue();
    retryFailedMessages();
  }

  @override
  void stop() => _teardown();

  @override
  void paused() => _teardown();

  @override
  void foreground() {
    startListening();
    markAsOnline(true);
    startAutoRefresh();
    drainOfflineQueue();
    retryFailedMessages();
  }

  @override
  void background() {
    markAsOnline(false);
    stopAutoRefresh();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Say Hello
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sayHello(
    String friendId,
    Message message, {
    Profile? profile,
    ChatSilentNotification? notification,
    OnChatPageOpeningCallback? callback,
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  }) async {
    try {
      if (profile != null && profile.id.isNotEmpty) {
        mappedProfiles[profile.id] = profile;
      }

      final target = await createOrGetThread([friendId]);
      if (target.isEmpty) return;

      if (verifyToSend != null && !verifyToSend(target)) {
        onDeniedToSend?.call(target);
        return;
      }

      final mgr = managerForRoom(target);
      await mgr.send(
        message,
        verifyToSend: verifyToSend,
        onDeniedToSend: onDeniedToSend,
        notification: notification,
      );

      if (callback != null) {
        mgr.connect();
        try {
          await callback(mgr);
        } finally {
          mgr.disconnect();
        }
      }
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomManager.sayHello',
        context: {'friendId': friendId},
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private
  // ═══════════════════════════════════════════════════════════════════════════

  void _teardown() {
    disposeSubscriptions();
    disposeAllManagers();
    stopAutoRefresh();
  }
}
