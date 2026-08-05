import 'dart:convert';

String stableFingerprint(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = <MapEntry<String, Object?>>[
      for (final entry in value.entries)
        MapEntry(entry.key.toString(), entry.value),
    ]..sort((left, right) => left.key.compareTo(right.key));
    return <String, Object?>{
      for (final entry in entries) entry.key: _canonicalize(entry.value),
    };
  }
  if (value is Iterable && value is! String) {
    return <Object?>[
      for (final item in value) _canonicalize(item),
    ];
  }
  return value;
}
