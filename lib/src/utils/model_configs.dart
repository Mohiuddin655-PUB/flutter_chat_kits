import '../models/message.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/status.dart';
import '../models/typing.dart';

class ChatModelConfigs {
  final MessageKeys messageKeys;
  final ProfileKeys profileKeys;
  final RoomKeys roomKeys;
  final StatusKeys statusKeys;
  final TypingKeys typingKeys;

  const ChatModelConfigs({
    this.messageKeys = const MessageKeys(),
    this.profileKeys = const ProfileKeys(),
    this.roomKeys = const RoomKeys(),
    this.statusKeys = const StatusKeys(),
    this.typingKeys = const TypingKeys(),
  });
}
