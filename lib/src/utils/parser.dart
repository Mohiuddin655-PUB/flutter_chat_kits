extension MapParser on Map {
  Map<K, V> parse<K, V>({V? Function(Object? raw)? parser}) {
    if (isEmpty) return {};
    final entries = this.entries.map((e) {
      final k = e.key;
      final v = parser?.call(e.value) ?? e.value;
      if (k is! K) return null;
      if (v is! V) return null;
      return MapEntry(k, v);
    }).whereType<MapEntry<K, V>>();
    return Map.fromEntries(entries);
  }
}

extension ChatListParser on Iterable {
  Iterable<E> parse<E>({
    E? Function(Object? raw)? parser,
    bool Function(E e)? check,
  }) {
    if (isEmpty) return {};
    final entries = map((e) {
      final v = parser?.call(e) ?? e;
      if (v is! E) return null;
      if (check != null && !check(v)) return null;
      return v;
    }).whereType<E>();
    return entries;
  }

  Iterable<int> get parsedInts {
    if (isEmpty) return {};
    return parse(parser: (e) => e is num ? e.toInt() : 0);
  }

  Iterable<double> get parsedDoubles {
    if (isEmpty) return {};
    return parse(parser: (e) => e is num ? e.toDouble() : 0);
  }

  Iterable<String> get parsedStrings {
    if (isEmpty) return {};
    return parse(parser: (e) => e.toString(), check: (e) => e.isNotEmpty);
  }
}
