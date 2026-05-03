import 'package:flutter/foundation.dart' show kIsWeb;

import '_platform_stub.dart' if (dart.library.io) '_platform_io.dart';

String get currentPlatform => kIsWeb ? 'web' : nativePlatform;
