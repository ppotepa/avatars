import '../api/avatar_request.dart';

/// Describes how much native geometry and semantic detail a render size can
/// support. The logical coordinate space remains 48×48, while rasterization
/// happens directly on the requested output grid.
final class ResolutionProfile {
  const ResolutionProfile({
    required this.size,
    required this.detailBudget,
    required this.outlineThickness,
    required this.featureThickness,
    required this.nativeGeometry,
  });

  final int size;
  final int detailBudget;
  final int outlineThickness;
  final int featureThickness;
  final bool nativeGeometry;

  double get scale => size / 48;

  static ResolutionProfile forSettings(AvatarRenderSettings settings) =>
      forSize(settings.size);

  static ResolutionProfile forSize(int size) => switch (size) {
        48 => const ResolutionProfile(
            size: 48,
            detailBudget: 0,
            outlineThickness: 1,
            featureThickness: 1,
            nativeGeometry: false,
          ),
        64 => const ResolutionProfile(
            size: 64,
            detailBudget: 1,
            outlineThickness: 1,
            featureThickness: 1,
            nativeGeometry: true,
          ),
        80 => const ResolutionProfile(
            size: 80,
            detailBudget: 2,
            outlineThickness: 2,
            featureThickness: 1,
            nativeGeometry: true,
          ),
        96 => const ResolutionProfile(
            size: 96,
            detailBudget: 3,
            outlineThickness: 2,
            featureThickness: 2,
            nativeGeometry: true,
          ),
        _ => ResolutionProfile(
            size: size,
            detailBudget: size <= 48 ? 0 : 1,
            outlineThickness: size >= 80 ? 2 : 1,
            featureThickness: size >= 96 ? 2 : 1,
            nativeGeometry: size > 48,
          ),
      };
}

/// Converts logical 48-space geometry into a concrete destination grid while
/// keeping all rounding deterministic and centered.
final class RenderGrid {
  const RenderGrid(this.profile);

  final ResolutionProfile profile;

  int get width => profile.size;
  int get height => profile.size;
  int get detailBudget => profile.detailBudget;

  int x(num logical) => _scaled(logical);
  int y(num logical) => _scaled(logical);
  int length(num logical) => _scaledLength(logical);

  int stroke([num logical = 1]) {
    final scaled = _scaledLength(logical);
    return scaled < profile.featureThickness
        ? profile.featureThickness
        : scaled;
  }

  int outline([num logical = 1]) {
    final scaled = _scaledLength(logical);
    return scaled < profile.outlineThickness
        ? profile.outlineThickness
        : scaled;
  }

  int _scaled(num value) =>
      ((value * profile.size * 2 + 48) ~/ (48 * 2)).clamp(0, profile.size - 1);

  int _scaledLength(num value) {
    final scaled = (value * profile.size / 48).round();
    return scaled < 1 ? 1 : scaled;
  }
}
