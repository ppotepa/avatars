import 'package:avatar_genome/src/rendering/resolution_profile.dart';
import 'package:test/test.dart';

void main() {
  test('larger sizes expose increasing semantic detail budgets', () {
    final p48 = ResolutionProfile.forSize(48);
    final p64 = ResolutionProfile.forSize(64);
    final p80 = ResolutionProfile.forSize(80);
    final p96 = ResolutionProfile.forSize(96);

    expect(p48.nativeGeometry, isFalse);
    expect(p64.nativeGeometry, isTrue);
    expect(p48.detailBudget, lessThan(p64.detailBudget));
    expect(p64.detailBudget, lessThan(p80.detailBudget));
    expect(p80.detailBudget, lessThan(p96.detailBudget));
    expect(p96.outlineThickness, greaterThan(p48.outlineThickness));
  });

  test('render grid scales logical coordinates deterministically', () {
    final grid64 = RenderGrid(ResolutionProfile.forSize(64));
    final grid96 = RenderGrid(ResolutionProfile.forSize(96));

    expect(grid64.x(24), closeTo(32, 1));
    expect(grid96.x(24), closeTo(48, 1));
    expect(grid96.length(4), greaterThan(grid64.length(4)));
    expect(grid96.stroke(), greaterThanOrEqualTo(2));
  });
}
