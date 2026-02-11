import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // final status = await Permission.storage.request();
      // if (!status.isGranted) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Storage permission denied'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //   }
      //   return;
      // }
      //
      // final imageUrl = widget.imageUrls[_currentIndex];
      // final response = await Dio().get(
      //   imageUrl,
      //   options: Options(responseType: ResponseType.bytes),
      // );

      // final result = await ImageGallerySaver.saveImage(
      //   response.data,
      //   quality: 100,
      // );
      //
      // if (mounted) {
      //   if (result['isSuccess']) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Image saved to gallery'),
      //         backgroundColor: Colors.green,
      //       ),
      //     );
      //   } else {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Failed to save image'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //   }
      // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
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
            onPressed: _isSaving ? null : _saveImage,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: _buildImage(widget.imageUrls[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String src) {
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.contain,
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
}
