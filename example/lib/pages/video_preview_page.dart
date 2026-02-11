import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  final String thumbnail;
  final String videoUrl;

  const VideoPreviewPage({
    super.key,
    required this.thumbnail,
    required this.videoUrl,
  });

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isSaving = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });

      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });

      await Future.delayed(Duration(milliseconds: 200));
      await _controller.play();
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  Future<void> _saveVideo() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      await Dio().download(
        widget.videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // final result = await ImageGallerySaver.saveFile(filePath);
      //
      // if (mounted) {
      //   if (result['isSuccess']) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Video saved to gallery'),
      //         backgroundColor: Colors.green,
      //       ),
      //     );
      //   } else {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Failed to save video'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //   }
      // }
      //
      // await File(filePath).delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Video',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isSaving ? null : _saveVideo,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_controller.value.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  if (_showControls)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 64,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  if (_showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.blue,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
