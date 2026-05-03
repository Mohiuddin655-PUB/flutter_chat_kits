import 'dart:io';

bool get platformIsAndroid => Platform.isAndroid;

bool get platformIsIos => Platform.isIOS;

bool get platformIsMacOS => Platform.isMacOS;

String get nativePlatform =>
    Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : Platform.isMacOS
        ? 'macos'
        : Platform.isFuchsia
        ? 'fuchsia'
        : Platform.isLinux
        ? 'linux'
        : Platform.isWindows
        ? 'windows'
        : 'unknown';
