import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatPage extends StatelessWidget {
  final ChatManager manager;

  const ChatPage({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppbar(manager: manager),
      body: ChatBody(manager: manager),
    );
  }
}
