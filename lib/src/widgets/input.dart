import 'dart:async';

import 'package:flutter/material.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../models/message.dart';
import '../utils/chat_ui.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatUiConfigs get i => RoomManager.i.uiConfigs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_isTyping) {
        _isTyping = false;
        ChatManager.i.typing(false);
      }
    }
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ChatManager.i.typing(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        ChatManager.i.typing(false);
      }
    });
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      ChatManager.i.typing(false);
    }
    ChatManager.i.send(TextMessage.create(text));
    _controller.clear();
  }

  Future<void> _sendImages() async {
    if (i.onMutiImagePicker == null) return;
    final images = await i.onMutiImagePicker!(context);
    if (images.isEmpty) return;
    final text = _controller.text.trim();
    ChatManager.i.send(ImageMessage.create(images, text.isEmpty ? null : text));
  }

  Future<void> _sendCapturedImage() async {
    if (i.onImageCapture == null) return;
    final image = await i.onImageCapture!(context);
    if (image == null) return;
    final text = _controller.text.trim();
    ChatManager.i.send(
      ImageMessage.create([image], text.isEmpty ? null : text),
    );
  }

  Future<void> _sendVoice(String path, int duration) async {
    ChatManager.i.send(AudioMessage.create(path, duration));
  }

  Future<void> _sendCapturedVideo() async {
    if (i.onVideoDuration == null) return;
    if (i.onVideoThumbnail == null) return;
    if (i.onVideoCapture == null) return;
    final video = await i.onVideoCapture!(context);
    if (video == null || !mounted) return;
    final duration = await i.onVideoDuration!(context, video);
    if (duration <= 0 || !mounted) return;
    final thumbnail = await i.onVideoThumbnail!(context, video);
    if (thumbnail == null || thumbnail.isEmpty) return;
    final text = _controller.text.trim();
    ChatManager.i.send(
      VideoMessage.create(
        video,
        thumbnail,
        duration,
        text.isEmpty ? null : text,
      ),
    );
  }

  Future<void> _sendVideo() async {
    if (i.onVideoDuration == null) return;
    if (i.onVideoThumbnail == null) return;
    if (i.onVideoPicker == null) return;
    final video = await i.onVideoPicker!(context);
    if (video == null || !mounted) return;
    final duration = await i.onVideoDuration!(context, video);
    if (duration <= 0 || !mounted) return;
    final thumbnail = await i.onVideoThumbnail!(context, video);
    if (thumbnail == null || thumbnail.isEmpty) return;
    final text = _controller.text.trim();
    ChatManager.i.send(
      VideoMessage.create(
        video,
        thumbnail,
        duration,
        text.isEmpty ? null : text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (i.inputBuilder == null) {
      return SizedBox.shrink();
    }
    return i.inputBuilder!(
      context,
      ChatInputConfigs(
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
