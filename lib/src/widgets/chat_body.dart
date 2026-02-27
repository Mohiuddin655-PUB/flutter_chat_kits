import 'package:flutter/material.dart';
import 'package:flutter_chat_kits/flutter_chat_kits.dart';

import 'bottom_bar.dart';

class ChatBody extends StatelessWidget {
  final ChatManager manager;
  final double? scrollToBottomThreshold;
  final Curve? scrollToBottomAnimationCurve;
  final Duration? scrollToBottomAnimationDuration;
  final ScrollController? scrollController;
  final TextEditingController? textEditingController;
  final EdgeInsets? contentPadding;
  final EdgeInsets? contentMargin;

  const ChatBody({
    super.key,
    required this.manager,
    this.scrollToBottomThreshold,
    this.scrollToBottomAnimationCurve,
    this.scrollToBottomAnimationDuration,
    this.scrollController,
    this.contentPadding,
    this.contentMargin,
    this.textEditingController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: contentMargin ?? EdgeInsets.zero,
          child: ChatBoard(
            manager: manager,
            scrollToBottomThreshold: scrollToBottomThreshold,
            scrollToBottomAnimationCurve: scrollToBottomAnimationCurve,
            scrollToBottomAnimationDuration: scrollToBottomAnimationDuration,
            controller: scrollController,
            padding: contentPadding,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ChatBottomBar(
            manager: manager,
            textEditingController: textEditingController,
          ),
        ),
      ],
    );
  }
}
