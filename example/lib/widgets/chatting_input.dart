import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';
import 'package:image_picker/image_picker.dart';

import 'attachment_picker.dart';
import 'voice_recorder.dart';

class ChattingInput extends StatefulWidget {
  final ChatInputConfigs configs;

  const ChattingInput({
    super.key,
    required this.configs,
  });

  @override
  State<ChattingInput> createState() => _ChattingInputState();
}

class _ChattingInputState extends State<ChattingInput> {
  String? _path(XFile? file) => file?.path;

  void _showAttachmentOptions() {
    ChatAttachmentPicker.show(context).then((tag) async {
      if (tag == 'camera') {
        final path = await ImagePicker()
            .pickImage(source: ImageSource.camera)
            .then((e) => e?.path);
        if (path == null) return;
        widget.configs.onCaptureImage(path);
      } else if (tag == 'images') {
        final paths = await ImagePicker()
            .pickMultiImage()
            .then((e) => e.map((e) => e.path).toList());
        if (paths.isEmpty) return;
        widget.configs.onSendImages(paths);
      } else if (tag == 'captured_video') {
        final path = await ImagePicker()
            .pickVideo(source: ImageSource.camera)
            .then((e) => e?.path);
        if (path == null) return;
        widget.configs.onCaptureVideo(path);
      } else if (tag == 'video') {
        final path = await ImagePicker()
            .pickVideo(source: ImageSource.gallery)
            .then((e) => e?.path);
        if (path == null) return;
        widget.configs.onSendVideo(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.configs.editor,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: widget.configs.editor,
              builder: (context, child) {
                if (widget.configs.editor.text.trim().isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: widget.configs.onSendText,
                  );
                }
                return ChatVoiceRecorder(
                  onComplete: widget.configs.onSendVoice,
                  onStateChanged: (isRecording) {
                    setState(() {});
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
