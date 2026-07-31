import '../../geometry/point.dart';
import 'companion_rig_v2_model.dart';

CompanionStyleSpec? arcadeTechCompanionStyle(String id) => switch (id) {
      'arcadeChomper' => const CompanionStyleSpec(
          id: 'arcadeChomper',
          profile: CompanionMotionProfile.arcade,
          paint: _arcadeChomper,
          speaks: true,
          floats: true,
        ),
      'arcadeGhost' => const CompanionStyleSpec(
          id: 'arcadeGhost',
          profile: CompanionMotionProfile.arcade,
          paint: _arcadeGhost,
          floats: true,
        ),
      'joystickBuddy' => const CompanionStyleSpec(
          id: 'joystickBuddy',
          profile: CompanionMotionProfile.mechanical,
          paint: _joystickBuddy,
        ),
      'pixelHeartBuddy' => const CompanionStyleSpec(
          id: 'pixelHeartBuddy',
          profile: CompanionMotionProfile.arcade,
          paint: _pixelHeart,
          floats: true,
        ),
      'arcadeCabinet' => const CompanionStyleSpec(
          id: 'arcadeCabinet',
          profile: CompanionMotionProfile.mechanical,
          paint: _arcadeCabinet,
        ),
      'diceBuddy' => const CompanionStyleSpec(
          id: 'diceBuddy',
          profile: CompanionMotionProfile.arcade,
          paint: _diceBuddy,
          floats: true,
        ),
      'shoulderRobot' || 'serviceBot' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.mechanical,
          paint: _serviceBot,
          speaks: true,
        ),
      'miniDrone' || 'scoutDrone' => CompanionStyleSpec(
          id: id,
          profile: CompanionMotionProfile.mechanical,
          paint: _scoutDrone,
          floats: true,
        ),
      'robotSpider' => const CompanionStyleSpec(
          id: 'robotSpider',
          profile: CompanionMotionProfile.mechanical,
          paint: _robotSpider,
        ),
      'hologramAssistant' => const CompanionStyleSpec(
          id: 'hologramAssistant',
          profile: CompanionMotionProfile.floating,
          paint: _hologramAssistant,
          speaks: true,
          floats: true,
        ),
      'radioBuddy' => const CompanionStyleSpec(
          id: 'radioBuddy',
          profile: CompanionMotionProfile.mechanical,
          paint: _radioBuddy,
          speaks: true,
        ),
      _ => null,
    };

void _arcadeChomper(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 9, 7, 7);
  final mouth = p[CompanionNode.mouth];
  if (side < 0) {
    mouth.fillTriangle(
      (x: x - 7, y: y - 9),
      (x: x, y: y - 13),
      (x: x, y: y - 5),
    );
  } else {
    mouth.fillTriangle(
      (x: x + 7, y: y - 9),
      (x: x, y: y - 13),
      (x: x, y: y - 5),
    );
  }
  p[CompanionNode.eyes].set(x - side * 2, y - 12);
  p[CompanionNode.trail]
    ..set(x - side * 9, y - 9)
    ..set(x - side * 13, y - 9)
    ..set(x - side * 17, y - 9);
  p
    ..anchor(CompanionNode.mouth, PixelPoint(x + side * 2, y - 9), parentNode: CompanionNode.body)
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 7, y - 9))
    ..color(CompanionNode.body, 'clothLight')
    ..color(CompanionNode.mouth, 'bgDark')
    ..color(CompanionNode.trail, 'white');
}

void _arcadeGhost(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillEllipse(x, y - 11, 6, 5)
    ..fillRect(x - 6, y - 11, 13, 8);
  p[CompanionNode.eyes]
    ..fillRect(x - 3, y - 13, 2, 3)
    ..fillRect(x + 2, y - 13, 2, 3)
    ..set(x - 2 + side, y - 12)
    ..set(x + 3 + side, y - 12);
  for (var offset = -5; offset <= 5; offset += 4) {
    p[CompanionNode.trail].fillTriangle(
      (x: x + offset - 2, y: y - 4),
      (x: x + offset + 2, y: y - 4),
      (x: x + offset, y: y + 1),
    );
  }
  p
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 4))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.eyes, 'white')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _joystickBuddy(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillRect(x - 6, y - 6, 13, 7)
    ..hLine(x - 7, x + 7, y + 1);
  p[CompanionNode.head]
    ..vLine(x, y - 13, y - 6)
    ..fillEllipse(x, y - 15, 2, 2);
  p[CompanionNode.leftArm].line(x - 5, y - 4, x - 9, y - 1);
  p[CompanionNode.rightArm].line(x + 5, y - 4, x + 9, y - 1);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 4)
    ..set(x + 2, y - 4);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 6))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 5, y - 4))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 5, y - 4))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothAccent')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _pixelHeart(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillRect(x - 5, y - 14, 4, 4)
    ..fillRect(x + 2, y - 14, 4, 4)
    ..fillRect(x - 7, y - 11, 15, 5)
    ..fillRect(x - 5, y - 6, 11, 3)
    ..fillRect(x - 2, y - 3, 5, 3);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 10)
    ..set(x + 3, y - 10);
  p[CompanionNode.trail]
    ..set(x - side * 9, y - 8)
    ..set(x - side * 12, y - 6);
  p
    ..anchor(CompanionNode.trail, PixelPoint(x - side * 7, y - 8))
    ..color(CompanionNode.body, 'mouthBase')
    ..color(CompanionNode.eyes, 'white')
    ..color(CompanionNode.trail, 'mouthLight');
}

void _arcadeCabinet(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillRect(x - 6, y - 16, 13, 17)
    ..fillRect(x - 7, y - 2, 15, 3);
  p[CompanionNode.head].fillRect(x - 4, y - 13, 9, 6);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 11)
    ..set(x + 2, y - 11);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 8);
  p[CompanionNode.leftArm].line(x - 6, y - 7, x - 10, y - 4);
  p[CompanionNode.rightArm].line(x + 6, y - 7, x + 10, y - 4);
  p[CompanionNode.leftLeg].vLine(x - 3, y + 1, y + 4);
  p[CompanionNode.rightLeg].vLine(x + 3, y + 1, y + 4);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 7))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 6, y - 7))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 6, y - 7))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y + 1))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y + 1))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'fantasyBase')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _diceBuddy(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 6, y - 14, 13, 13);
  p[CompanionNode.eyes]
    ..fillEllipse(x - 3, y - 11, 1, 1)
    ..fillEllipse(x + 3, y - 4, 1, 1)
    ..fillEllipse(x, y - 7, 1, 1);
  p[CompanionNode.leftArm].line(x - 6, y - 8, x - 10, y - 5);
  p[CompanionNode.rightArm].line(x + 6, y - 8, x + 10, y - 5);
  p[CompanionNode.leftLeg].line(x - 3, y - 1, x - 5, y + 3);
  p[CompanionNode.rightLeg].line(x + 3, y - 1, x + 5, y + 3);
  p
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 6, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 6, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y - 1))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y - 1))
    ..color(CompanionNode.body, 'white')
    ..color(CompanionNode.eyes, 'mouthDark');
}

void _serviceBot(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 5, y - 10, 11, 10);
  p[CompanionNode.head].fillRect(x - 4, y - 16, 9, 6);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 14)
    ..set(x + 2, y - 14);
  p[CompanionNode.mouth].hLine(x - 2, x + 2, y - 11);
  p[CompanionNode.leftArm]
    ..line(x - 5, y - 8, x - 9, y - 4, thickness: 2)
    ..set(x - 10, y - 3);
  p[CompanionNode.rightArm]
    ..line(x + 5, y - 8, x + 9, y - 4, thickness: 2)
    ..set(x + 10, y - 3);
  p[CompanionNode.leftLeg].fillRect(x - 4, y, 3, 4);
  p[CompanionNode.rightLeg].fillRect(x + 2, y, 3, 4);
  p[CompanionNode.leftAntenna]
    ..line(x - 1, y - 16, x - 4, y - 20)
    ..set(x - 4, y - 21);
  p[CompanionNode.heldItem]
    ..fillRect(x + side * 9, y - 5, 3, 5)
    ..line(x + side * 10, y - 5, x + side * 12, y - 8);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 5, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 5, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y))
    ..anchor(CompanionNode.leftAntenna, PixelPoint(x - 1, y - 16))
    ..anchor(CompanionNode.heldItem, PixelPoint(x + side * 9, y - 4), parentNode: side > 0 ? CompanionNode.rightArm : CompanionNode.leftArm)
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothAccent')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _scoutDrone(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 10, 6, 4);
  p[CompanionNode.head].fillRect(x - 3, y - 13, 7, 4);
  p[CompanionNode.eyes].hLine(x - 2, x + 2, y - 12);
  p[CompanionNode.leftWing]
    ..hLine(x - 12, x - 4, y - 11)
    ..fillEllipse(x - 12, y - 11, 2, 1);
  p[CompanionNode.rightWing]
    ..hLine(x + 4, x + 12, y - 11)
    ..fillEllipse(x + 12, y - 11, 2, 1);
  p[CompanionNode.leftLeg].line(x - 3, y - 7, x - 5, y - 3);
  p[CompanionNode.rightLeg].line(x + 3, y - 7, x + 5, y - 3);
  p[CompanionNode.trail]
    ..set(x - 2, y - 5)
    ..set(x + 2, y - 5);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 9))
    ..anchor(CompanionNode.leftWing, PixelPoint(x - 4, y - 11))
    ..anchor(CompanionNode.rightWing, PixelPoint(x + 4, y - 11))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 3, y - 7))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 3, y - 7))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 6))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothAccent')
    ..color(CompanionNode.leftWing, 'clothLight')
    ..color(CompanionNode.rightWing, 'clothLight')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _robotSpider(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillEllipse(x, y - 8, 5, 4);
  p[CompanionNode.head].fillEllipse(x + side * 4, y - 9, 3, 3);
  p[CompanionNode.eyes]
    ..set(x + side * 3, y - 10)
    ..set(x + side * 5, y - 10);
  p[CompanionNode.leftArm]
    ..line(x - 3, y - 8, x - 9, y - 13)
    ..line(x - 9, y - 13, x - 12, y - 9)
    ..line(x - 3, y - 6, x - 10, y - 3)
    ..line(x - 10, y - 3, x - 12, y + 1);
  p[CompanionNode.rightArm]
    ..line(x + 3, y - 8, x + 9, y - 13)
    ..line(x + 9, y - 13, x + 12, y - 9)
    ..line(x + 3, y - 6, x + 10, y - 3)
    ..line(x + 10, y - 3, x + 12, y + 1);
  p[CompanionNode.leftLeg]
    ..line(x - 2, y - 5, x - 7, y + 1)
    ..line(x - 7, y + 1, x - 5, y + 4);
  p[CompanionNode.rightLeg]
    ..line(x + 2, y - 5, x + 7, y + 1)
    ..line(x + 7, y + 1, x + 5, y + 4);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 2, y - 9))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 3, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 3, y - 8))
    ..anchor(CompanionNode.leftLeg, PixelPoint(x - 2, y - 5))
    ..anchor(CompanionNode.rightLeg, PixelPoint(x + 2, y - 5))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothAccent')
    ..color(CompanionNode.eyes, 'fantasyLight');
}

void _hologramAssistant(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body]
    ..fillTriangle(
      (x: x - 5, y: y),
      (x: x + 5, y: y),
      (x: x, y: y - 12),
    )
    ..hLine(x - 7, x + 7, y + 1);
  p[CompanionNode.head].fillEllipse(x, y - 14, 4, 4);
  p[CompanionNode.eyes]
    ..set(x - 2, y - 15)
    ..set(x + 2, y - 15);
  p[CompanionNode.mouth].hLine(x - 1, x + 1, y - 11);
  p[CompanionNode.leftArm].line(x - 2, y - 8, x - 7, y - 5);
  p[CompanionNode.rightArm].line(x + 2, y - 8, x + 7, y - 5);
  p[CompanionNode.trail]
    ..hLine(x - 5, x + 5, y - 3)
    ..hLine(x - 3, x + 3, y - 1);
  p
    ..anchor(CompanionNode.head, PixelPoint(x, y - 10))
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 2, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 2, y - 8))
    ..anchor(CompanionNode.trail, PixelPoint(x, y - 4))
    ..color(CompanionNode.body, 'fantasyBase')
    ..color(CompanionNode.head, 'fantasyLight')
    ..color(CompanionNode.trail, 'fantasyDark');
}

void _radioBuddy(CompanionRigParts p, int x, int y, int side) {
  p[CompanionNode.body].fillRect(x - 6, y - 13, 13, 13);
  p[CompanionNode.head]
    ..line(x + side * 3, y - 13, x + side * 7, y - 19)
    ..set(x + side * 7, y - 20);
  p[CompanionNode.eyes]
    ..set(x - 3, y - 10)
    ..set(x + 3, y - 10);
  p[CompanionNode.mouth]
    ..hLine(x - 4, x + 4, y - 6)
    ..hLine(x - 3, x + 3, y - 4);
  p[CompanionNode.leftArm].line(x - 6, y - 8, x - 10, y - 5);
  p[CompanionNode.rightArm].line(x + 6, y - 8, x + 10, y - 5);
  p
    ..anchor(CompanionNode.head, PixelPoint(x + side * 3, y - 13), parentNode: CompanionNode.body)
    ..anchor(CompanionNode.leftArm, PixelPoint(x - 6, y - 8))
    ..anchor(CompanionNode.rightArm, PixelPoint(x + 6, y - 8))
    ..color(CompanionNode.body, 'clothDark')
    ..color(CompanionNode.head, 'clothAccent')
    ..color(CompanionNode.eyes, 'fantasyLight')
    ..color(CompanionNode.mouth, 'fantasyBase');
}
