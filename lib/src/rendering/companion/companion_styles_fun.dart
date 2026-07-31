import '../../geometry/point.dart';
import 'companion_rig_v2_model.dart';

CompanionStyleSpec? funCompanionStyle(String id) => switch (id) {
      'stormCloud' => const CompanionStyleSpec(
          id: 'stormCloud',
          profile: CompanionMotionProfile.floating,
          paint: _stormCloud,
          speaks: true,
          floats: true,
        ),
      'flameOrb' => const CompanionStyleSpec(
          id: 'flameOrb',
          profile: CompanionMotionProfile.floating,
          paint: _flameOrb,
          speaks: true,
          floats: true,
        ),
      'blackHole' => const CompanionStyleSpec(
          id: 'blackHole',
          profile: CompanionMotionProfile.floating,
          paint: _blackHole,
          floats: true,
        ),
      'slime' => const CompanionStyleSpec(
          id: 'slime',
          profile: CompanionMotionProfile.slime,
          paint: _slime,
          speaks: true,
        ),
      'coffeeBuddy' => const CompanionStyleSpec(
          id: 'coffeeBuddy',
          profile: CompanionMotionProfile.humanoid,
          paint: _coffee,
          speaks: true,
        ),
      'donutBuddy' => const CompanionStyleSpec(
          id: 'donutBuddy',
          profile: CompanionMotionProfile.arcade,
          paint: _donut,
          speaks: true,
          floats: true,
        ),
      'emojiOrb' => const CompanionStyleSpec(
          id: 'emojiOrb',
          profile: CompanionMotionProfile.arcade,
          paint: _emojiOrb,
          speaks: true,
          floats: true,
        ),
      'miniBlackCatCloud' => const CompanionStyleSpec(
          id: 'miniBlackCatCloud',
          profile: CompanionMotionProfile.floating,
          paint: _catCloud,
          speaks: true,
          floats: true,
        ),
      _ => null,
    };

void _stormCloud(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x - 4, y - 11, 5, 4)
    ..fillEllipse(x + 3, y - 12, 6, 5)
    ..fillRect(x - 8, y - 11, 17, 6);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 12)
    ..set(x + 3, y - 12);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 9);
  p[CompanionNode.leftTentacle]
    ..line(x - 4, y - 7, x - 6, y - 2)
    ..set(x - 7, y);
  p[CompanionNode.rightTentacle]
    ..line(x + 4, y - 7, x + 6, y - 2)
    ..set(x + 7, y);
  p[CompanionNode.trail]
    ..line(x - 1, y - 6, x - 3, y)
    ..line(x - 3, y, x + 1, y - 1)
    ..line(x + 1, y - 1, x - 1, y + 4);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 4, y - 7))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 4, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 6))
    ..color(CompanionNode.body, 'bgLight')
    ..color(CompanionNode.trail, 'weatherLightning');
}

void _flameOrb(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 9, 5, 5);
  p[CompanionNode.head].fillTriangle(
    (x: x - 5, y: y - 10),
    (x: x + 5, y: y - 10),
    (x: x + side * 2, y: y - 20),
  );
  p[CompanionNode.eyes]
    ..set(x - 2, y - 10)
    ..set(x + 2, y - 10);
  p[CompanionNode.mouth].set(x, y - 7);
  p[CompanionNode.leftArm].line(x - 4, y - 8, x - 8, y - 5);
  p[CompanionNode.rightArm].line(x + 4, y - 8, x + 8, y - 5);
  p[CompanionNode.trail]
    ..set(x - 3, y - 3)
    ..set(x, y - 1)
    ..set(x + 3, y - 3);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 11), parentNode: CompanionNode.body)
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 4, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 4, y - 8))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 4))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _blackHole(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x, y - 10, 8, 5)
    ..fillEllipse(x, y - 10, 5, 8);
  p[CompanionNode.head].fillEllipse(x, y - 10, 4, 4);
  p[CompanionNode.trail]
    ..line(x - 10, y - 10, x + 10, y - 10)
    ..line(x, y - 20, x, y)
    ..set(x - side * 11, y - 7)
    ..set(x + side * 11, y - 13);
  p[CompanionNode.leftTentacle]
    ..line(x - 5, y - 13, x - 11, y - 17)
    ..set(x - 12, y - 18);
  p[CompanionNode.rightTentacle]
    ..line(x + 5, y - 7, x + 11, y - 3)
    ..set(x + 12, y - 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10), parentNode: CompanionNode.body)
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 5, y - 13))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 5, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 10))
    ..color(CompanionNode.body, 'bgDark')
    ..color(CompanionNode.head, 'outline')
    ..color(CompanionNode.trail, 'fantasyLight');
}

void _slime(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x, y - 7, 7, 7)
    ..fillRect(x - 7, y - 7, 15, 8);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 9)
    ..set(x + 3, y - 9);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 5);
  p[CompanionNode.leftTentacle]
    ..line(x - 5, y - 3, x - 9, y + 2, thickness: 2)
    ..set(x - 10, y + 2);
  p[CompanionNode.rightTentacle]
    ..line(x + 5, y - 3, x + 9, y + 2, thickness: 2)
    ..set(x + 10, y + 2);
  p[CompanionNode.trail].hLine(x - 7, x + 7, y + 1);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 5, y - 3))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 5, y - 3))
    ..anchor(CompanionNode.trail, PixelPoint(x, y))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.leftTentacle, 'fantasyDark')
    ..color(CompanionNode.rightTentacle, 'fantasyDark');
}

void _coffee(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 5, y - 12, 11, 12);
  p[CompanionNode.head].hLine(x - 6, x + 6, y - 12);
  p[CompanionNode.rightArm].fillEllipse(x + 7, y - 7, 3, 4);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 8)
    ..set(x + 2, y - 8);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 5);
  p[CompanionNode.leftArm].line(x - 5, y - 7, x - 9, y - 4);
  p[CompanionNode.leftLeg].line(x - 2, y, x - 4, y + 4);
  p[CompanionNode.rightLeg].line(x + 2, y, x + 4, y + 4);
  p[CompanionNode.trail]
    ..line(x - 2, y - 14, x - 4, y - 19)
    ..line(x + 2, y - 14, x + 4, y - 20);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 12), parentNode: CompanionNode.body)
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 5, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 5, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 13))
    ..color(CompanionNode.body, 'clothAccent')
    ..color(CompanionNode.trail, 'weatherFogLight');
}

void _donut(CompanionRigParts p, int x, int y, int side) {
  final outer = p[CompanionNode.body]..fillEllipse(x, y - 10, 7, 7);
  final hole = p[CompanionNode.shadow]..fillEllipse(x, y - 10, 3, 3);
  outer.data.setAll(0, outer.subtract(hole).data);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 12)
    ..set(x + 3, y - 12);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 7);
  p[CompanionNode.leftArm].line(x - 6, y - 9, x - 10, y - 6);
  p[CompanionNode.rightArm].line(x + 6, y - 9, x + 10, y - 6);
  p[CompanionNode.leftLeg].line(x - 3, y - 4, x - 4, y + 1);
  p[CompanionNode.rightLeg].line(x + 3, y - 4, x + 4, y + 1);
  p
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 6, y - 9))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 6, y - 9))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y - 4))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y - 4))
    ..color(CompanionNode.body, 'mouthBase')
    ..color(CompanionNode.shadow, 'bgDark');
}

void _emojiOrb(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 10, 7, 7);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 3, y - 12, 1, 2)
    ..fillEllipse(x + 3, y - 12, 1, 2);
  p[CompanionNode.mouth]
    ..line(x - 3, y - 7, x, y - 5)
    ..line(x, y - 5, x + 3, y - 7);
  p[CompanionNode.leftArm].line(x - 6, y - 9, x - 10, y - 6);
  p[CompanionNode.rightArm].line(x + 6, y - 9, x + 10, y - 6);
  p[CompanionNode.trail]
    ..set(x - side * 9, y - 7)
    ..set(x - side * 12, y - 10);
  p
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 6, y - 9))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 6, y - 9))
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 7, y - 8))
    ..color(CompanionNode.body, 'clothLight')
    ..color(CompanionNode.eyes, 'mouthDark');
}

void _catCloud(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x - 3, y - 8, 5, 4)
    ..fillEllipse(x + 3, y - 8, 5, 4)
    ..fillRect(x - 7, y - 8, 15, 5);
  p[CompanionNode.head].fillEllipse(x + side * 2, y - 13, 4, 4);
  p[CompanionNode.leftEar].fillTriangle(
    (x: x - 2, y: y - 15),
    (x: x, y: y - 14),
    (x: x - 1, y: y - 18),
  );
  p[CompanionNode.rightEar].fillTriangle(
    (x: x + 3, y: y - 14),
    (x: x + 5, y: y - 15),
    (x: x + 4, y: y - 18),
  );
  p[CompanionNode.eyes]
    ..set(x + side, y - 14)
    ..set(x + side * 3, y - 14);
  p[CompanionNode.tail]
    ..line(x - side * 5, y - 7, x - side * 10, y - 10, thickness: 2)
    ..line(x - side * 10, y - 10, x - side * 8, y - 14, thickness: 2);
  p[CompanionNode.trail]
    ..set(x - 5, y - 3)
    ..set(x, y - 2)
    ..set(x + 5, y - 3);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side, y - 10))
    ..anchor(CompanionNode.leftEar, PixelPoint(x - 1, y - 15))
    ..anchor(CompanionNode.rightEar, PixelPoint(x + 4, y - 15))
    ..anchor(CompanionNode.tail, PixelPoint(x - side * 5, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 4))
    ..color(CompanionNode.body, 'bgLight')
    ..color(CompanionNode.head, 'clothDark')
    ..color(CompanionNode.tail, 'clothDark');
}
