import '../../../pixels/pixel_mask.dart';

final class AtmosphereMasks {
  const AtmosphereMasks(this.dark, this.base, this.light);

  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;

  factory AtmosphereMasks.empty() =>
      AtmosphereMasks(PixelMask(), PixelMask(), PixelMask());
}
