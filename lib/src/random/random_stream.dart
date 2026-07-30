import '../util/math_utils.dart';

final class WeightedValue<T> {
  const WeightedValue(this.value, this.weight);

  final T value;
  final double weight;
}

/// Deterministic PRNG backed by two independently mixed 32-bit states.
///
/// The public seed is kept at 48 bits so it remains exact on Dart Web while
/// avoiding the previous 32-bit root-seed ceiling.
final class RandomStream {
  RandomStream(int seed)
      : seed = seed & 0xffffffffffff,
        _stateA = _initialA(seed),
        _stateB = _initialB(seed);

  final int seed;
  int _stateA;
  int _stateB;

  static int _initialA(int seed) {
    final value = (seed ^ (seed >> 24) ^ 0x6d2b79f5) & 0xffffffff;
    return value == 0 ? 0x6d2b79f5 : value;
  }

  static int _initialB(int seed) {
    final value = ((seed >> 16) ^ seed ^ 0x9e3779b9) & 0xffffffff;
    return value == 0 ? 0x9e3779b9 : value;
  }

  int _step(int state, int increment) {
    var t = (state + increment) & 0xffffffff;
    t = multiply32(t ^ (t >> 15), t | 1);
    t ^= (t + multiply32(t ^ (t >> 7), t | 61)) & 0xffffffff;
    return (t ^ (t >> 14)) & 0xffffffff;
  }

  int nextUint32() {
    _stateA = (_stateA + 0x6d2b79f5) & 0xffffffff;
    _stateB = (_stateB + 0x9e3779b9) & 0xffffffff;
    final first = _step(_stateA, 0x85ebca6b);
    final second = _step(_stateB, 0xc2b2ae35);
    return (first ^ ((second << 13) | (second >> 19))) & 0xffffffff;
  }

  double nextDouble() => nextUint32() / 4294967296.0;

  int nextInt(int min, int max) {
    if (max < min) {
      throw ArgumentError.value(max, 'max', 'Must be >= min.');
    }
    return min + (nextDouble() * (max - min + 1)).floor();
  }

  bool nextBool([double probability = 0.5]) =>
      nextDouble() < clampDouble(probability, 0, 1);

  T pick<T>(List<T> values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'Must not be empty.');
    }
    return values[nextInt(0, values.length - 1)];
  }

  T weightedPick<T>(List<WeightedValue<T>> values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'Must not be empty.');
    }
    final positive = values
        .where((item) => item.weight.isFinite && item.weight > 0)
        .toList(growable: false);
    if (positive.isEmpty) {
      throw ArgumentError.value(values, 'values', 'At least one weight must be positive.');
    }
    final total = positive.fold<double>(0, (sum, item) => sum + item.weight);
    var cursor = nextDouble() * total;
    for (final item in positive) {
      cursor -= item.weight;
      if (cursor <= 0) {
        return item.value;
      }
    }
    return positive.last.value;
  }

  RandomStream fork(String namespace) =>
      RandomStream(fnv1a32('$seed:$namespace'));
}
