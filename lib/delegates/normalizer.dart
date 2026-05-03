import '../utils/field_value.dart';

abstract class ChatFieldValueNormalizer {
  Object? message(Object? raw);

  Object? profile(Object? raw);

  Object? room(Object? raw);

  Object? status(Object? raw);

  Object? typing(Object? raw);

  ChatValueTimestamp timestamp(Object? raw);

  Map<String, dynamic> normalize(
    Object? raw,
    Object? Function(Object? raw)? normalizer,
  ) {
    if (raw is! Map) return {};
    return raw.map((key, val) {
      return MapEntry(
        key is String ? key : '$key',
        _normalizeValue(val, normalizer),
      );
    });
  }

  Object? _normalizeValue(Object? raw, Object? Function(Object?)? normalizer) {
    if (raw == null || raw is num || raw is String || raw is bool) return raw;
    if (raw is List) {
      return raw.map((e) => _normalizeValue(e, normalizer)).toList();
    }
    if (raw is Set) {
      return raw.map((e) => _normalizeValue(e, normalizer)).toList();
    }
    if (raw is Map) return normalize(raw, normalizer);
    return normalizer?.call(raw);
  }
}
