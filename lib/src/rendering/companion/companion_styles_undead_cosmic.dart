import '../../geometry/point.dart';
import 'companion_rig_v2_model.dart';

CompanionStyleSpec? undeadCosmicCompanionStyle(String id) => switch (id) {
      'ghost' || 'sheetGhost' || 'cloudSpirit' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.floating,
          paint: _ghost,
          speaks: true,
          floats: true,
        ),
      'miniSkeleton' => const CompanionStyleSpec(
          id: 'miniSkeleton',
          profile: CompanionMotionProfile.humanoid,
          paint: _skeleton,
          speaks: true,
        ),
      'skullHands' || 'floatingSkull' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.floating,
          paint: _skullHands,
          speaks: true,
          floats: true,
        ),
      'miniReaper' => const CompanionStyleSpec(
          id: 'miniReaper',
          profile: CompanionMotionProfile.humanoid,
          paint: _reaper,
          speaks: true,
        ),
      'zombieHead' => const CompanionStyleSpec(
          id: 'zombieHead',
          profile: CompanionMotionProfile.floating,
          paint: _zombieHead,
          speaks: true,
          floats: true,
        ),
      'vampireBat' => const CompanionStyleSpec(
          id: 'vampireBat',
          profile: CompanionMotionProfile.bird,
          paint: _vampireBat,
          speaks: true,
        ),
      'greyAlien' => const CompanionStyleSpec(
          id: 'greyAlien',
          profile: CompanionMotionProfile.humanoid,
          paint: _greyAlien,
          speaks: true,
        ),
      'alienBlob' => const CompanionStyleSpec(
          id: 'alienBlob',
          profile: CompanionMotionProfile.slime,
          paint: _alienBlob,
          speaks: true,
        ),
      'miniUfo' => const CompanionStyleSpec(
          id: 'miniUfo',
          profile: CompanionMotionProfile.mechanical,
          paint: _miniUfo,
          floats: true,
        ),
      'cosmicParasite' => const CompanionStyleSpec(
          id: 'cosmicParasite',
          profile: CompanionMotionProfile.tentacled,
          paint: _cosmicParasite,
          speaks: true,
        ),
      'miniAstronaut' => const CompanionStyleSpec(
          id: 'miniAstronaut',
          profile: CompanionMotionProfile.humanoid,
          paint: _miniAstronaut,
          speaks: true,
          floats: true,
        ),
      'cosmicJellyfish' => const CompanionStyleSpec(
          id: 'cosmicJellyfish',
          profile: CompanionMotionProfile.tentacled,
          paint: _cosmicJellyfish,
          floats: true,
        ),
      _ => null,
    };

void _ghost(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x, y - 10, 5, 5)
    ..fillRect(x - 5, y - 10, 11, 7);
  p[CompanionNode.head].fillEllipse(x, y - 12, 5, 4);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 13)
    ..set(x + 2, y - 13);
  p[CompanionNode.mouth].hLine(x - 1, x + 1, y - 10);
  for (var offset = -4; offset <= 4; offset += 2) {
    p[CompanionNode.trail].fillTriangle(
      (x: x + offset - 1, y: y - 5),
      (x: x + offset + 1, y: y - 5),
      (x: x + offset, y: y + 1),
    );
  }
  p[CompanionNode.leftArm].line(x - 4, y - 9, x - 7, y - 7);
  p[CompanionNode.rightArm].line(x + 4, y - 9, x + 7, y - 7);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 8))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 4, y - 9))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 4, y - 9))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 5));
  p
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.trail, 'fantasyDark')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _skeleton(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 14, 4, 4);
  p[CompanionNode.eyes]
    ..fillRect(x - 3, y - 15, 2, 2)
    ..fillRect(x + 2, y - 15, 2, 2);
  p[CompanionNode.mouth]
    ..hLine(x - 2, x + 2, y - 11)
    ..vLine(x, y - 12, y - 10);
  p[CompanionNode.body]
    ..vLine(x, y - 10, y - 3)
    ..hLine(x - 3, x + 3, y - 8)
    ..hLine(x - 2, x + 2, y - 6);
  p[CompanionNode.leftArm]
    ..line(x - 3, y - 8, x - 7, y - 4)
    ..set(x - 8, y - 3);
  p[CompanionNode.rightArm]
    ..line(x + 3, y - 8, x + 7, y - 5)
    ..set(x + 8, y - 4);
  p[CompanionNode.leftLeg].line(x - 1, y - 3, x - 4, y + 2);
  p[CompanionNode.rightLeg].line(x + 1, y - 3, x + 4, y + 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 3, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 3, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 1, y - 3))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 1, y - 3));
  for (final node in <String>[
    CompanionNode.body,
    CompanionNode.head,
    CompanionNode.leftArm,
    CompanionNode.rightArm,
    CompanionNode.leftLeg,
    CompanionNode.rightLeg,
  ]) {
    p.color(node, 'white');
  }
  p.color(CompanionNode.eyes, 'mouthDark');
}

void _skullHands(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 12, 5, 5);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 2, y - 13, 1, 1)
    ..fillEllipse(x + 2, y - 13, 1, 1);
  p[CompanionNode.mouth]
    ..hLine(x - 3, x + 3, y - 9)
    ..set(x - 1, y - 8)
    ..set(x + 1, y - 8);
  p[CompanionNode.leftArm]
    ..line(x - 4, y - 11, x - 8, y - 7)
    ..hLine(x - 9, x - 6, y - 6);
  p[CompanionNode.rightArm]
    ..line(x + 4, y - 11, x + 8, y - 7)
    ..hLine(x + 6, x + 9, y - 6);
  p[CompanionNode.trail]
    ..set(x, y - 6)
    ..set(x + side, y - 4)
    ..set(x - side, y - 2);
  p
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 4, y - 11), parentNode: CompanionNode.head)
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 4, y - 11), parentNode: CompanionNode.head)
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 7), parentNode: CompanionNode.head);
  p
    ..color(CompanionNode.head, 'white')
    ..color(CompanionNode.leftArm, 'white')
    ..color(CompanionNode.rightArm, 'white')
    ..color(CompanionNode.eyes, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _reaper(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillTriangle(
    (x: x - 5, y: y),
    (x: x + 5, y: y),
    (x: x, y: y - 14),
  );
  p[CompanionNode.head].fillEllipse(x, y - 13, 4, 4);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 14)
    ..set(x + 1, y - 14);
  p[CompanionNode.rightArm].line(x + 2, y - 9, x + side * 7, y - 7);
  p[CompanionNode.heldItem]
    ..line(x + side * 7, y - 14, x + side * 7, y)
    ..line(x + side * 7, y - 14, x + side * 2, y - 17)
    ..line(x + side * 2, y - 17, x - side, y - 16);
  p[CompanionNode.trail]
    ..set(x - 3, y + 1)
    ..set(x, y + 2)
    ..set(x + 3, y + 1);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 2, y - 9))
    ..anchor(CompanionNode.heldItem, PixelPoint(x + side * 7, y - 7), parentNode: CompanionNode.rightArm)
    ..anchor(CompanionNode.trail, PixelPoint(x, y));
  p
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'mouthDark')
    ..color(CompanionNode.eyes, 'fantasyLight')
    ..color(CompanionNode.heldItem, 'white');
}

void _zombieHead(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 11, 6, 5);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 13)
    ..fillEllipse(x + 3, y - 12, 1, 1);
  p[CompanionNode.mouth]
    ..line(x - 3, y - 8, x + 3, y - 7)
    ..set(x + side * 4, y - 6);
  p[CompanionNode.trail]
    ..line(x - 4, y - 6, x - 2, y - 2)
    ..line(x + 4, y - 6, x + 2, y - 1);
  p
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 6), parentNode: CompanionNode.head)
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.eyes, 'fantasyLight')
    ..color(CompanionNode.mouth, 'mouthDark');
}

void _vampireBat(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 7, 3, 5);
  p[CompanionNode.head].fillEllipse(x, y - 13, 3, 3);
  p[CompanionNode.leftEar].fillTriangle(
    (x: x - 3, y: y - 15),
    (x: x - 1, y: y - 14),
    (x: x - 3, y: y - 19),
  );
  p[CompanionNode.rightEar].fillTriangle(
    (x: x + 1, y: y - 14),
    (x: x + 3, y: y - 15),
    (x: x + 3, y: y - 19),
  );
  p[CompanionNode.leftWing]
    ..fillTriangle(
      (x: x - 2, y: y - 10),
      (x: x - 12, y: y - 15),
      (x: x - 7, y: y - 3),
    )
    ..line(x - 2, y - 10, x - 9, y - 9);
  p[CompanionNode.rightWing]
    ..fillTriangle(
      (x: x + 2, y: y - 10),
      (x: x + 12, y: y - 15),
      (x: x + 7, y: y - 3),
    )
    ..line(x + 2, y - 10, x + 9, y - 9);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 14)
    ..set(x + 1, y - 14);
  p[CompanionNode.mouth]
    ..set(x - 1, y - 11)
    ..set(x + 1, y - 11);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 2, y - 10))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 2, y - 10))
    ..anchor(CompanionNode.leftEar, PixelPoint(x - 2, y - 15))
    ..anchor(CompanionNode.rightEar, PixelPoint(x + 2, y - 15));
  p
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothDark')
    ..color(CompanionNode.leftWing, 'fantasyDark')
    ..color(CompanionNode.rightWing, 'fantasyDark')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _greyAlien(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 5, 3, 6);
  p[CompanionNode.head].fillEllipse(x, y - 14, 6, 5);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 3, y - 15, 2, 2)
    ..fillEllipse(x + 3, y - 15, 2, 2);
  p[CompanionNode.mouth].hLine(x - 1, x + 1, y - 10);
  p[CompanionNode.leftArm].line(x - 2, y - 7, x - 6, y - 2);
  p[CompanionNode.rightArm].line(x + 2, y - 7, x + 6, y - 2);
  p[CompanionNode.leftLeg].line(x - 1, y, x - 3, y + 4);
  p[CompanionNode.rightLeg].line(x + 1, y, x + 3, y + 4);
  p[CompanionNode.leftAntenna]
    ..line(x - 2, y - 18, x - 4, y - 21)
    ..set(x - 4, y - 22);
  p[CompanionNode.rightAntenna]
    ..line(x + 2, y - 18, x + 4, y - 21)
    ..set(x + 4, y - 22);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 9))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 2, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 2, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 1, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 1, y))
    ..anchor(CompanionNode.leftAntenna, PixelPoint(x - 2, y - 18))
    ..anchor(CompanionNode.rightAntenna, PixelPoint(x + 2, y - 18));
  p
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.eyes, 'mouthDark');
}

void _alienBlob(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x, y - 8, 7, 7)
    ..fillRect(x - 6, y - 8, 13, 8);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 3, y - 10, 1, 2)
    ..fillEllipse(x + 3, y - 10, 1, 2);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 5);
  p[CompanionNode.leftTentacle]
    ..line(x - 4, y - 3, x - 8, y + 3, thickness: 2)
    ..set(x - 9, y + 3);
  p[CompanionNode.rightTentacle]
    ..line(x + 4, y - 3, x + 8, y + 3, thickness: 2)
    ..set(x + 9, y + 3);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 4, y - 3))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 4, y - 3))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.leftTentacle, 'fantasyDark')
    ..color(CompanionNode.rightTentacle, 'fantasyDark');
}

void _miniUfo(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 13, 4, 3);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 14)
    ..set(x + 1, y - 14);
  p[CompanionNode.body]
    ..fillEllipse(x, y - 8, 8, 3)
    ..hLine(x - 9, x + 9, y - 8);
  p[CompanionNode.light]
    ..hLine(x - 5, x + 5, y - 6)
    ..set(x - 7, y - 8)
    ..set(x + 7, y - 8);
  p[CompanionNode.trail].fillTriangle(
    (x: x - 5, y: y - 5),
    (x: x + 5, y: y - 5),
    (x: x, y: y + 3),
  );
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 5))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.light, 'fantasyLight');
}

void _cosmicParasite(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 8, 5, 6);
  p[CompanionNode.head].fillEllipse(x + side * 2, y - 13, 4, 3);
  p[CompanionNode.eyes]
    ..set(x + side, y - 14)
    ..set(x + side * 3, y - 13)
    ..set(x - side, y - 12);
  p[CompanionNode.leftTentacle]
    ..line(x - 3, y - 5, x - 9, y + 1, thickness: 2)
    ..line(x - 9, y + 1, x - 7, y + 4);
  p[CompanionNode.rightTentacle]
    ..line(x + 3, y - 5, x + 9, y + 1, thickness: 2)
    ..line(x + 9, y + 1, x + 7, y + 4);
  p[CompanionNode.tail].line(x - side * 3, y - 4, x - side * 10, y - 9, thickness: 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side, y - 10))
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 3, y - 5))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 3, y - 5))
    ..anchor(CompanionNode.tail, PixelPoint(x - side * 3, y - 4))
    ..color(CompanionNode.body, 'fantasyDark')
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _miniAstronaut(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head]
    ..fillEllipse(x, y - 14, 5, 5)
    ..fillEllipse(x, y - 14, 3, 3);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 14)
    ..set(x + 1, y - 14);
  p[CompanionNode.body].fillRect(x - 4, y - 9, 9, 9);
  p[CompanionNode.leftArm].line(x - 4, y - 8, x - 8, y - 4, thickness: 2);
  p[CompanionNode.rightArm].line(x + 4, y - 8, x + 8, y - 5, thickness: 2);
  p[CompanionNode.leftLeg].line(x - 2, y, x - 4, y + 5, thickness: 2);
  p[CompanionNode.rightLeg].line(x + 2, y, x + 4, y + 5, thickness: 2);
  p[CompanionNode.heldItem]
    ..fillRect(x + side * 7, y - 7, 3, 4)
    ..set(x + side * 8, y - 8);
  p[CompanionNode.trail]
    ..set(x - 3, y + 4)
    ..set(x + 3, y + 4);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 9))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 4, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 4, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y))
    ..anchor(CompanionNode.heldItem, PixelPoint(x + side * 7, y - 5), parentNode: side > 0 ? CompanionNode.rightArm : CompanionNode.leftArm)
    ..color(CompanionNode.body, 'white')
    ..color(CompanionNode.head, 'white')
    ..color(CompanionNode.eyes, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyLight');
}

void _cosmicJellyfish(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 13, 7, 5);
  p[CompanionNode.body].fillRect(x - 6, y - 13, 13, 5);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 13)
    ..set(x + 2, y - 13);
  p[CompanionNode.leftTentacle]
    ..line(x - 4, y - 8, x - 6, y + 2)
    ..line(x - 6, y + 2, x - 3, y + 5);
  p[CompanionNode.rightTentacle]
    ..line(x + 4, y - 8, x + 6, y + 2)
    ..line(x + 6, y + 2, x + 3, y + 5);
  p[CompanionNode.trail]
    ..line(x - 1, y - 8, x - 2, y + 6)
    ..line(x + 1, y - 8, x + 2, y + 6);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 4, y - 8), parentNode: CompanionNode.head)
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 4, y - 8), parentNode: CompanionNode.head)
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 8), parentNode: CompanionNode.head)
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.leftTentacle, 'fantasyLight')
    ..color(CompanionNode.rightTentacle, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyDark');
}
