import '../models/message.dart';

class MessageUploadData {
  final String roomId;
  final String msgId;
  final String path;
  final String name;

  String? get contentType {
    final clean = path.split('?').first;
    final ext = clean.split('.').last.toLowerCase();

    const mimeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
    };

    String? mime = mimeMap[ext];
    if (mime != null) return mime;
    return null;
  }

  const MessageUploadData({
    required this.roomId,
    required this.msgId,
    required this.path,
    required this.name,
  });
}

abstract class ChatMessageDelegate {
  Future<void> create(String roomId, String msgId, Map<String, dynamic> value);

  Future<void> delete(String roomId, String id);

  Future<void> deletes(Iterable<Message> messages);

  Future<void> update(String roomId, String id, Map<String, dynamic> value);

  Future<void> updates(String roomId, Map<String, Map<String, dynamic>> values);

  Future<String> upload(MessageUploadData data);

  Future<void> deleteFromStorage(String url);

  Stream<List<Message>> stream(String roomId);
}
