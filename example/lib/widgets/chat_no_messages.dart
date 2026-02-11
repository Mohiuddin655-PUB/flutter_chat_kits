import 'package:flutter/material.dart';

class ChatNoMessages extends StatelessWidget {
  const ChatNoMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No messages yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
