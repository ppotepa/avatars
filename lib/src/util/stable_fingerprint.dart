import 'dart:convert';

String stableFingerprint(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is Iterable && value is! String) {
    return <Object?>[
      for (final item in value) _canonicalize(item),
    ];
  }
  return value;
}
