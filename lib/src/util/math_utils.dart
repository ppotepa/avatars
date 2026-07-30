int clampInt(int value, int min, int max) =>
    value < min ? min : (value > max ? max : value);

double clampDouble(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);

int roundInt(num value) => value.round();

double lerpDouble(num a, num b, double t) =>
    (a + (b - a) * t).toDouble();

int positiveMod(int value, int modulus) =>
    ((value % modulus) + modulus) % modulus;

int fnv1a32(String text) {
  var hash = 0x811c9dc5;
  for (final codeUnit in text.codeUnits) {
    hash ^= codeUnit;
    hash = ((hash * 0x01000193) & 0xffffffff);
  }
  return hash & 0xffffffff;
}

String hex32(int value) =>
    (value & 0xffffffff).toRadixString(16).padLeft(8, '0');

String hash48(Iterable<int> bytes, {Iterable<int> prefix = const <int>[]}) {
  const mask24 = 0xffffff;
  var high = 0x811c9d;
  var low = 0xc5a5b7;

  void mix(int byte) {
    final value = byte & 0xff;
    high = ((high ^ value) * 0x010193) & mask24;
    low = ((low ^ value) * 0x0001b3) & mask24;
    high = (high + (low >> 7)) & mask24;
    low = (low + (high >> 5)) & mask24;
  }

  for (final byte in prefix) mix(byte);
  for (final byte in bytes) mix(byte);
  return '${high.toRadixString(16).padLeft(6, '0')}'
      '${low.toRadixString(16).padLeft(6, '0')}';
}

int signed32(int value) {
  final v = value & 0xffffffff;
  return v >= 0x80000000 ? v - 0x100000000 : v;
}

int multiply32(int a, int b) => (a * b) & 0xffffffff;
