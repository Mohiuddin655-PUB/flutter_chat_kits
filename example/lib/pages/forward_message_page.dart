import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ForwardMessagePage extends StatefulWidget {
  final Message message;

  const ForwardMessagePage({
    super.key,
    required this.message,
  });

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  final Set<String> _selectedRoomIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward message'),
        actions: [
          if (_selectedRoomIds.isNotEmpty)
            TextButton(
              onPressed: _forwardMessage,
              child: Text(
                'Send (${_selectedRoomIds.length})',
                style: const TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedRoomIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedRoomIds.length} ${_selectedRoomIds.length == 1 ? 'chat' : 'chats'} selected',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedRoomIds.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: RoomManager.i,
              builder: (context, child) {
                final rooms = RoomManager.i.rooms;
                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('No chats available'),
                  );
                }

                final availableRooms = rooms.where((e) {
                  return e.id != widget.message.roomId;
                }).toList();

                if (availableRooms.isEmpty) {
                  return const Center(
                    child: Text('No other chats available'),
                  );
                }

                return ListView.builder(
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = availableRooms[index];
                    final roomId = room.id;
                    final participants = room.participants.toList();
                    return Column(
                      children: [
                        ...participants.map((e) {
                          final otherUser = RoomManager.i.profileFor(e);
                          return CheckboxListTile(
                            value: _selectedRoomIds.contains(roomId),
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedRoomIds.add(roomId);
                                } else {
                                  _selectedRoomIds.remove(roomId);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              backgroundImage: otherUser.photo != null
                                  ? NetworkImage(otherUser.photo!)
                                  : null,
                              child: otherUser.photo == null
                                  ? Text(
                                      otherUser.name?[0].toUpperCase() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(otherUser.name ?? ''),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _forwardMessage() {
    if (_selectedRoomIds.isEmpty) return;
    RoomManager.i.forward(_selectedRoomIds.toList(), widget.message);
  }
}
