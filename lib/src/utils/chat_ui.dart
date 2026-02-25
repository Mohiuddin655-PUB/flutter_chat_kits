import 'package:flutter/widgets.dart';

import '../managers/chat.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/status.dart';
import '../models/typing.dart';

typedef ChatAppbarBuilder<T extends Typing> = Widget Function(
  BuildContext context,
  ChatAppbarConfigs,
);
typedef ChatVisibilityBuilder = Widget Function(
  BuildContext context,
  String id,
  Widget child,
  void Function(ChatVisibilityInfo info) callback,
);
typedef ChatInboxBuilder<R extends Room, T> = Widget Function(
  BuildContext context,
  R room,
  Profile profile,
  Status status,
  T typing,
);
typedef ChatInputBuilder<T extends Message> = Widget Function(
    BuildContext context, ChatInputConfigs configs);
typedef ChatReplayMessagePreviewBuilder<T extends Message> = Widget Function(
    BuildContext context, T message, VoidCallback onCancel);
typedef ChatScrollDownButtonBuilder<T extends Message> = Widget Function(
    BuildContext context, List<T> unseen, VoidCallback onGo);
typedef ChatMessageBuilder<T extends Message> = Widget Function(
    BuildContext context, ChatManager manager, T message);
typedef ChatTypingBuilder<T extends Typing> = Widget Function(
    BuildContext context, List<T> typings);
typedef ChatProfileBuilder<T extends Profile> = Widget Function(
    BuildContext context, T profile, Status status);
typedef ChatGroupDateBuilder = Widget Function(
    BuildContext context, DateTime date);
typedef ChattingPageCallback<T extends Object?> = Future<T?> Function(
    BuildContext context, ChatManager manager);
typedef ChatContentPickerCallback = Future<String?> Function(
    BuildContext context);
typedef ChatContentsPickerCallback = Future<List<String>> Function(
    BuildContext context);
typedef ChatVideoDurationCallback = Future<int> Function(
    BuildContext context, String path);
typedef ChatVideoThumbnailCallback = Future<String?> Function(
    BuildContext context, String path);

class ChatVisibilityInfo {
  final Key? key;
  final Size size;
  final double visibleFraction;

  const ChatVisibilityInfo({
    required this.key,
    this.size = Size.zero,
    this.visibleFraction = 0,
  });
}

class ChatAppbarConfigs {
  final ChatManager manager;
  final Profile profile;
  final Status status;
  final List<Typing> typings;

  bool get isTyping => typings.isNotEmpty;

  const ChatAppbarConfigs({
    required this.manager,
    required this.profile,
    required this.status,
    required this.typings,
  });
}

class ChatInputConfigs {
  final ChatManager manager;
  final TextEditingController editor;
  final VoidCallback onCaptureImage;
  final VoidCallback onSendText;
  final void Function(String path, int duration) onSendVoice;
  final VoidCallback onSendImages;
  final VoidCallback onCaptureVideo;
  final VoidCallback onSendVideo;

  const ChatInputConfigs({
    required this.manager,
    required this.editor,
    required this.onCaptureImage,
    required this.onSendText,
    required this.onSendVoice,
    required this.onSendImages,
    required this.onCaptureVideo,
    required this.onSendVideo,
  });
}

class ChatUiConfigs {
  final ChatAppbarBuilder<Typing>? chatAppbarBuilder;
  final ChatInboxBuilder<DirectRoom, Typing?>? directInboxBuilder;
  final ChatInboxBuilder<GroupRoom, List<Typing>>? groupInboxBuilder;
  final ChatMessageBuilder<AudioMessage>? audioBuilder;
  final ChatMessageBuilder<Message>? deletedBuilder;
  final ChatMessageBuilder<ImageMessage>? imageBuilder;
  final ChatMessageBuilder<LinkMessage>? linkBuilder;
  final ChatMessageBuilder<TextMessage>? textBuilder;
  final ChatMessageBuilder<VideoMessage>? videoBuilder;
  final ChatGroupDateBuilder? groupDateBuilder;
  final ChatProfileBuilder<Profile>? profileBuilder;
  final ChatTypingBuilder<Typing>? typingBuilder;
  final WidgetBuilder? blockedInputBuilder;
  final WidgetBuilder? leaveFromRoomBuilder;
  final ChatReplayMessagePreviewBuilder<Message>? replayMessageReplyBuilder;
  final ChatInputBuilder<Message>? inputBuilder;
  final ChatScrollDownButtonBuilder<Message>? scrollDownButtonBuilder;
  final WidgetBuilder? noMessagesBuilder;
  final ChatVisibilityBuilder? visibilityDetectorBuilder;
  final ChattingPageCallback onChatStart;
  final ChatContentPickerCallback? onImageCapture;
  final ChatContentPickerCallback? onImagePicker;
  final ChatContentsPickerCallback? onMutiImagePicker;
  final ChatContentPickerCallback? onVideoCapture;
  final ChatContentPickerCallback? onVideoPicker;
  final ChatVideoDurationCallback? onVideoDuration;
  final ChatVideoThumbnailCallback? onVideoThumbnail;

  const ChatUiConfigs({
    required this.onChatStart,
    this.chatAppbarBuilder,
    this.directInboxBuilder,
    this.groupInboxBuilder,
    this.audioBuilder,
    this.deletedBuilder,
    this.imageBuilder,
    this.linkBuilder,
    this.textBuilder,
    this.videoBuilder,
    this.groupDateBuilder,
    this.noMessagesBuilder,
    this.visibilityDetectorBuilder,
    this.profileBuilder,
    this.typingBuilder,
    this.replayMessageReplyBuilder,
    this.inputBuilder,
    this.scrollDownButtonBuilder,
    this.onImageCapture,
    this.onImagePicker,
    this.onMutiImagePicker,
    this.onVideoCapture,
    this.onVideoPicker,
    this.onVideoDuration,
    this.onVideoThumbnail,
    this.blockedInputBuilder,
    this.leaveFromRoomBuilder,
  });
}
