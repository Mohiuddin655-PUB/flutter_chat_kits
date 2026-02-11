import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppbar(),
      body: ChatBody(),
    );
  }
}
