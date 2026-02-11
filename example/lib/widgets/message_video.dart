import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import '../pages/video_preview_page.dart';

class ChattingMessageVideo extends StatelessWidget {
  final VideoMessage message;

  const ChattingMessageVideo({
    super.key,
    required this.message,
  });

  bool get isSending => message.isSending;

  bool get isMe => message.isSentByMe;

  void _onPreview(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (c) {
      return VideoPreviewPage(
        videoUrl: message.url,
        thumbnail: message.thumbnail,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onPreview(context),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (isSending) {
      return Image.file(
        File(message.thumbnail),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (c, e, st) => _buildError(),
      );
    }
    return CachedNetworkImage(
      imageUrl: message.thumbnail,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      progressIndicatorBuilder: (c, u, p) => _buildProgress(p.progress ?? 0),
      errorWidget: (c, e, st) => _buildError(),
    );
  }

  Widget _buildProgress(double progress) {
    return CircularProgressIndicator(
      value: progress,
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [Icon(Icons.error_outline_rounded), Text("Loading failed!")],
    );
  }
}
