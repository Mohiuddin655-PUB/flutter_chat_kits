import '../models/message.dart' show MessageKeys;
import '../models/profile.dart' show BotProfileKeys, UserProfileKeys;
import '../models/room.dart' show RoomKeys;
import '../models/status.dart' show StatusKeys;
import '../models/typing.dart' show TypingKeys;

class ChatModelConfigs {
  final MessageKeys messageKeys;
  final BotProfileKeys botProfileKeys;
  final UserProfileKeys userProfileKeys;
  final RoomKeys roomKeys;
  final StatusKeys statusKeys;
  final TypingKeys typingKeys;

  const ChatModelConfigs({
    this.messageKeys = const MessageKeys(),
    this.botProfileKeys = const BotProfileKeys(),
    this.userProfileKeys = const UserProfileKeys(),
    this.roomKeys = const RoomKeys(),
    this.statusKeys = const StatusKeys(),
    this.typingKeys = const TypingKeys(),
  });
}
