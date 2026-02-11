import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import '../pages/image_preview_page.dart';

class ChattingMessageImage extends StatelessWidget {
  final ImageMessage message;

  const ChattingMessageImage({
    super.key,
    required this.message,
  });

  bool get isMe => message.isSentByMe;

  bool get isSending => message.isSending;

  List<String> get urls => message.urls;

  void _onPreview(BuildContext context, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (c) {
      return ImagePreviewPage(imageUrls: urls, initialIndex: index);
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return SizedBox(
        width: 300,
        height: 300,
        child: GestureDetector(
          onTap: () => _onPreview(context, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(urls.first),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: urls.length == 2 ? 2 : 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: urls.length > 4 ? 4 : urls.length,
      itemBuilder: (context, index) {
        final showMore = urls.length > 4 && index == 3;
        return GestureDetector(
          onTap: () => _onPreview(context, index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(urls[index]),
              ),
              if (showMore) _buildShowMore(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String src) {
    if (isSending) {
      return Image.file(
        File(src),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (c, e, st) => _buildError(),
      );
    }
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      progressIndicatorBuilder: (c, u, p) => _buildProgress(p.progress ?? 0),
      errorWidget: (c, e, st) => _buildError(),
    );
  }

  Widget _buildProgress(double progress) {
    return Center(
      child: CircularProgressIndicator(
        value: progress,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
          ),
          Text(
            "Loading failed!",
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildShowMore() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '+${urls.length - 3}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
