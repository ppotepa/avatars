import 'resolution_profile.dart';

/// Allocates the finite semantic detail budget to regions in perceptual order.
/// Face identity and hand pose remain legible before decorative surfaces gain
/// additional texture.
final class RegionalDetailBudget {
  const RegionalDetailBudget._(this.values);

  final Map<String, int> values;

  int forOwner(String owner) => values[owner] ?? values['default'] ?? 0;

  factory RegionalDetailBudget.forProfile(ResolutionProfile profile) {
    final total = profile.detailBudget;
    if (total == 0) {
      return const RegionalDetailBudget._(<String, int>{'default': 0});
    }
    return RegionalDetailBudget._(<String, int>{
      'eyes': total,
      'mouth': total,
      'head': total,
      'brows': total,
      'hair': total,
      'leftHand': total,
      'rightHand': total,
      'clothing': total >= 2 ? total - 1 : 0,
      'armor': total >= 2 ? total - 1 : 1,
      'jewelry': total >= 2 ? total - 1 : 1,
      'cyber': total >= 2 ? total - 1 : 1,
      'companion': total >= 3 ? 1 : 0,
      'background': 0,
      'default': total >= 3 ? 1 : 0,
    });
  }
}
