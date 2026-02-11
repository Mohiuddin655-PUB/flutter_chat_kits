# Flutter Chat Kits

A comprehensive, production-ready Flutter package for building real-time chat applications with support for direct messaging and group chats.

## Features

### Core Functionality
- 🔥 **Real-time Messaging** - Send and receive messages instantly
- 👥 **Group & Direct Chats** - Support for both one-on-one and group conversations
- 📎 **Rich Media Support** - Text, images, videos, audio, and links
- ✏️ **Message Actions**
    - Edit messages
    - Delete messages (for everyone or just for you)
    - Reply to messages
    - Forward messages
    - React with emojis
    - Pin important messages
- 📊 **Message Status Tracking** - Sending, sent, delivered, and seen indicators
- ⌨️ **Typing Indicators** - Real-time typing status
- 🔔 **Notifications** - Customizable notification system
- 🚫 **Room Management** - Mute, block, leave, and delete conversations
- 👀 **Read Receipts** - Track message delivery and read status
- 📌 **Unseen Message Count** - Keep track of unread messages per chat

### UI Components
Pre-built, customizable widgets:
- `ChatBoard` - Main chat message display with scroll-to-bottom functionality
- `ChatInbox` - Conversation list item with preview
- `ChatBody` - Complete chat screen layout
- `ChatMessages` - Message list renderer
- `ChatInput` - Message input field with actions
- `ChatAppBar` - Custom app bar with profile and status

### Architecture
- **Delegate Pattern** - Implement your own backend (Firebase, REST API, WebSocket, etc.)
- **State Management** - Built-in managers using `ValueNotifier` and `ChangeNotifier`
- **Type-Safe Models** - Strongly typed message and room models with Equatable support
- **Modular Design** - Use only what you need

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_chat_kits: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Implement Delegates

The package uses a delegate pattern. Implement the required delegates to connect to your backend:

```dart
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

// Message operations
class MyMessageDelegate implements ChatMessageDelegate {
  @override
  Future<void> create(String roomId, String msgId, Map<String, dynamic> value) async {
    // Implement message creation in your backend
  }

  @override
  Future<void> update(String roomId, String id, Map<String, dynamic> value) async {
    // Implement message update
  }

  @override
  Future<void> delete(String roomId, String id) async {
    // Implement message deletion
  }

  @override
  Stream<List<Message>> stream(String roomId) {
    // Return a stream of messages for a room
  }

  @override
  Future<String> upload(MessageUploadData data) async {
    // Upload media files and return URL
  }

  // Implement other methods...
}

// Room operations
class MyRoomDelegate implements ChatRoomDelegate {
  @override
  Future<void> create(String roomId, Map<String, dynamic> value) async {
    // Implement room creation
  }

  @override
  Future<Room> get(String roomId) async {
    // Fetch room data
  }

  @override
  Stream<List<Room>> stream(String uid) {
    // Return stream of user's rooms
  }

  // Implement other methods...
}

// Profile, Status, Typing, Notification, and Normalizer delegates...
```

### 2. Initialize RoomManager

```dart
void main() {
  // Initialize with your delegates
  RoomManager.initialize(
    uid: 'current_user_id',
    messageDelegate: MyMessageDelegate(),
    roomDelegate: MyRoomDelegate(),
    profileDelegate: MyProfileDelegate(),
    statusDelegate: MyStatusDelegate(),
    typingDelegate: MyTypingDelegate(),
    notificationDelegate: MyNotificationDelegate(),
    normalizer: MyNormalizer(),
    uiConfigs: ChatUIConfigs(
      // Customize UI builders
      directInboxBuilder: (context, room, profile, status, typing) {
        // Return custom inbox tile widget
      },
      // Add other UI builders...
    ),
  );

  runApp(MyApp());
}
```

### 3. Display Chat List

```dart
class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: ListenableBuilder(
        listenable: RoomManager.i,
        builder: (context, child) {
          final rooms = RoomManager.i.rooms;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return ChatInbox(room: rooms[index]);
            },
          );
        },
      ),
    );
  }
}
```

### 4. Display Chat Screen

```dart
class ChatScreen extends StatefulWidget {
  final Room room;
  
  const ChatScreen({required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    ChatManager.i.connect(widget.room);
  }

  @override
  void dispose() {
    ChatManager.i.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(),
      body: Column(
        children: [
          Expanded(child: ChatBoard()),
          ChatInput(),
        ],
      ),
    );
  }
}
```

### 5. Send Messages

```dart
// Send text message
void sendTextMessage(String text) {
  final message = TextMessage.create(
    roomId: ChatManager.i.roomId,
    senderId: RoomManager.i.me,
    text: text,
  );
  ChatManager.i.send(message);
}

// Send image message
void sendImageMessage(String imagePath) {
  final message = ImageMessage.create(
    roomId: ChatManager.i.roomId,
    senderId: RoomManager.i.me,
    url: imagePath,
  );
  ChatManager.i.send(message);
}

// Reply to a message
void replyToMessage(Message originalMessage, String replyText) {
  ChatManager.i.reply(originalMessage);
  final message = TextMessage.create(
    roomId: ChatManager.i.roomId,
    senderId: RoomManager.i.me,
    text: replyText,
    replyId: originalMessage.id,
  );
  ChatManager.i.send(message);
}
```

## Core Concepts

### Message Types

The package supports multiple message types:

- `TextMessage` - Plain text messages
- `ImageMessage` - Image messages with thumbnail support
- `VideoMessage` - Video messages with thumbnail and duration
- `AudioMessage` - Audio messages with duration
- `LinkMessage` - Link messages with preview

### Message Status

Messages go through different states:
- `sending` - Being uploaded/sent
- `sent` - Successfully sent to server
- `delivered` - Delivered to recipient's device
- `seen` - Viewed by recipient
- `failed` - Failed to send

### Room Types

- `DirectRoom` - One-on-one conversation
- `GroupRoom` - Group conversation with multiple participants

### Managers

#### RoomManager
Global singleton managing all rooms and their state:
- `RoomManager.i.rooms` - List of all rooms
- `RoomManager.i.room(roomId)` - Get specific room
- `RoomManager.i.createRoom(room)` - Create new room
- `RoomManager.i.markAsTyping(roomId, status)` - Update typing status
- `RoomManager.i.markAsActive(roomId)` - Set active room

#### ChatManager
Manages the currently active chat:
- `ChatManager.i.messages` - List of messages
- `ChatManager.i.unseens` - Unread messages
- `ChatManager.i.pins` - Pinned messages
- `ChatManager.i.connect(room)` - Open a chat
- `ChatManager.i.disconnect()` - Close current chat
- `ChatManager.i.send(message)` - Send message
- `ChatManager.i.edit(message, content)` - Edit message
- `ChatManager.i.delete(message)` - Delete message
- `ChatManager.i.react(message, emoji)` - Add reaction
- `ChatManager.i.pin(message)` - Pin message
- `ChatManager.i.forward(roomIds, message)` - Forward message

## Customization

### UI Builders

Customize the appearance by providing your own builders:

```dart
ChatUIConfigs(
  directInboxBuilder: (context, room, profile, status, typing) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profile?.photo ?? ''),
      ),
      title: Text(profile?.name ?? 'Unknown'),
      subtitle: Text(room.formattedLastMessage()),
      trailing: room.unseenCount > 0
          ? CircleAvatar(
              radius: 12,
              child: Text('${room.unseenCount}'),
            )
          : null,
    );
  },
  messageBuilder: (context, message, previous, next) {
    // Custom message bubble
  },
  inputBuilder: (context, onSend, replyMessage) {
    // Custom input field
  },
  // ... more builders
)
```

### Message Actions

Handle message actions with callbacks:

```dart
// React to message
ChatManager.i.react(message, '👍');

// Edit message
ChatManager.i.edit(message, 'Updated text');

// Delete message
ChatManager.i.delete(message);

// Pin message
ChatManager.i.pin(message);

// Forward message
ChatManager.i.forward(['room1', 'room2'], message);
```

## Advanced Features

### Typing Indicators

```dart
// Start typing
ChatManager.i.typing(true);

// Stop typing
ChatManager.i.typing(false);

// Listen to others typing
ValueListenableBuilder(
  valueListenable: ChatManager.i.typings,
  builder: (context, typings, child) {
    if (typings.isEmpty) return SizedBox.shrink();
    return Text('${typings.first.name} is typing...');
  },
)
```

### Online Status

```dart
ValueListenableBuilder(
  valueListenable: ChatManager.i.status,
  builder: (context, status, child) {
    return Text(status?.isOnline ?? false ? 'Online' : 'Offline');
  },
)
```

### Visibility Detection

Automatically mark messages as seen when visible:

```dart
@override
Widget build(BuildContext context) {
  return RoomManager.i.uiConfigs.visibilityDetectorBuilder(
    context,
    widget.message.id,
    MessageBubble(message: widget.message),
    (info) {
      if (info.visibleFraction > 0.5) {
        ChatManager.i.seen(widget.message);
      }
    },
  );
}
```

## Models

### Message Model

```dart
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final MessageType type;
  final Map<String, MessageStatus> statuses;
  final ChatValueTimestamp createdAt;
  final ChatValueTimestamp updatedAt;
  
  // Optional fields
  final String replyId;
  final Map<String, String> reactions;
  final Map<String, bool> pins;
  final bool isDeleted;
  final bool isEdited;
  final bool isForwarded;
  
  // Helper methods
  bool get isSentByMe;
  bool get isSending;
  bool get isSeenByMe;
  bool get isPinned;
  bool get isEditable;
}
```

### Room Model

```dart
class Room {
  final String id;
  final bool isGroup;
  final Set<String> participants;
  final String? lastMessage;
  final String lastMessageId;
  final int unseenCount;
  final ChatValueTimestamp updatedAt;
  
  // Helper methods
  bool get isEmpty;
  bool get isMutedByMe;
  bool get isBlockByMe;
  bool get isDisabledToSend;
  String formattedLastMessage();
}
```

## Delegate Reference

### Required Delegates

1. **ChatMessageDelegate** - Message CRUD operations
2. **ChatRoomDelegate** - Room CRUD operations
3. **ChatProfileDelegate** - User profile data
4. **ChatStatusDelegate** - Online/offline status
5. **ChatTypingDelegate** - Typing indicators
6. **ChatNotificationDelegate** - Push notifications
7. **ChatNormalizer** - Data normalization

## Best Practices

1. **Implement Proper Error Handling** - Handle network failures gracefully
2. **Use Optimistic Updates** - Update UI immediately, revert on failure
3. **Clean Up Resources** - Always call `disconnect()` when leaving chat
4. **Lazy Load Messages** - Implement pagination in your delegate
5. **Cache Profiles** - Avoid repeated profile fetches
6. **Debounce Typing** - Don't send typing status on every keystroke
7. **Test Offline Mode** - Ensure graceful degradation without connectivity

## Example Implementation

Check the example folder for a complete Firebase implementation:
- Firebase Firestore for message and room storage
- Firebase Storage for media uploads
- Firebase Cloud Messaging for notifications
- Real-time listeners for live updates

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or questions:
- Open an issue on GitHub
- Check the documentation
- Review example implementations

## Changelog

See CHANGELOG.md for version history and updates.

---

Built with ❤️ for the Flutter community