Object? deepFreezeValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): deepFreezeValue(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(deepFreezeValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(deepFreezeValue));
  }
  return value;
}

Map<String, Object?> deepFreezeStringMap(Map<String, Object?> source) =>
    Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in source.entries)
        entry.key: deepFreezeValue(entry.value),
    });

Map<String, Object> deepFreezeObjectMap(Map<String, Object> source) =>
    Map<String, Object>.unmodifiable(<String, Object>{
      for (final entry in source.entries)
        entry.key: deepFreezeValue(entry.value) as Object,
    });
