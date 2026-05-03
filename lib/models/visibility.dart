import 'dart:ui';

import 'package:flutter/foundation.dart';

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
