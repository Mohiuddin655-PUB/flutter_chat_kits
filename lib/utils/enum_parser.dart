extension ChatEnumParser<T extends Enum> on Iterable<T> {
  T? tryParse(Object? value) {
    if (value == null) return null;
    if (value is T) return value;

    if (value is int) return elementAtOrNull(value);

    if (value is! String) return null;

    final normalized = value.split('.').last.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    return firstWhereOrNull((e) => e.name.toLowerCase() == normalized);
  }

  T parse(Object? raw, {T? fallback}) => tryParse(raw) ?? fallback ?? first;

  Map<String, T>? tryReferences(Object? raw) {
    if (raw is! Map || raw.isEmpty) return null;

    final entries = raw.entries.map((e) {
      final k = e.key.toString();
      final v = tryParse(e.value);
      if (k.isEmpty || v == null) return null;
      return MapEntry(k, v);
    }).whereType<MapEntry<String, T>>();

    final map = Map.fromEntries(entries);
    return map.isEmpty ? null : map;
  }

  Map<String, T> references(Object? raw) => tryReferences(raw) ?? {};

  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
