import 'dart:async';
import 'dart:math';

import '../core/room_manager_base.dart';
import '../delegates/ai.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/status.dart';
import '../utils/field_value.dart';

mixin BotResponseMixin on RoomManagerBase {
  // ═════════════════════════════════════════════════════════════════════════
  //  State
  // ═════════════════════════════════════════════════════════════════════════

  final Map<String, String> _repliedMessageId = {};
  final Set<String> _inFlight = {};
  final Set<String> _leaveInProgress = {};
  final Map<String, DateTime> _cooldownEndsAt = {};
  final Map<String, Timer> _autoLeaveTimers = {};
  final Random _rng = Random();

  /// Tracks whether this is the bot's first entry into a room this session.
  /// On first entry we snapshot the latest message ID and skip it — so bot
  /// only responds to messages that arrive *after* it joins.
  final Set<String> _initializedRooms = {};

  // ═════════════════════════════════════════════════════════════════════════
  //  Tuning knobs — override in subclass to customize
  // ═════════════════════════════════════════════════════════════════════════

  /// Base seconds the bot takes to "read" (before length-extra is added).
  (int, int) get readDelayRange => (2, 5);

  /// Seconds the bot pauses to "think" before starting to type.
  (int, int) get thinkDelayRange => (1, 3);

  /// Poll interval (ms) while waiting for partner to stop typing.
  int get typingPollMs => 800;

  /// Max seconds to wait for partner to finish typing.
  int get typingWaitMaxSec => 60;

  /// Grace period (sec) after partner stops typing, to let message land.
  int get typingGraceSec => 2;

  /// Minutes range before the bot auto-leaves the room.
  (int, int) get sessionMinutesRange => (20, 60);

  /// Minutes range the bot stays "away" after leaving.
  (int, int) get cooldownMinutesRange => (5, 15);

  /// Pre-written leave messages — one is picked at random.
  /// Override to match the bot's personality / language.
  List<String> get leaveMessages => const [
    "I need to go now, talk to you later! 👋",
    "Hey, gotta head out for a bit. Catch you later!",
    "Let's continue this later, see you soon! 😊",
    "Taking a little break. I'll be back! 💕",
    "I have to run, talk soon!",
  ];

  // ═════════════════════════════════════════════════════════════════════════
  //  Public entry point
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Future<void> handleBotReply(String roomId, List<Message> messages) async {
    if (!botEnabled || messages.isEmpty) return;

    final r = room(roomId);
    if (r.isEmpty) return;

    final bot = _resolveBotProfile(r);
    if (bot == null) return;

    // ── Guard: leave in progress or cooldown ──
    if (_leaveInProgress.contains(roomId)) return;
    if (_isOnCooldown(roomId)) return;

    final incoming = _latestHumanMessage(messages, bot.id);
    if (incoming == null || incoming.type == MessageType.custom) return;

    // ── Guard: first entry — snapshot current latest message, skip reply ──
    // This prevents the bot from replying to messages that existed before
    // it joined this session (e.g. after app restart or room re-entry).
    if (!_initializedRooms.contains(roomId)) {
      _initializedRooms.add(roomId);
      final hasHumanHistory = messages.any((m) {
        return m.id != incoming.id &&
            m.senderId != bot.id &&
            m.type != MessageType.custom &&
            !m.isEmpty &&
            !m.shouldRemove;
      });

      if (hasHumanHistory) {
        _repliedMessageId[roomId] = incoming.id;
        return;
      }
    }

    if (_repliedMessageId[roomId] == incoming.id) return;
    if (_inFlight.contains(roomId)) return;

    _inFlight.add(roomId);
    try {
      // Mark bot online & schedule auto-leave
      await _setBotOnline(bot.id, true);
      _scheduleAutoLeave(roomId, bot);

      // ── 1. Simulate reading ──────────────────────────────────────────
      await _readDelay(incoming);

      // ── 2. Wait if partner is typing ─────────────────────────────────
      if (_isHumanTyping(roomId, bot.id)) {
        final newMessageArrived = await _waitHumanTyping(
          roomId,
          bot.id,
          incoming.id,
        );
        if (newMessageArrived) {
          // A fresh message landed — the listener will fire a new
          // handleBotReply call, so we bail out here.
          return;
        }
        // Partner typed but didn't send. Continue with original message.
      }

      // ── 3. Think pause ───────────────────────────────────────────────
      await _thinkDelay();

      // ── 4. Typing ON → generate → typing OFF → send ─────────────────
      final request = _buildRequest(bot, messages, incoming);
      if (request == null) return;

      await _markSeenByBot(roomId, bot.id, incoming);
      await _setBotTyping(roomId, bot.id, true);

      final reply = await aiDelegate.generate(request);

      await _setBotTyping(roomId, bot.id, false);

      if (reply == null || reply.trim().isEmpty) return;

      _repliedMessageId[roomId] = incoming.id;
      await _sendBotReply(roomId, bot.id, reply.trim());
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'BotResponseMixin.handleBotReply',
        context: {'roomId': roomId, 'incomingMsgId': incoming.id},
      );
      await _setBotTyping(roomId, bot.id, false);
    } finally {
      _inFlight.remove(roomId);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  1. Read delay — proportional to message length
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _readDelay(Message incoming) async {
    final baseSec = _randomInRange(readDelayRange);

    // Extra time for longer content (~1 s per 50 chars, capped at 5 s)
    int charCount = 0;
    if (incoming is TextMessage) charCount = incoming.text.length;
    if (incoming is LinkMessage) charCount = incoming.link.length;
    final extraSec = (charCount / 50).clamp(0, 5).toInt();

    await Future.delayed(Duration(seconds: baseSec + extraSec));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  2. Partner-typing wait
  // ═════════════════════════════════════════════════════════════════════════

  /// Polls until no human in the room is typing, or until timeout.
  /// Returns true if a *new* human message landed (caller should abort).
  Future<bool> _waitHumanTyping(
    String roomId,
    String botId,
    String currentMsgId,
  ) async {
    final deadline = DateTime.now().add(Duration(seconds: typingWaitMaxSec));

    while (_isHumanTyping(roomId, botId)) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future.delayed(Duration(milliseconds: typingPollMs));
    }

    // Small grace period for the message to arrive in DB
    await Future.delayed(Duration(seconds: typingGraceSec));

    // Check whether a new human message actually landed
    final fresh = managerOrNull(roomId)?.sortedMessages ?? [];
    final latest = _latestHumanMessage(fresh, botId);
    return latest != null && latest.id != currentMsgId;
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  3. Think delay
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _thinkDelay() async {
    await Future.delayed(Duration(seconds: _randomInRange(thinkDelayRange)));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  4. Auto-leave
  // ═════════════════════════════════════════════════════════════════════════

  void _scheduleAutoLeave(String roomId, BotProfile bot) {
    // Don't reset if a timer is already running
    if (_autoLeaveTimers.containsKey(roomId)) return;

    final minutes = _randomInRange(sessionMinutesRange);
    _autoLeaveTimers[roomId] = Timer(
      Duration(minutes: minutes),
      () => _triggerAutoLeave(roomId, bot),
    );
  }

  /// Leave sequence:
  ///   typing ON → send goodbye → typing OFF → go offline → start cooldown.
  Future<void> _triggerAutoLeave(String roomId, BotProfile bot) async {
    if (_leaveInProgress.contains(roomId)) return;
    _leaveInProgress.add(roomId);

    try {
      final goodbye = leaveMessages[_rng.nextInt(leaveMessages.length)];

      // Simulate typing the goodbye
      await _setBotTyping(roomId, bot.id, true);
      await Future.delayed(Duration(seconds: _randomInRange((1, 3))));
      await _setBotTyping(roomId, bot.id, false);

      // Send the goodbye
      final msg = TextMessage.create(goodbye, roomId: roomId, senderId: bot.id);
      if (!msg.isEmpty) await createMessageByBot(msg);

      // Go offline
      await _setBotOnline(bot.id, false);

      // Snapshot the latest human message ID so that when the bot returns
      // after cooldown, it won't re-reply to anything sent before it left.
      final currentMessages = managerOrNull(roomId)?.sortedMessages ?? [];
      final latestHuman = _latestHumanMessage(currentMessages, bot.id);
      if (latestHuman != null) {
        _repliedMessageId[roomId] = latestHuman.id;
      }

      // Reset the init guard so bot goes through the snapshot logic again
      // on the next session entry (after cooldown).
      _initializedRooms.remove(roomId);

      // Record cooldown-end time
      _cooldownEndsAt[roomId] = DateTime.now().add(
        Duration(minutes: _randomInRange(cooldownMinutesRange)),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'BotResponseMixin._triggerAutoLeave',
        context: {'roomId': roomId, 'botId': bot.id},
      );
    } finally {
      _leaveInProgress.remove(roomId);
      _autoLeaveTimers[roomId]?.cancel();
      _autoLeaveTimers.remove(roomId);
    }
  }

  bool _isOnCooldown(String roomId) {
    final until = _cooldownEndsAt[roomId];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _cooldownEndsAt.remove(roomId);
    return false;
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Delegate wrappers (reuse existing delegates — no abstract methods)
  // ═════════════════════════════════════════════════════════════════════════

  /// Toggle the bot's typing indicator via [typingDelegate].
  Future<void> _setBotTyping(String roomId, String botId, bool typing) async {
    try {
      if (typing) {
        await typingDelegate.start(roomId, botId);
      } else {
        await typingDelegate.end(botId);
      }
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'BotResponseMixin._setBotTyping',
        context: {'roomId': roomId, 'botId': botId, 'typing': typing},
      );
    }
  }

  /// Check if any human participant in [roomId] is currently typing.
  /// Uses [typingFor] from RoomManagerBase which reads [mappedTypings].
  bool _isHumanTyping(String roomId, String botId) {
    final r = room(roomId);
    for (final uid in r.participants) {
      if (uid == botId) continue;
      final t = typingFor(uid);
      if (!t.isEmpty && t.roomId == roomId) return true;
    }
    return false;
  }

  /// Set the bot's online / offline status via [statusDelegate].
  Future<void> _setBotOnline(String botId, bool online) async {
    try {
      final value = n.normalize({
        StatusKeys.i.isOnline: online ? true : ChatValueDelete(),
        StatusKeys.i.lastSeen: ChatValueTimestamp(),
      }, n.status);
      if (online) {
        await statusDelegate.online(botId, value);
      } else {
        await statusDelegate.offline(botId, value);
      }
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'BotResponseMixin._setBotOnline',
        context: {'botId': botId, 'online': online},
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Profile resolution
  // ═════════════════════════════════════════════════════════════════════════

  BotProfile? _resolveBotProfile(Room room) {
    for (final uid in room.participants) {
      final p = profileFor(uid);
      if (p is BotProfile && !p.isEmpty) return p;
    }
    return null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Latest human message
  // ═════════════════════════════════════════════════════════════════════════

  Message? _latestHumanMessage(List<Message> messages, String botId) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg.isEmpty) continue;
      if (msg.senderId == botId) continue;
      if (msg.type == MessageType.custom) continue;
      if (msg.isDeleted || msg.shouldRemove) continue;
      return msg;
    }
    return null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Request builder
  // ═════════════════════════════════════════════════════════════════════════

  ChatAiRequest? _buildRequest(
    BotProfile botProfile,
    List<Message> messages,
    Message incoming,
  ) {
    Message? replyMessage;
    if (incoming.replyId.isNotEmpty) {
      final found = incoming.replyMessage;
      if (!found.isEmpty && !found.isDeleted && !found.shouldRemove) {
        replyMessage = found;
      }
    }

    final conversations =
        messages
            .where((m) => m.id != incoming.id && !m.isEmpty && !m.shouldRemove)
            .toList();

    return switch (incoming) {
      TextMessage m => ChatAiTextReplyRequest(
        profile: botProfile,
        conversations: conversations,
        replyMessage: replyMessage,
        text: m.text,
      ),
      AudioMessage m => ChatAiAudioReplyRequest(
        profile: botProfile,
        conversations: conversations,
        replyMessage: replyMessage,
        url: m.url,
        caption: null,
      ),
      ImageMessage m => ChatAiImageReplyRequest(
        profile: botProfile,
        conversations: conversations,
        replyMessage: replyMessage,
        urls: m.urls,
        caption: m.caption,
      ),
      VideoMessage m => ChatAiVideoReplyRequest(
        profile: botProfile,
        conversations: conversations,
        replyMessage: replyMessage,
        url: m.url,
        caption: m.caption,
      ),
      LinkMessage m => ChatAiLinkReplyRequest(
        profile: botProfile,
        conversations: conversations,
        replyMessage: replyMessage,
        link: m.link,
      ),
      _ => null,
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Send reply
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _markSeenByBot(String roomId, String botId, Message msg) async {
    try {
      final isLastMsg = room(roomId).lastMessageId == msg.id;
      await updateMessage(
        roomId,
        msg.id,
        {'${MessageKeys.i.statuses}.$botId': MessageStatus.seen.name},
        roomValues: {
          if (isLastMsg)
            '${RoomKeys.i.lastMessageStatuses}.$botId': MessageStatus.seen.name,
        },
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'BotResponseMixin._markSeenByBot',
        context: {'roomId': roomId, 'botId': botId, 'msgId': msg.id},
      );
    }
  }

  Future<void> _sendBotReply(
    String roomId,
    String botId,
    String replyText,
  ) async {
    final msg = TextMessage.create(replyText, roomId: roomId, senderId: botId);
    if (msg.isEmpty) return;
    await createMessageByBot(msg);
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Helpers
  // ═════════════════════════════════════════════════════════════════════════

  int _randomInRange((int, int) range) {
    final (min, max) = range;
    return min + _rng.nextInt(max - min + 1);
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Cleanup — call from RoomManager._teardown()
  // ═════════════════════════════════════════════════════════════════════════

  void disposeBotMixin() {
    for (final timer in _autoLeaveTimers.values) {
      timer.cancel();
    }
    _autoLeaveTimers.clear();
    _repliedMessageId.clear();
    _inFlight.clear();
    _leaveInProgress.clear();
    _cooldownEndsAt.clear();
    _initializedRooms.clear();
  }
}
