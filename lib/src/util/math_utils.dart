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

int signed32(int value) {
  final v = value & 0xffffffff;
  return v >= 0x80000000 ? v - 0x100000000 : v;
}

int multiply32(int a, int b) => (a * b) & 0xffffffff;
