import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

class ChattingMessageAudio extends StatefulWidget {
  final AudioMessage message;

  const ChattingMessageAudio({
    super.key,
    required this.message,
  });

  @override
  State<ChattingMessageAudio> createState() => _ChattingMessageAudioState();
}

class _ChattingMessageAudioState extends State<ChattingMessageAudio> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool get isMe => widget.message.isSentByMe;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.message.duration;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(widget.message.isSending
          ? DeviceFileSource(widget.message.url)
          : UrlSource(widget.message.url));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isSending) {
      return _buildSendingWidget();
    }

    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.white : Colors.blue,
            ),
            onPressed: _togglePlayPause,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: isMe ? Colors.white : Colors.blue,
                    inactiveTrackColor: isMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey[300],
                    thumbColor: isMe ? Colors.white : Colors.blue,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) async {
                      final position = Duration(
                        milliseconds:
                            (value * _totalDuration.inMilliseconds).round(),
                      );
                      await _audioPlayer.seek(position);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatDuration(_currentPosition),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(_totalDuration),
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendingWidget() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? Colors.white : Colors.blue,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Sending...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(_totalDuration),
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
