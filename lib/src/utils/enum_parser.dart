extension ChatEnumParser<T extends Enum> on Iterable<T> {
  T? tryParse(Object? value) {
    if (value == null) return null;

    if (value is T) return value;

    if (value is int) {
      return elementAtOrNull(value);
    }

    if (value is! String) {
      return null;
    }

    try {
      final normalized = value.split('.').last.toLowerCase().trim();

      return firstWhere((e) => e.name.toLowerCase() == normalized);
    } catch (_) {
      return null;
    }
  }

  T parse(Object? raw) => tryParse(raw) ?? first;

  Map<String, T> references(Object? raw) {
    if (raw is! Map || raw.isEmpty) return {};
    final entries = raw.entries.map((e) {
      final k = e.key.toString();
      final v = tryParse(e.value);
      if (k.isEmpty) return null;
      if (v == null || v.name == 'none') return null;
      return MapEntry(k, v);
    }).whereType<MapEntry<String, T>>();
    return Map.fromEntries(entries);
  }
}
