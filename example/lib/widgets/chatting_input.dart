import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

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
  void _showAttachmentOptions() {
    ChatAttachmentPicker.show(context).then((tag) {
      if (tag == 'camera') {
        widget.configs.onCaptureImage();
      } else if (tag == 'images') {
        widget.configs.onSendImages();
      } else if (tag == 'captured_video') {
        widget.configs.onCaptureVideo();
      } else if (tag == 'video') {
        widget.configs.onSendVideo();
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
