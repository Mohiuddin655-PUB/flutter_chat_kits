import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import 'user_list_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = RoomManager.i.me;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chatty"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsersListPage(
                currentUserId: currentUserId,
              ),
            ),
          );
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: RoomManager.i,
        builder: (context, child) {
          final loading = RoomManager.i.loading;
          if (loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final rooms = RoomManager.i.rooms;

          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ChatInbox(room: room);
            },
          );
        },
      ),
    );
  }
}
