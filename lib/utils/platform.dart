import 'package:flutter/foundation.dart';

import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

String get currentPlatform => kIsWeb ? 'web' : nativePlatform;
