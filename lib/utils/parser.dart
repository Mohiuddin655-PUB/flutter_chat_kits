extension MapParser on Map {
  Map<K, V>? tryParse<K, V>({V? Function(Object? raw)? parser}) {
    if (isEmpty) return null;

    final entries =
        this.entries.map((e) {
          final k = e.key;
          final v = parser?.call(e.value) ?? e.value;
          if (k is! K) return null;
          if (v is! V) return null;
          return MapEntry(k, v);
        }).whereType<MapEntry<K, V>>();

    final result = Map.fromEntries(entries);
    return result.isEmpty ? null : result;
  }

  Map<K, V> parse<K, V>({V? Function(Object? raw)? parser}) {
    return tryParse(parser: parser) ?? {};
  }
}

extension ChatListParser on Iterable {
  Iterable<E> parse<E>({
    E? Function(Object? raw)? parser,
    bool Function(E e)? check,
  }) {
    if (isEmpty) return const [];
    return map((e) {
      final v = parser?.call(e) ?? e;
      if (v is! E) return null;
      if (check != null && !check(v)) return null;
      return v;
    }).whereType<E>();
  }

  List<int> get parsedInts {
    return parse(parser: (e) => e is num ? e.toInt() : null).toList();
  }

  List<double> get parsedDoubles {
    return parse(parser: (e) => e is num ? e.toDouble() : null).toList();
  }

  List<String> get parsedStrings {
    return parse(
      parser: (e) => e?.toString(),
      check: (e) => e.isNotEmpty,
    ).toList();
  }
}
