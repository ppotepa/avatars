import 'companion_rig_v2_model.dart';
import 'companion_styles_arcade_tech.dart';
import 'companion_styles_fun.dart';
import 'companion_styles_natural_fantasy.dart';
import 'companion_styles_undead_cosmic.dart';

CompanionStyleSpec? companionStyle(String id) =>
    undeadCosmicCompanionStyle(id) ??
    arcadeTechCompanionStyle(id) ??
    naturalFantasyCompanionStyle(id) ??
    funCompanionStyle(id);

const Set<String> kArticulatedCompanionStyles = <String>{
  // Existing companions.
  'parrot',
  'cat',
  'smallDragon',
  'shoulderRobot',
  'ghost',
  'insect',
  'owl',
  'crow',
  'raven',
  'bat',
  'snake',
  'frog',
  'mushroomBuddy',
  'floatingSkull',
  'miniDrone',
  'lanternSpirit',
  'starOrb',
  'cloudSpirit',
  'bookFamiliar',

  // Undead.
  'sheetGhost',
  'miniSkeleton',
  'skullHands',
  'miniReaper',
  'zombieHead',
  'vampireBat',

  // Cosmic.
  'greyAlien',
  'alienBlob',
  'miniUfo',
  'cosmicParasite',
  'miniAstronaut',
  'cosmicJellyfish',

  // Arcade.
  'arcadeChomper',
  'arcadeGhost',
  'joystickBuddy',
  'pixelHeartBuddy',
  'arcadeCabinet',
  'diceBuddy',

  // Technology.
  'serviceBot',
  'scoutDrone',
  'robotSpider',
  'hologramAssistant',
  'radioBuddy',

  // Fantasy.
  'miniGriffin',
  'fairy',
  'mandrake',
  'miniGolem',
  'miniMimic',
  'fireSprite',
  'floatingEye',

  // Natural.
  'rat',
  'raccoon',
  'chameleon',
  'gecko',
  'octopus',
  'snail',

  // Abstract and humorous.
  'stormCloud',
  'flameOrb',
  'blackHole',
  'slime',
  'coffeeBuddy',
  'donutBuddy',
  'emojiOrb',
  'miniBlackCatCloud',
};
