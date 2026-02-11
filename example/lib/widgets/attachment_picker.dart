import 'package:flutter/material.dart';

class ChatAttachmentPicker extends StatelessWidget {
  const ChatAttachmentPicker({super.key});

  static Future<String?> show(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return ChatAttachmentPicker();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, "camera"),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blue),
            title: const Text('Photos'),
            onTap: () => Navigator.pop(context, "images"),
          ),
          ListTile(
            leading:
                const Icon(Icons.video_camera_back_rounded, color: Colors.blue),
            title: const Text('Record'),
            onTap: () => Navigator.pop(context, "captured_video"),
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.blue),
            title: const Text('Video'),
            onTap: () => Navigator.pop(context, "video"),
          ),
        ],
      ),
    );
  }
}
