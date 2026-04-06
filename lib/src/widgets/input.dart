import 'dart:async';

import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../models/message.dart';
import '../utils/chat_ui.dart';

class ChatInput extends StatefulWidget {
  final ChatManager manager;
  final TextEditingController? controller;

  const ChatInput({
    super.key,
    required this.manager,
    this.controller,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with WidgetsBindingObserver {
  late TextEditingController _controller;
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatUiConfigs get i => RoomManager.i.uiConfigs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onTextChanged);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_isTyping) {
        _isTyping = false;
        widget.manager.typing(false);
      }
    }
  }

  void _onTextChanged() {
    if (_controller.text.isEmpty) {
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        widget.manager.typing(false);
      }
      return;
    }

    if (!_isTyping) {
      _isTyping = true;
      widget.manager.typing(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.manager.typing(false);
      }
    });
  }

  void _sendText({
    String? text,
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) {
    text ??= _controller.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      widget.manager.typing(false);
    }
    widget.manager.send(
      TextMessage.create(text, extra: extra),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
    _controller.clear();
  }

  Future<void> _sendImages(
    List<String> paths, {
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) async {
    if (paths.isEmpty) return;
    final text = _controller.text.trim();
    widget.manager.send(
      ImageMessage.create(
        paths,
        caption: text.isEmpty ? null : text,
        extra: extra,
      ),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
    if (text.isNotEmpty) _controller.clear();
  }

  Future<void> _sendCapturedImage(
    String path, {
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) async {
    if (path.isEmpty) return;
    final text = _controller.text.trim();
    widget.manager.send(
      ImageMessage.create(
        [path],
        caption: text.isEmpty ? null : text,
        extra: extra,
      ),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
    if (text.isNotEmpty) _controller.clear();
  }

  Future<void> _sendVoice(
    String path,
    int duration,
    List<double> waveform, {
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) async {
    widget.manager.send(
      AudioMessage.create(
        path,
        duration,
        waveform,
        extra: extra,
      ),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
  }

  Future<void> _sendCapturedVideo(
    String path, {
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) async {
    if (i.onVideoDuration == null) return;
    if (i.onVideoThumbnail == null) return;
    if (path.isEmpty) return;
    final duration = await i.onVideoDuration!(context, path);
    if (duration <= 0 || !mounted) return;
    final thumbnail = await i.onVideoThumbnail!(context, path);
    if (thumbnail == null || thumbnail.isEmpty) return;
    final text = _controller.text.trim();
    widget.manager.send(
      VideoMessage.create(
        path,
        thumbnail,
        duration,
        caption: text.isEmpty ? null : text,
        extra: extra,
      ),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
    if (text.isNotEmpty) _controller.clear();
  }

  Future<void> _sendVideo(
    String path, {
    Map<String, dynamic>? extra,
    VerifyToSendMessage? verifyToSend,
    VerifyToSendNotification? verifyToSendNotification,
    OnDeniedToSendMessage? onDeniedToSend,
    OnDeniedToSendNotification? onDeniedToSendNotification,
  }) async {
    if (i.onVideoDuration == null) return;
    if (i.onVideoThumbnail == null) return;
    if (path.isEmpty) return;
    final duration = await i.onVideoDuration!(context, path);
    if (duration <= 0 || !mounted) return;
    final thumbnail = await i.onVideoThumbnail!(context, path);
    if (thumbnail == null || thumbnail.isEmpty) return;
    final text = _controller.text.trim();
    widget.manager.send(
      VideoMessage.create(
        path,
        thumbnail,
        duration,
        caption: text.isEmpty ? null : text,
        extra: extra,
      ),
      verifyToSend: verifyToSend,
      verifyToSendNotification: verifyToSendNotification,
      onDeniedToSend: onDeniedToSend,
      onDeniedToSendNotification: onDeniedToSendNotification,
    );
    if (text.isNotEmpty) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (i.inputBuilder == null) {
      return const SizedBox.shrink();
    }
    return i.inputBuilder!(
      context,
      ChatInputConfigs(
        manager: widget.manager,
        editor: _controller,
        onCaptureImage: _sendCapturedImage,
        onSendText: _sendText,
        onSendVoice: _sendVoice,
        onSendImages: _sendImages,
        onCaptureVideo: _sendCapturedVideo,
        onSendVideo: _sendVideo,
      ),
    );
  }
}
