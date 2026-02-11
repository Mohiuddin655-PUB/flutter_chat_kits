import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatVoiceRecorder extends StatefulWidget {
  final Function(String path, int duration) onComplete;
  final Function(bool isRecording) onStateChanged;

  const ChatVoiceRecorder({
    super.key,
    required this.onComplete,
    required this.onStateChanged,
  });

  @override
  State<ChatVoiceRecorder> createState() => _ChatVoiceRecorderState();
}

class _ChatVoiceRecorderState extends State<ChatVoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordingPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordingPath =
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        widget.onStateChanged(true);

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();

      if (path != null && _recordDuration > 0) {
        widget.onComplete(path, _recordDuration);
      }

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      widget.onStateChanged(false);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      await _recorder.stop();

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      widget.onStateChanged(false);
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelRecording,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _stopRecording,
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.mic, color: Colors.blue),
      onPressed: _startRecording,
    );
  }
}
