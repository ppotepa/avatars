import '../../geometry/point.dart';
import 'companion_rig_v2_model.dart';

CompanionStyleSpec? naturalFantasyCompanionStyle(String id) => switch (id) {
      'parrot' || 'owl' || 'crow' || 'raven' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.bird,
          paint: _bird,
          speaks: true,
        ),
      'bat' => const CompanionStyleSpec(
          id: 'bat',
          profile: CompanionMotionProfile.bird,
          paint: _bat,
          speaks: true,
        ),
      'cat' || 'raccoon' || 'rat' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.quadruped,
          paint: _smallMammal,
          speaks: true,
        ),
      'frog' => const CompanionStyleSpec(
          id: 'frog',
          profile: CompanionMotionProfile.quadruped,
          paint: _frog,
          speaks: true,
        ),
      'snake' => const CompanionStyleSpec(
          id: 'snake',
          profile: CompanionMotionProfile.tentacled,
          paint: _snake,
          speaks: true,
        ),
      'chameleon' || 'gecko' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.quadruped,
          paint: _lizard,
          speaks: true,
        ),
      'octopus' => const CompanionStyleSpec(
          id: 'octopus',
          profile: CompanionMotionProfile.tentacled,
          paint: _octopus,
          speaks: true,
        ),
      'snail' => const CompanionStyleSpec(
          id: 'snail',
          profile: CompanionMotionProfile.quadruped,
          paint: _snail,
        ),
      'insect' => const CompanionStyleSpec(
          id: 'insect',
          profile: CompanionMotionProfile.bird,
          paint: _insect,
          floats: true,
        ),
      'smallDragon' => const CompanionStyleSpec(
          id: 'smallDragon',
          profile: CompanionMotionProfile.bird,
          paint: _smallDragon,
          speaks: true,
        ),
      'miniGriffin' => const CompanionStyleSpec(
          id: 'miniGriffin',
          profile: CompanionMotionProfile.bird,
          paint: _griffin,
          speaks: true,
        ),
      'fairy' => const CompanionStyleSpec(
          id: 'fairy',
          profile: CompanionMotionProfile.humanoid,
          paint: _fairy,
          speaks: true,
          floats: true,
        ),
      'mandrake' => const CompanionStyleSpec(
          id: 'mandrake',
          profile: CompanionMotionProfile.humanoid,
          paint: _mandrake,
          speaks: true,
        ),
      'miniGolem' => const CompanionStyleSpec(
          id: 'miniGolem',
          profile: CompanionMotionProfile.humanoid,
          paint: _golem,
        ),
      'miniMimic' => const CompanionStyleSpec(
          id: 'miniMimic',
          profile: CompanionMotionProfile.quadruped,
          paint: _mimic,
          speaks: true,
        ),
      'fireSprite' || 'lanternSpirit' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.floating,
          paint: _fireSprite,
          speaks: true,
          floats: true,
        ),
      'floatingEye' => const CompanionStyleSpec(
          id: 'floatingEye',
          profile: CompanionMotionProfile.floating,
          paint: _floatingEye,
          floats: true,
        ),
      'mushroomBuddy' => const CompanionStyleSpec(
          id: 'mushroomBuddy',
          profile: CompanionMotionProfile.humanoid,
          paint: _mushroom,
          speaks: true,
        ),
      'bookFamiliar' => const CompanionStyleSpec(
          id: 'bookFamiliar',
          profile: CompanionMotionProfile.mechanical,
          paint: _book,
          speaks: true,
          floats: true,
        ),
      'starOrb' => const CompanionStyleSpec(
          id: 'starOrb',
          profile: CompanionMotionProfile.floating,
          paint: _starOrb,
          floats: true,
        ),
      _ => null,
    };

void _bird(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 6, 4, 6);
  p[CompanionNode.head].fillEllipse(x - side, y - 13, 3, 3);
  p[CompanionNode.leftWing]
    ..fillEllipse(x - 3, y - 7, 3, 4)
    ..line(x - 2, y - 9, x - 7, y - 5);
  p[CompanionNode.rightWing]
    ..fillEllipse(x + 3, y - 7, 3, 4)
    ..line(x + 2, y - 9, x + 7, y - 5);
  p[CompanionNode.tail]
    ..line(x - 1, y - 1, x - 3, y + 6, thickness: 2)
    ..line(x + 1, y - 1, x + 3, y + 6, thickness: 2);
  p[CompanionNode.beak].fillTriangle(
    (x: x - side * 3, y: y - 14),
    (x: x - side * 7, y: y - 12),
    (x: x - side * 3, y: y - 11),
  );
  p[CompanionNode.eyes].set(x - side * 2, y - 14);
  p[CompanionNode.leftLeg]
    ..line(x - 2, y - 1, x - 3, y + 2)
    ..hLine(x - 4, x - 2, y + 2);
  p[CompanionNode.rightLeg]
    ..line(x + 2, y - 1, x + 3, y + 2)
    ..hLine(x + 2, x + 4, y + 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x - side, y - 10))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 2, y - 9))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 2, y - 9))
    ..anchor(CompanionNode.tail, PixelPoint(x, y - 1))
    ..anchor(CompanionNode.beak, PixelPoint(x - side * 3, y - 13), parentNode: CompanionNode.head)
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y - 1))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y - 1));
}

void _bat(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 7, 3, 5);
  p[CompanionNode.head].fillEllipse(x, y - 13, 3, 3);
  p[CompanionNode.leftEar].fillTriangle(
    (x: x - 3, y: y - 15),
    (x: x - 1, y: y - 14),
    (x: x - 3, y: y - 18),
  );
  p[CompanionNode.rightEar].fillTriangle(
    (x: x + 1, y: y - 14),
    (x: x + 3, y: y - 15),
    (x: x + 3, y: y - 18),
  );
  p[CompanionNode.leftWing].fillTriangle(
    (x: x - 2, y: y - 10),
    (x: x - 12, y: y - 14),
    (x: x - 6, y: y - 2),
  );
  p[CompanionNode.rightWing].fillTriangle(
    (x: x + 2, y: y - 10),
    (x: x + 12, y: y - 14),
    (x: x + 6, y: y - 2),
  );
  p[CompanionNode.eyes]
    ..set(x - 1, y - 14)
    ..set(x + 1, y - 14);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 2, y - 10))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 2, y - 10))
    ..anchor(CompanionNode.leftEar, PixelPoint(x - 2, y - 15))
    ..anchor(CompanionNode.rightEar, PixelPoint(x + 2, y - 15));
}

void _smallMammal(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 5, 6, 5);
  p[CompanionNode.head].fillEllipse(x + side * 3, y - 11, 4, 4);
  p[CompanionNode.leftEar].fillTriangle(
    (x: x + side - 3, y: y - 14),
    (x: x + side, y: y - 13),
    (x: x + side - 2, y: y - 17),
  );
  p[CompanionNode.rightEar].fillTriangle(
    (x: x + side * 4, y: y - 13),
    (x: x + side * 6, y: y - 14),
    (x: x + side * 5, y: y - 17),
  );
  p[CompanionNode.eyes].set(x + side * 4, y - 12);
  p[CompanionNode.mouth].set(x + side * 7, y - 9);
  p[CompanionNode.leftLeg].fillRect(x - 4, y - 1, 3, 3);
  p[CompanionNode.rightLeg].fillRect(x + 2, y - 1, 3, 3);
  p[CompanionNode.tail]
    ..line(x - side * 5, y - 5, x - side * 10, y - 9, thickness: 2)
    ..line(x - side * 10, y - 9, x - side * 8, y - 14, thickness: 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 2, y - 8))
    ..anchor(CompanionNode.leftEar, PixelPoint(x + side, y - 14))
    ..anchor(CompanionNode.rightEar, PixelPoint(x + side * 5, y - 14))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y - 2))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y - 2))
    ..anchor(CompanionNode.tail, PixelPoint(x - side * 5, y - 5));
}

void _frog(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 5, 6, 4);
  p[CompanionNode.head].fillEllipse(x, y - 10, 6, 4);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 3, y - 13, 2, 2)
    ..fillEllipse(x + 3, y - 13, 2, 2)
    ..set(x - 3, y - 13)
    ..set(x + 3, y - 13);
  p[CompanionNode.mouth].hLine(x - 3, x + 3, y - 8);
  p[CompanionNode.leftLeg]
    ..line(x - 4, y - 3, x - 9, y + 2, thickness: 2)
    ..hLine(x - 10, x - 6, y + 2);
  p[CompanionNode.rightLeg]
    ..line(x + 4, y - 3, x + 9, y + 2, thickness: 2)
    ..hLine(x + 6, x + 10, y + 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 4, y - 3))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 4, y - 3))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyBase');
}

void _snake(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..line(x, y, x + side * 5, y - 7, thickness: 2)
    ..line(x + side * 5, y - 7, x - side * 2, y - 14, thickness: 2);
  p[CompanionNode.head].fillEllipse(x - side * 2, y - 16, 4, 2);
  p[CompanionNode.eyes].set(x - side * 3, y - 17);
  p[CompanionNode.mouth].line(x - side * 5, y - 16, x - side * 8, y - 16);
  p[CompanionNode.tail].line(x, y, x - side * 4, y + 3);
  p
    ..anchor(CompanionNode.head, PixelPoint(x - side * 1, y - 14))
    ..anchor(CompanionNode.tail, PixelPoint(x, y));
}

void _lizard(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 6, 7, 4);
  p[CompanionNode.head].fillEllipse(x + side * 7, y - 8, 4, 3);
  p[CompanionNode.eyes].fillEllipse(x + side * 8, y - 9, 1, 1);
  p[CompanionNode.mouth].line(x + side * 10, y - 7, x + side * 13, y - 7);
  p[CompanionNode.leftLeg]
    ..line(x - 3, y - 4, x - 7, y)
    ..hLine(x - 8, x - 5, y);
  p[CompanionNode.rightLeg]
    ..line(x + 3, y - 4, x + 7, y)
    ..hLine(x + 5, x + 8, y);
  p[CompanionNode.tail]
    ..line(x - side * 6, y - 6, x - side * 12, y - 3, thickness: 2)
    ..line(x - side * 12, y - 3, x - side * 14, y - 7);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 5, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y - 4))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y - 4))
    ..anchor(CompanionNode.tail, PixelPoint(x - side * 6, y - 6))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyBase');
}

void _octopus(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.head].fillEllipse(x, y - 11, 6, 5);
  p[CompanionNode.body].fillRect(x - 5, y - 11, 11, 6);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 12)
    ..set(x + 2, y - 12);
  p[CompanionNode.leftTentacle]
    ..line(x - 4, y - 6, x - 9, y + 2, thickness: 2)
    ..line(x - 1, y - 6, x - 4, y + 4);
  p[CompanionNode.rightTentacle]
    ..line(x + 4, y - 6, x + 9, y + 2, thickness: 2)
    ..line(x + 1, y - 6, x + 4, y + 4);
  p[CompanionNode.leftArm].line(x - 3, y - 7, x - 8, y - 5);
  p[CompanionNode.rightArm].line(x + 3, y - 7, x + 8, y - 5);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 4, y - 6))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 4, y - 6))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 3, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 3, y - 7))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyBase');
}

void _snail(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x - side * 2, y - 6, 6, 6);
  p[CompanionNode.head].fillEllipse(x + side * 5, y - 5, 3, 3);
  p[CompanionNode.leftAntenna]
    ..line(x + side * 4, y - 7, x + side * 3, y - 11)
    ..set(x + side * 3, y - 12);
  p[CompanionNode.rightAntenna]
    ..line(x + side * 6, y - 7, x + side * 8, y - 11)
    ..set(x + side * 8, y - 12);
  p[CompanionNode.eyes]
    ..set(x + side * 3, y - 12)
    ..set(x + side * 8, y - 12);
  p[CompanionNode.trail].hLine(x - side * 8, x + side * 8, y);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 3, y - 5))
    ..anchor(CompanionNode.leftAntenna, PixelPoint(x + side * 4, y - 7))
    ..anchor(CompanionNode.rightAntenna, PixelPoint(x + side * 6, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y));
}

void _insect(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 7, 2, 4);
  p[CompanionNode.head].fillEllipse(x, y - 12, 2, 2);
  p[CompanionNode.leftWing].fillEllipse(x - 4, y - 8, 4, 2);
  p[CompanionNode.rightWing].fillEllipse(x + 4, y - 8, 4, 2);
  p[CompanionNode.leftAntenna].line(x - 1, y - 13, x - 4, y - 17);
  p[CompanionNode.rightAntenna].line(x + 1, y - 13, x + 4, y - 17);
  p[CompanionNode.eyes].set(x, y - 13);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 1, y - 9))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 1, y - 9))
    ..anchor(CompanionNode.leftAntenna, PixelPoint(x - 1, y - 13))
    ..anchor(CompanionNode.rightAntenna, PixelPoint(x + 1, y - 13));
}

void _smallDragon(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 6, 5, 6);
  p[CompanionNode.head].fillEllipse(x + side * 3, y - 14, 4, 3);
  p[CompanionNode.leftWing].fillTriangle(
    (x: x - 2, y: y - 10),
    (x: x - 12, y: y - 16),
    (x: x - 7, y: y - 3),
  );
  p[CompanionNode.rightWing].fillTriangle(
    (x: x + 2, y: y - 10),
    (x: x + 12, y: y - 16),
    (x: x + 7, y: y - 3),
  );
  p[CompanionNode.tail]
    ..line(x - side * 4, y - 3, x - side * 10, y + 5, thickness: 2)
    ..fillTriangle(
      (x: x - side * 10, y: y + 5),
      (x: x - side * 13, y: y + 2),
      (x: x - side * 12, y: y + 7),
    );
  p[CompanionNode.leftEar].fillTriangle(
    (x: x + side, y: y - 16),
    (x: x + side * 3, y: y - 16),
    (x: x + side * 2, y: y - 20),
  );
  p[CompanionNode.eyes].set(x + side * 4, y - 15);
  p[CompanionNode.mouth].line(x + side * 6, y - 13, x + side * 9, y - 12);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 2, y - 11))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 2, y - 10))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 2, y - 10))
    ..anchor(CompanionNode.tail, PixelPoint(x - side * 4, y - 3));
}

void _griffin(CompanionRigParts p, int x, int y, int side) {
  _bird(p, x, y, side);
  p[CompanionNode.leftLeg]
    ..line(x - 2, y - 2, x - 5, y + 3, thickness: 2)
    ..hLine(x - 7, x - 3, y + 3);
  p[CompanionNode.rightLeg]
    ..line(x + 2, y - 2, x + 5, y + 3, thickness: 2)
    ..hLine(x + 3, x + 7, y + 3);
  p[CompanionNode.tail]
    ..line(x - side * 3, y - 2, x - side * 9, y + 4, thickness: 2)
    ..fillEllipse(x - side * 10, y + 4, 2, 2);
  p.color(CompanionNode.body, 'clothLight');
}

void _fairy(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 2, y - 9, 5, 9);
  p[CompanionNode.head].fillEllipse(x, y - 14, 3, 3);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 15)
    ..set(x + 1, y - 15);
  p[CompanionNode.leftWing].fillEllipse(x - 5, y - 10, 4, 5);
  p[CompanionNode.rightWing].fillEllipse(x + 5, y - 10, 4, 5);
  p[CompanionNode.leftArm].line(x - 2, y - 7, x - 6, y - 4);
  p[CompanionNode.rightArm].line(x + 2, y - 7, x + 6, y - 4);
  p[CompanionNode.leftLeg].line(x - 1, y, x - 3, y + 5);
  p[CompanionNode.rightLeg].line(x + 1, y, x + 3, y + 5);
  p[CompanionNode.trail]
    ..set(x - side * 6, y - 4)
    ..set(x - side * 9, y - 7)
    ..set(x - side * 11, y - 3);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 11))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 2, y - 10))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 2, y - 10))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 2, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 2, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 1, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 1, y))
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 4, y - 5));
}

void _mandrake(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 6, 5, 7);
  p[CompanionNode.head].fillEllipse(x, y - 12, 4, 4);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 13)
    ..set(x + 2, y - 13);
  p[CompanionNode.mouth].fillEllipse(x, y - 10, 1, 1);
  p[CompanionNode.leftArm].line(x - 4, y - 7, x - 8, y - 3, thickness: 2);
  p[CompanionNode.rightArm].line(x + 4, y - 7, x + 8, y - 3, thickness: 2);
  p[CompanionNode.leftLeg].line(x - 2, y, x - 5, y + 5, thickness: 2);
  p[CompanionNode.rightLeg].line(x + 2, y, x + 5, y + 5, thickness: 2);
  p[CompanionNode.leftAntenna]
    ..line(x - 2, y - 15, x - 5, y - 20)
    ..fillEllipse(x - 5, y - 21, 2, 2);
  p[CompanionNode.rightAntenna]
    ..line(x + 2, y - 15, x + 5, y - 20)
    ..fillEllipse(x + 5, y - 21, 2, 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 9))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 4, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 4, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y))
    ..anchor(CompanionNode.leftAntenna, PixelPoint(x - 2, y - 15))
    ..anchor(CompanionNode.rightAntenna, PixelPoint(x + 2, y - 15))
    ..color(CompanionNode.body, 'clothAccent')
    ..color(CompanionNode.head, 'clothAccent');
}

void _golem(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillRect(x - 5, y - 10, 11, 11)
    ..fillRect(x - 6, y - 7, 13, 6);
  p[CompanionNode.head].fillRect(x - 4, y - 16, 9, 6);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 14)
    ..set(x + 2, y - 14);
  p[CompanionNode.leftArm].fillRect(x - 10, y - 9, 5, 9);
  p[CompanionNode.rightArm].fillRect(x + 6, y - 9, 5, 9);
  p[CompanionNode.leftLeg].fillRect(x - 4, y, 4, 5);
  p[CompanionNode.rightLeg].fillRect(x + 1, y, 4, 5);
  p[CompanionNode.light]
    ..line(x, y - 9, x - 2, y - 5)
    ..line(x - 2, y - 5, x + 1, y - 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 5, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 5, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothDark')
    ..color(CompanionNode.light, 'fantasyLight');
}

void _mimic(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 7, y - 10, 15, 11);
  p[CompanionNode.head]
    ..fillRect(x - 7, y - 15, 15, 5)
    ..hLine(x - 8, x + 8, y - 10);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 13)
    ..set(x + 3, y - 13);
  p[CompanionNode.mouth]
    ..hLine(x - 6, x + 6, y - 9)
    ..set(x - 4, y - 8)
    ..set(x, y - 8)
    ..set(x + 4, y - 8);
  p[CompanionNode.leftLeg].line(x - 4, y, x - 7, y + 4, thickness: 2);
  p[CompanionNode.rightLeg].line(x + 4, y, x + 7, y + 4, thickness: 2);
  p[CompanionNode.tail].line(x + side * 6, y - 6, x + side * 11, y - 3, thickness: 2);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 4, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 4, y))
    ..anchor(CompanionNode.tail, PixelPoint(x + side * 6, y - 6));
}

void _fireSprite(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillTriangle(
    (x: x - 5, y: y),
    (x: x + 5, y: y),
    (x: x + side, y: y - 16),
  );
  p[CompanionNode.head].fillEllipse(x, y - 9, 4, 4);
  p[CompanionNode.eyes]
    ..set(x - 1, y - 10)
    ..set(x + 1, y - 10);
  p[CompanionNode.leftArm].line(x - 3, y - 7, x - 7, y - 4);
  p[CompanionNode.rightArm].line(x + 3, y - 7, x + 7, y - 4);
  p[CompanionNode.trail]
    ..set(x - 4, y + 1)
    ..set(x, y + 2)
    ..set(x + 4, y + 1);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 6))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 3, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 3, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _floatingEye(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 10, 8, 5);
  p[CompanionNode.eyes]
    ..fillEllipse(x, y - 10, 4, 4)
    ..fillEllipse(x + side, y - 10, 2, 2)
    ..set(x + side * 2, y - 10);
  p[CompanionNode.leftTentacle].line(x - 5, y - 7, x - 10, y - 2);
  p[CompanionNode.rightTentacle].line(x + 5, y - 7, x + 10, y - 2);
  p[CompanionNode.trail]
    ..set(x - 4, y - 4)
    ..set(x, y - 2)
    ..set(x + 4, y - 4);
  p
    ..anchor(CompanionNode.leftTentacle, PixelPoint(x - 5, y - 7))
    ..anchor(CompanionNode.rightTentacle, PixelPoint(x + 5, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 5))
    ..color(CompanionNode.body, 'white')
    ..color(CompanionNode.eyes, 'fantasyBase')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _mushroom(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 3, y - 8, 7, 9);
  p[CompanionNode.head].fillEllipse(x, y - 12, 8, 4);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 6)
    ..set(x + 2, y - 6);
  p[CompanionNode.mouth].set(x, y - 4);
  p[CompanionNode.leftArm].line(x - 3, y - 5, x - 7, y - 2);
  p[CompanionNode.rightArm].line(x + 3, y - 5, x + 7, y - 2);
  p[CompanionNode.leftLeg].line(x - 2, y, x - 4, y + 4);
  p[CompanionNode.rightLeg].line(x + 2, y, x + 4, y + 4);
  p[CompanionNode.trail]
    ..set(x - 7, y - 14)
    ..set(x + 7, y - 13);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 8))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 3, y - 5))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 3, y - 5))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 12));
}

void _book(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillRect(x - 8, y - 12, 7, 12)
    ..fillRect(x + 2, y - 12, 7, 12)
    ..vLine(x, y - 12, y);
  p[CompanionNode.eyes]
    ..set(x - 4, y - 8)
    ..set(x + 4, y - 8);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 4);
  p[CompanionNode.leftWing].line(x - 8, y - 10, x - 12, y - 6);
  p[CompanionNode.rightWing].line(x + 8, y - 10, x + 12, y - 6);
  p[CompanionNode.trail]
    ..set(x - side * 10, y - 2)
    ..set(x - side * 13, y - 5);
  p
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 8, y - 10))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 8, y - 10))
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 8, y - 3))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _starOrb(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 10, 5, 5);
  p[CompanionNode.light]
    ..line(x, y - 18, x, y - 2)
    ..line(x - 8, y - 10, x + 8, y - 10)
    ..line(x - 5, y - 15, x + 5, y - 5)
    ..line(x + 5, y - 15, x - 5, y - 5);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 11)
    ..set(x + 2, y - 11);
  p[CompanionNode.trail]
    ..set(x - side * 7, y - 7)
    ..set(x - side * 10, y - 4)
    ..set(x - side * 12, y - 9);
  p
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 5, y - 7))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.light, 'fantasyLight');
}
