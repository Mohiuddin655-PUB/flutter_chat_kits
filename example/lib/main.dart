import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'auth/user.dart';
import 'firebase_options.dart';
import 'notification.dart';
import 'pages/auth.dart';
import 'pages/chat_page.dart';
import 'pages/inbox_page.dart';
import 'services/message.dart';
import 'services/normalizer.dart';
import 'services/notification.dart';
import 'services/profile.dart';
import 'services/room.dart';
import 'services/status.dart';
import 'services/typing.dart';
import 'widgets/chat_no_messages.dart';
import 'widgets/chat_profile.dart';
import 'widgets/chat_scroll_down_button.dart';
import 'widgets/chat_typing_indicator.dart';
import 'widgets/chatting_appbar.dart';
import 'widgets/chatting_input.dart';
import 'widgets/inbox_direct.dart';
import 'widgets/inbox_group.dart';
import 'widgets/message_audio.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_deleted.dart';
import 'widgets/message_group_date.dart';
import 'widgets/message_image.dart';
import 'widgets/message_link.dart';
import 'widgets/message_text.dart';
import 'widgets/message_video.dart';
import 'widgets/reply_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await InAppNotifications.init();
  RoomManager.init(
    connectivity: Connectivity().onConnectivityChanged.map((e) {
      bool _isConnected(Iterable<ConnectivityResult> results) {
        bool isConnected(ConnectivityResult result) {
          if (result == ConnectivityResult.mobile) return true;
          if (result == ConnectivityResult.wifi) return true;
          if (result == ConnectivityResult.ethernet) return true;
          return false;
        }

        final connected = results.any(isConnected);
        return connected;
      }

      return _isConnected(e);
    }),
    room: ChatRoomService(),
    message: ChatMessageService(),
    status: ChatStatusService(),
    typing: ChatTypingService(),
    profile: ChatProfileService(),
    notification: ChatNotificationService(),
    normalizer: ChatFieldValueNormalizerService(),
    uiConfigs: ChatUiConfigs(
      chatAppbarBuilder: (context, configs) {
        return ChattingAppBar(configs: configs);
      },
      inputBuilder: (context, configs) {
        return ChattingInput(configs: configs);
      },
      directInboxBuilder: (context, room, profile, status, typing) {
        return ChatInboxDirect(
          profile: profile,
          room: room,
          status: status,
          typing: typing,
        );
      },
      groupInboxBuilder: (context, room, profile, status, typings) {
        return ChatInboxGroup(
          profile: profile,
          room: room,
          status: status,
          typings: typings,
        );
      },
      audioBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageAudio(message: msg),
        );
      },
      deletedBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageDeleted(message: msg),
        );
      },
      imageBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageImage(message: msg),
        );
      },
      linkBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageLink(message: msg),
        );
      },
      textBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageText(message: msg),
        );
      },
      videoBuilder: (context, manager, msg) {
        return ChatMessageBubble(
          manager: manager,
          message: msg,
          child: ChattingMessageVideo(message: msg),
        );
      },
      groupDateBuilder: (context, date) {
        return ChattingMessageGroupDate(date: date);
      },
      profileBuilder: (context, profile, status) {
        return ChatProfile(profile: profile, status: status);
      },
      typingBuilder: (context, typings) {
        return ChatTypingIndicator();
      },
      replayMessageReplyBuilder: (context, message, onCancel) {
        return ChatReplyMessagePreview(message: message, onCancel: onCancel);
      },
      scrollDownButtonBuilder: (context, unseens, onGo) {
        return ChatScrollDownButton(unseens: unseens, onGo: onGo);
      },
      noMessagesBuilder: (context) => ChatNoMessages(),
      visibilityDetectorBuilder: (context, id, child, changed) {
        return VisibilityDetector(
          key: ValueKey(id),
          onVisibilityChanged: (v) {
            changed(ChatVisibilityInfo(
              key: v.key,
              visibleFraction: v.visibleFraction,
              size: v.size,
            ));
          },
          child: child,
        );
      },
      onChatStart: (context, manager) {
        return Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatPage(manager: manager)),
        );
      },
      onImageCapture: (context) {
        return ImagePicker().pickImage(source: ImageSource.camera).then((v) {
          return v?.path;
        });
      },
      onImagePicker: (context) {
        return ImagePicker().pickImage(source: ImageSource.gallery).then((v) {
          return v?.path;
        });
      },
      onMutiImagePicker: (context) {
        return ImagePicker().pickMultiImage().then((v) {
          if (v.isEmpty) return [];
          final paths = v.map((e) => e.path).toList();
          return paths;
        });
      },
      onVideoCapture: (context) {
        return ImagePicker().pickVideo(source: ImageSource.camera).then((v) {
          return v?.path;
        });
      },
      onVideoPicker: (context) {
        return ImagePicker().pickVideo(source: ImageSource.gallery).then((v) {
          return v?.path;
        });
      },
      onVideoDuration: (context, path) async {
        final info = await VideoCompress.getMediaInfo(path);
        final duration = info.duration?.toInt() ?? 0;
        return duration;
      },
      onVideoThumbnail: (context, path) async {
        final thumbnail = await VideoCompress.getFileThumbnail(path);
        return thumbnail.path;
      },
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loggedIn = UserHelper.uid.isNotEmpty;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (loggedIn) {
      RoomManager.i.attach(UserHelper.uid);
    }

    _sub = FirebaseAuth.instance.authStateChanges().listen((v) {
      loggedIn = UserHelper.uid.isNotEmpty;
      if (loggedIn) {
        RoomManager.i.attach(UserHelper.uid);
      } else {
        RoomManager.i.detach();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat Kits',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: loggedIn ? InboxPage() : AuthPage(),
    );
  }
}
