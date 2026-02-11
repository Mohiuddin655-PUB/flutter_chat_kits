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
    return raw.map((k, v) {
      Object? value(Object? raw) {
        if (raw is num) return raw;
        if (raw is String) return raw;
        if (raw is bool) return raw;
        if (raw is List) return raw.map(value).toList();
        if (raw is Map) return normalize(raw, normalizer);
        return normalizer?.call(raw);
      }

      return MapEntry(k, value(v));
    });
  }
}
