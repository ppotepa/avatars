import '../util/math_utils.dart';

final class WeightedValue<T> {
  const WeightedValue(this.value, this.weight);

  final T value;
  final double weight;
}

final class RandomStream {
  RandomStream(int seed)
      : seed = (seed & 0xffffffff) == 0 ? 0x6d2b79f5 : seed & 0xffffffff,
        _state = (seed & 0xffffffff) == 0 ? 0x6d2b79f5 : seed & 0xffffffff;

  final int seed;
  int _state;

  int nextUint32() {
    _state = (_state + 0x6d2b79f5) & 0xffffffff;
    var t = _state;
    t = multiply32(t ^ (t >> 15), t | 1);
    t ^= (t + multiply32(t ^ (t >> 7), t | 61)) & 0xffffffff;
    return (t ^ (t >> 14)) & 0xffffffff;
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
    final total = values.fold<double>(0, (sum, item) => sum + item.weight);
    var cursor = nextDouble() * total;
    for (final item in values) {
      cursor -= item.weight;
      if (cursor <= 0) {
        return item.value;
      }
    }
    return values.last.value;
  }

  RandomStream fork(String namespace) =>
      RandomStream(fnv1a32('$seed:$namespace'));
}
