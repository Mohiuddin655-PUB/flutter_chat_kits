import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show Key;

class VisibilityInfo {
  final Key? key;
  final Size size;
  final double visibleFraction;

  const VisibilityInfo({
    this.key,
    this.size = Size.zero,
    this.visibleFraction = 0,
  });
}
