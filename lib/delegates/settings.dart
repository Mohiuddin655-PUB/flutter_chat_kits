import '../models/profile.dart';
import '../models/room.dart';

typedef NotificationSender = Future<Profile?> Function();
typedef VerifyToSendNotification = bool Function(Room, UserProfile);
typedef OnDeniedToSendNotification = void Function(Room, UserProfile);

class ChatNotification {
  final String? title;
  final String? body;
  final NotificationSender? sender;
  final VerifyToSendNotification? verify;
  final OnDeniedToSendNotification? onDenied;

  const ChatNotification({
    this.title,
    this.body,
    this.sender,
    this.verify,
    this.onDenied,
  });

  ChatNotification copyWith({
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

class ChatSilentNotification extends ChatNotification {
  const ChatSilentNotification({
    super.title,
    super.body,
    super.sender,
    super.verify,
    super.onDenied,
  });

  @override
  ChatSilentNotification copyWith({
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatSilentNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

class ChatNewRoomNotification extends ChatSilentNotification {
  const ChatNewRoomNotification({
    super.title,
    super.body,
    super.sender,
    super.verify,
    super.onDenied,
  });

  @override
  ChatNewRoomNotification copyWith({
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatNewRoomNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

class ChatNewMessageNotification extends ChatSilentNotification {
  const ChatNewMessageNotification({
    super.title,
    super.body,
    super.sender,
    super.verify,
    super.onDenied,
  });

  @override
  ChatNewMessageNotification copyWith({
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatNewMessageNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

class ChatDeleteMessageNotification extends ChatSilentNotification {
  const ChatDeleteMessageNotification({
    super.title,
    super.body,
    super.sender,
    super.verify,
    super.onDenied,
  });

  @override
  ChatDeleteMessageNotification copyWith({
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatDeleteMessageNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

class ChatCustomNotification extends ChatSilentNotification {
  final String type;

  const ChatCustomNotification({
    required this.type,
    super.title,
    super.body,
    super.sender,
    super.verify,
    super.onDenied,
  });

  @override
  ChatCustomNotification copyWith({
    String? type,
    String? title,
    String? body,
    NotificationSender? sender,
    VerifyToSendNotification? verify,
    OnDeniedToSendNotification? onDenied,
  }) {
    return ChatCustomNotification(
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      verify: verify ?? this.verify,
      onDenied: onDenied ?? this.onDenied,
    );
  }
}

abstract class ChatUserSettingsDelegate {
  Future<bool> isEnabled(String uid, String type);

  Future<bool> isEnabledToSendNewRoomNotification(String uid);

  Future<bool> isEnabledToSendMessageNotification(String uid);

  Future<bool> isEnabledToSendDeleteRoomNotification(String uid);
}
