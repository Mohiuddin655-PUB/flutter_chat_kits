# Changelog

All notable changes to this project will be documented in this file.

## [1.0.16] - 2026-03-31

## [1.0.15] - 2026-03-013

- Improve input bar callbacks to send also extra

## [1.0.14] - 2026-03-013

- Improve input bar and remove all media pickers from ChatUi util

## [1.0.13] - 2026-03-011

- Improve send message text

## [1.0.12] - 2026-03-06

- Delete message permanently support

## [1.0.11] - 2026-03-06

- Improve chat manager
- Support message resolver

## [1.0.10] - 2026-02-29

## [1.0.9] - 2026-02-29

- Enhanced message create function

## [1.0.8] - 2026-02-28

- CustomMessage support
- AudioMessage waveform support

## [1.0.7] - 2026-02-27

- Fix minor bugs
- Add some useful methods to manage room easily

## [1.0.6] - 2026-02-26

- Add sayHello to send message initially without room

## [1.0.5] - 2026-02-26

- Delete room with related metadata

## [1.0.4] - 2026-02-25

- Add Block and Pin feature in room

## [1.0.3] - 2026-02-25

- Enhance ChatManager

## [1.0.2] - 2026-02-11

- Enhance room and profile

## [1.0.1] - 2026-02-11

- Control profile, room and messages with extra

## [1.0.0] - 2026-02-11

### 🎉 Initial Release

This is the first public release of Flutter Chat Kits - a comprehensive, production-ready Flutter
package for building real-time chat applications.

### ✨ Features

#### Core Functionality

- **Real-time Messaging** - Send and receive messages instantly with stream-based architecture
- **Direct & Group Chats** - Support for both one-on-one and group conversations
- **Multiple Message Types**:
    - Text messages
    - Image messages with thumbnail support
    - Video messages with duration and thumbnail
    - Audio messages with duration tracking
    - Link messages with preview support

#### Message Actions

- Edit messages with edit history
- Delete messages (for everyone or just for you)
- Reply to messages with context
- Forward messages to multiple chats
- React with emojis
- Pin/unpin important messages
- Remove messages from view

#### Status & Indicators

- Real-time message status tracking (sending, sent, delivered, seen)
- Typing indicators with multi-user support
- Online/offline status tracking
- Read receipts and delivery confirmations
- Unseen message count per conversation

#### Room Management

- Create and delete rooms
- Mute/unmute conversations
- Block/unblock users
- Leave group conversations
- Track active rooms
- Custom room metadata support

#### UI Components

Pre-built, customizable widgets:

- `ChatBoard` - Main message display with auto-scroll
- `ChatInbox` - Conversation list item with preview
- `ChatBody` - Complete chat screen layout
- `ChatMessages` - Message list renderer
- `ChatInput` - Message input field with actions
- `ChatAppBar` - Custom app bar with profile and status
- Scroll-to-bottom button with unseen count
- Visibility detection for auto-seen marking

#### Architecture & Patterns

- **Delegate Pattern** - Implement your own backend (Firebase, REST API, WebSocket, etc.)
- **State Management** - Built-in managers using `ValueNotifier` and `ChangeNotifier`
- **Type-Safe Models** - Strongly typed message and room models with Equatable support
- **Modular Design** - Use only what you need
- **Optimistic Updates** - Instant UI feedback with automatic rollback on failures
- **Lifecycle Management** - Proper connect/disconnect handling
- **Background/Foreground** - Smart state handling for app lifecycle

#### Delegates

- `ChatMessageDelegate` - Message CRUD and streaming
- `ChatRoomDelegate` - Room CRUD and streaming
- `ChatProfileDelegate` - User profile management
- `ChatStatusDelegate` - Online/offline status
- `ChatTypingDelegate` - Typing indicators
- `ChatNotificationDelegate` - Push notifications
- `ChatNormalizer` - Data normalization and formatting

#### Developer Experience

- Comprehensive documentation and examples
- Type-safe APIs throughout
- Clear error handling patterns
- Extensive customization options
- Performance optimized for large chat histories
- Memory leak prevention
- Reactive programming model

### 🎯 Key Highlights

- ✅ **Backend Agnostic** - Works with any backend (Firebase, REST, WebSocket, custom)
- ✅ **Production Ready** - Battle-tested patterns and comprehensive error handling
- ✅ **Fully Customizable** - Override any UI component to match your design system
- ✅ **Type Safe** - Strong typing with Dart's type system
- ✅ **Reactive** - Built on Flutter's reactive programming model
- ✅ **Modular** - Import and use only what you need
- ✅ **Performance** - Optimized rendering for thousands of messages
- ✅ **Offline Ready** - Designed for offline-first architectures

### 📦 Package Structure

```
lib/
├── src/
│   ├── delegates/     # Backend integration interfaces
│   ├── managers/      # State management
│   ├── models/        # Data models
│   ├── utils/         # Utilities and helpers
│   └── widgets/       # UI components
└── flutter_chat_kits.dart  # Main export file
```

### 🚀 Getting Started

See the [README.md](README.md) for installation instructions and quick start guide

---

## 🗺️ Future Roadmap

We're continuously improving Flutter Chat Kits. Here's what's planned:

### Version 1.1.0 (Coming Soon)

- Voice message recording UI
- Message search functionality
- Advanced filtering and sorting options
- Message export functionality
- Archive conversations
- Starred/favorited messages
- Message threading

### Version 1.2.0

- End-to-end encryption support
- Message scheduling
- Polls and surveys in chat
- Location sharing
- Contact sharing
- Custom message types API
- Rich text formatting

### Version 2.0.0

- Video/audio calling integration
- Screen sharing capabilities
- Live location sharing
- Stories/status updates
- Channels and broadcast lists
- Advanced admin controls for groups
- Message reactions with custom emojis
- Chat themes and customization presets

---

## 🤝 Contributing

We welcome contributions from the community! Whether it's:

- 🐛 Bug reports
- 💡 Feature requests
- 📝 Documentation improvements
- 🔧 Code contributions

Please feel free to open an issue or submit a pull request.

---

## 📞 Support

Need help? We're here for you:

- 📖 **Documentation**: Check the [README.md](README.md) for comprehensive guides
- 🐛 **Issues**: Report bugs or request features on GitHub Issues
- 💬 **Discussions**: Join community discussions on GitHub Discussions
- ⭐ **Star us**: If you find this package helpful, please star the repository!

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Flutter Chat Kits** - Built with ❤️ for the Flutter community