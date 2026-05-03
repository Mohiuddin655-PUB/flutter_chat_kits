import '../models/message.dart' show Message;
import '../models/profile.dart' show BotProfile;

class ChatAiRequest {
  final BotProfile profile;

  const ChatAiRequest({required this.profile});
}

class ChatAiReplyRequest extends ChatAiRequest {
  final List<Message> conversations;
  final Message? replyMessage;

  const ChatAiReplyRequest({
    required super.profile,
    required this.conversations,
    required this.replyMessage,
  });
}

class ChatAiAudioReplyRequest extends ChatAiReplyRequest {
  final String url;
  final String? caption;

  const ChatAiAudioReplyRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
    required this.url,
    required this.caption,
  });
}

class ChatAiImageReplyRequest extends ChatAiReplyRequest {
  final List<String> urls;
  final String? caption;

  const ChatAiImageReplyRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
    required this.urls,
    required this.caption,
  });
}

class ChatAiLinkReplyRequest extends ChatAiReplyRequest {
  final String link;

  const ChatAiLinkReplyRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
    required this.link,
  });
}

class ChatAiTextReplyRequest extends ChatAiReplyRequest {
  final String text;

  const ChatAiTextReplyRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
    required this.text,
  });
}

class ChatAiVideoReplyRequest extends ChatAiReplyRequest {
  final String url;
  final String? caption;

  const ChatAiVideoReplyRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
    required this.url,
    required this.caption,
  });
}

class ChatAiFirstMessageRequest extends ChatAiRequest {
  const ChatAiFirstMessageRequest({required super.profile});
}

class ChatAiLeaveMessageRequest extends ChatAiRequest {
  const ChatAiLeaveMessageRequest({required super.profile});
}

class ChatAiComeBackMessageRequest extends ChatAiReplyRequest {
  const ChatAiComeBackMessageRequest({
    required super.profile,
    required super.conversations,
    required super.replyMessage,
  });
}

abstract class ChatAiDelegate {
  Future<String?> generate(ChatAiRequest request);
}
