import '../models/message.dart';

class MessageUploadData {
  final String roomId;
  final String msgId;
  final String path;
  final String name;

  const MessageUploadData({
    required this.roomId,
    required this.msgId,
    required this.path,
    required this.name,
  });

  static const _mimeMap = {
    // Image
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    // Video
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    // Audio
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
  };

  String? get contentType {
    final clean = path.split('?').first.split('#').first;
    final ext = clean.split('.').last.toLowerCase();
    return _mimeMap[ext];
  }
}

abstract class ChatMessageDelegate {
  Future<void> create(String roomId, String msgId, Map<String, dynamic> value);

  Future<void> delete(String roomId, String id);

  Future<void> deletes(Iterable<Message> messages);

  Future<void> deleteAll(String roomId);

  Future<void> update(String roomId, String id, Map<String, dynamic> value);

  Future<void> updates(String roomId, Map<String, Map<String, dynamic>> values);

  Future<String> upload(MessageUploadData data);

  Future<void> deleteFromStorage(String url);

  Future<List<Message>> fetch(String roomId);

  Stream<List<Message>> stream(String roomId);

  /// Paginated stream — emits the latest [limit] messages, with the ability
  /// to load older pages on demand. App's delegate implementation (Firestore,
  /// Supabase, etc.) is responsible for the actual pagination logic.
  ///
  /// Returns a stream of the current "window" of loaded messages. Calling
  /// [loadMore] expands the window backward (older messages prepended).
  PaginatedMessageStream streamPaginated(String roomId, {int pageSize = 50});
}

/// A message stream with pagination control.
abstract class PaginatedMessageStream {
  /// Live stream of the current loaded window.
  Stream<List<Message>> get stream;

  /// Load the next page of older messages. Returns true if more were loaded,
  /// false if already at the start of history.
  Future<bool> loadMore();

  /// Whether more older messages are available.
  bool get hasMore;

  /// Cancel and clean up.
  Future<void> cancel();
}
