import '../models/message.dart';

/// Static helpers for inferring file extensions and storage-prefix labels
/// from file paths and [MessageType] fallbacks.
///
/// This is a pure utility class — it has no dependency on [RoomManager]
/// or any delegates. Upload orchestration lives in [MessageMixin].
abstract final class FileUploadHelper {
  // ── Prefix Map ────────────────────────────────────────────────────────────

  /// Single source of truth for both extension recognition and prefix mapping.
  static const _extensionToPrefix = {
    'jpg': 'img',
    'jpeg': 'img',
    'png': 'img',
    'webp': 'img',
    'gif': 'img',
    'bmp': 'img',
    'mp3': 'aud',
    'm4a': 'aud',
    'aac': 'aud',
    'wav': 'aud',
    'ogg': 'aud',
    'flac': 'aud',
    'mp4': 'vid',
    'mov': 'vid',
    'avi': 'vid',
    'mkv': 'vid',
    'webm': 'vid',
    '3gp': 'vid',
  };

  // ── Extension Detection ───────────────────────────────────────────────────

  /// Extracts the file extension from [path].
  ///
  /// Falls back to the canonical extension for [fallbackType] when the
  /// path extension is unrecognised or absent.
  static String? fileExtension(
    String path, {
    required MessageType fallbackType,
  }) {
    final clean = path.split('?').first;
    final parts = clean.split('.');
    if (parts.length >= 2) {
      final ext = parts.last.toLowerCase();
      if (_extensionToPrefix.containsKey(ext)) return ext;
    }
    return _fallbackExtension(fallbackType);
  }

  // ── Prefix Resolution ─────────────────────────────────────────────────────

  /// Maps a file [ext] to a short storage prefix (img / aud / vid / txt).
  ///
  /// Falls back to the canonical prefix for [fallbackType] when [ext]
  /// is not in the map.
  static String filePrefix(String? ext, {required MessageType fallbackType}) {
    return _extensionToPrefix[ext] ?? _fallbackPrefix(fallbackType);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  static String? _fallbackExtension(MessageType type) => switch (type) {
    MessageType.audio => 'm4a',
    MessageType.image => 'jpg',
    MessageType.video => 'mp4',
    _ => null,
  };

  static String _fallbackPrefix(MessageType type) => switch (type) {
    MessageType.audio => 'aud',
    MessageType.image => 'img',
    MessageType.video => 'vid',
    _ => 'txt',
  };
}
