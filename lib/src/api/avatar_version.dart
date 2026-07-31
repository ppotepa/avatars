/// Version identifiers persisted with requests and generated results.
///
/// Increment [generator] whenever the same seed can intentionally produce a
/// different genome or pixel buffer. Increment schema versions only when the
/// corresponding JSON contract changes incompatibly.
abstract final class AvatarGenomeVersion {
  static const int requestSchema = 1;
  static const int resultSchema = 2;
  static const String catalog = '4.3';
  static const String generator = '4.3.0-dart.2';
  static const String palette = 'p32.dynamic.1';
}
