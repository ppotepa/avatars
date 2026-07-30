# V4.1 parameter catalog

Total: **26 categories / 223 fields**.

## Budowa ciała i ramiona (`body`)

Group: `anatomy`. Fields: 17. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `body.type` | select | `verySlim`, `slim`, `standard`, `broad`, `massive`, `muscular`, `petite`, `compact`, `tallNarrow`, `shortWide` |
| `body.width` | range | 26…47 (auto 30…44) |
| `body.mass` | range | 0…6 (auto 1…5) |
| `body.heightBias` | range | -2…2 (auto -1…1) |
| `body.verticalPosition` | range | -2…2 (auto -1…1) |
| `body.armVisibility` | range | 0…5 (auto 2…5) |
| `shoulders.shape` | select | `straight`, `sloping`, `raised`, `narrow`, `broad`, `rounded`, `angular`, `muscular`, `delicate`, `asymmetric` |
| `shoulders.width` | range | 28…47 (auto 32…45) |
| `shoulders.slope` | range | 0…6 (auto 1…4) |
| `shoulders.roundness` | range | 0…4 (auto 1…4) |
| `shoulders.height` | range | -2…2 (auto -1…1) |
| `shoulders.asymmetry` | range | -2…2 (auto -1…1) |
| `torso.shape` | select | `rectangle`, `trapezoid`, `taperedUp`, `taperedDown`, `wideChest`, `delicate`, `muscular`, `rounded` |
| `torso.widthTop` | range | 24…45 (auto 30…43) |
| `torso.widthBottom` | range | 24…48 (auto 32…47) |
| `torso.height` | range | 9…15 (auto 10…14) |
| `torso.taper` | range | -6…8 (auto -3…6) |

## Szyja (`neck`)

Group: `anatomy`. Fields: 7. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `neck.variant` | select | `veryShort`, `short`, `standard`, `long`, `veryLong`, `thin`, `wide`, `straight`, `tapered`, `flared`, `tilted`, `asymmetric` |
| `neck.length` | range | 3…10 (auto 4…8) |
| `neck.widthTop` | range | 4…12 (auto 5…10) |
| `neck.widthBottom` | range | 5…14 (auto 6…11) |
| `neck.taper` | range | -3…3 (auto -2…2) |
| `neck.offsetX` | range | -2…2 (auto -1…1) |
| `neck.shadowDepth` | range | 0…3 (auto 1…3) |

## Głowa, szczęka i podbródek (`head`)

Group: `anatomy`. Fields: 12. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `head.shape` | select | `round`, `oval`, `elongated`, `broad`, `square`, `rectangular`, `triangle`, `invertedTriangle`, `diamond`, `heart`, `pear`, `egg`, `wideJaw`, `narrowJaw`, `strongChin`, `softOval`, `highSkull`, `flatTop`, `angular` |
| `head.width` | range | 18…30 (auto 20…28) |
| `head.height` | range | 21…31 (auto 23…29) |
| `head.topWidth` | range | 12…30 (auto 17…27) |
| `head.templeWidth` | range | 14…30 (auto 18…27) |
| `head.cheekWidth` | range | 16…31 (auto 19…28) |
| `head.jawWidth` | range | 10…28 (auto 14…23) |
| `head.chinWidth` | range | 4…18 (auto 6…14) |
| `head.chinDepth` | range | 0…4 (auto 1…3) |
| `head.roundness` | range | 0…6 (auto 1…5) |
| `head.angularity` | range | 0…5 (auto 0…4) |
| `head.asymmetry` | range | -2…2 (auto -1…1) |

## Czoło (`forehead`)

Group: `anatomy`. Fields: 5. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `forehead.shape` | select | `low`, `standard`, `high`, `veryHigh`, `wide`, `narrow`, `sloped`, `straight`, `rounded` |
| `forehead.height` | range | 4…10 (auto 5…9) |
| `forehead.width` | range | 12…28 (auto 17…25) |
| `forehead.slope` | range | -2…2 (auto -1…1) |
| `forehead.roundness` | range | 0…4 (auto 1…4) |

## Uszy ludzkie i fantastyczne (`ears`)

Group: `anatomy`. Fields: 10. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `ears.shape` | select | `none`, `humanTiny`, `humanSmall`, `humanOval`, `humanRound`, `humanRect`, `humanLong`, `humanWide`, `attached`, `protruding`, `lowSet`, `highSet`, `asymmetric`, `elfShort`, `elfMedium`, `elfLong`, `elfUp`, `elfSide`, `goblin`, `fairy`, `bat`, `cat`, `fox`, `rabbit`, `owl`, `deer`, `moth`, `draconic`, `bone`, `demon`, `fin`, `mechanical` |
| `ears.width` | range | 2…9 (auto 2…6) |
| `ears.height` | range | 3…12 (auto 4…9) |
| `ears.positionY` | range | -3…3 (auto -2…2) |
| `ears.angle` | range | -4…4 (auto -2…2) |
| `ears.protrusion` | range | 0…6 (auto 1…5) |
| `ears.tipLength` | range | 0…9 (auto 0…6) |
| `ears.tipSharpness` | range | 0…4 (auto 0…4) |
| `ears.innerDetail` | select | `none`, `singleLine`, `doubleLine`, `shadow`, `highlight`, `shell` |
| `ears.asymmetry` | range | -2…2 (auto -1…1) |

## Oczy, powieki, źrenice i rzęsy (`eyes`)

Group: `anatomy`. Fields: 16. Presets: 5.

| ID | Type | Domain |
|---|---|---|
| `eyes.shape` | select | `dot`, `twoPixel`, `round`, `oval`, `horizontal`, `vertical`, `almond`, `narrow`, `wide`, `rectangular`, `triangular`, `downturned`, `upturned`, `deepSet`, `cartoon`, `realistic`, `solidBlack`, `robotic` |
| `eyes.width` | range | 1…7 (auto 2…6) |
| `eyes.height` | range | 1…4 (auto 1…4) |
| `eyes.spacing` | range | 2…12 (auto 4…10) |
| `eyes.positionY` | range | -3…3 (auto -2…2) |
| `eyes.outerAngle` | range | -2…2 (auto -1…1) |
| `eyes.eyelid` | select | `none`, `upper`, `lower`, `both`, `heavy`, `drooping`, `double` |
| `eyes.lidThickness` | range | 0…2 (auto 0…2) |
| `eyes.irisStyle` | select | `none`, `pixel`, `small`, `medium`, `large`, `full`, `ring`, `twoTone`, `glow` |
| `eyes.irisSize` | range | 0…3 (auto 1…3) |
| `eyes.pupilStyle` | select | `none`, `dot`, `small`, `medium`, `large`, `vertical`, `horizontal`, `square`, `glowing`, `fullBlack` |
| `eyes.pupilSize` | range | 1…3 (auto 1…2) |
| `eyes.scleraVisibility` | range | 0…3 (auto 1…3) |
| `eyes.lashes` | select | `none`, `single`, `short`, `medium`, `long`, `outerShort`, `outerLong`, `upper`, `lower`, `stylized` |
| `eyes.lashLength` | range | 0…3 (auto 0…2) |
| `eyes.asymmetry` | range | -1…1 (auto 0…1) |

## Brwi (`brows`)

Group: `anatomy`. Fields: 8. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `brows.shape` | select | `none`, `veryThin`, `thin`, `medium`, `thick`, `veryThick`, `straight`, `rounded`, `highArch`, `lowArch`, `angular`, `short`, `long`, `gap`, `solid`, `asymmetric`, `bushy` |
| `brows.width` | range | 2…9 (auto 4…8) |
| `brows.thickness` | range | 0…3 (auto 1…3) |
| `brows.height` | range | -1…5 (auto 1…4) |
| `brows.spacing` | range | 1…8 (auto 2…6) |
| `brows.arch` | range | -2…3 (auto -1…2) |
| `brows.colorMode` | select | `linkedHair`, `darkerHair`, `lighterHair`, `independent` |
| `brows.asymmetry` | range | -1…1 (auto 0…1) |

## Nos (`nose`)

Group: `anatomy`. Fields: 9. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `nose.shape` | select | `none`, `pixel`, `dot`, `button`, `short`, `medium`, `long`, `straight`, `wide`, `narrow`, `flat`, `upturned`, `hooked`, `triangular`, `square`, `rounded`, `largeTip`, `smallTip`, `shadowOnly`, `nostrilsOnly`, `mechanical`, `animal` |
| `nose.length` | range | 0…8 (auto 2…7) |
| `nose.width` | range | 1…7 (auto 1…5) |
| `nose.bridgeWidth` | range | 0…3 (auto 0…2) |
| `nose.tipWidth` | range | 1…6 (auto 1…5) |
| `nose.positionY` | range | -2…3 (auto -1…2) |
| `nose.nostrilSpacing` | range | 0…5 (auto 1…4) |
| `nose.shadowStrength` | range | 0…3 (auto 1…3) |
| `nose.asymmetry` | range | -1…1 (auto 0…1) |

## Usta (`mouth`)

Group: `anatomy`. Fields: 9. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `mouth.shape` | select | `none`, `pixel`, `shortLine`, `line`, `wideLine`, `thin`, `full`, `lowerFull`, `upperFull`, `smallRound`, `cupid`, `angular`, `twoTone`, `shadowed`, `openGap` |
| `mouth.width` | range | 2…12 (auto 4…10) |
| `mouth.height` | range | 1…3 (auto 1…2) |
| `mouth.positionY` | range | -2…3 (auto -1…2) |
| `mouth.upperLipThickness` | range | 0…2 (auto 0…2) |
| `mouth.lowerLipThickness` | range | 0…2 (auto 0…2) |
| `mouth.centerDip` | range | 0…2 (auto 0…2) |
| `mouth.colorMode` | select | `skinShadow`, `softPink`, `red`, `brown`, `purple`, `black`, `cosmetic` |
| `mouth.asymmetry` | range | -1…1 (auto 0…1) |

## Policzki i detale twarzy (`cheeks`)

Group: `details`. Fields: 7. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `cheeks.shape` | select | `none`, `wide`, `narrow`, `high`, `low`, `sharp`, `round`, `hollow`, `full` |
| `cheeks.width` | range | 0…8 (auto 2…7) |
| `cheeks.height` | range | 0…4 (auto 1…3) |
| `cheeks.positionY` | range | -2…2 (auto -1…1) |
| `cheeks.roundness` | range | 0…4 (auto 1…4) |
| `cheeks.shadowStrength` | range | 0…3 (auto 0…2) |
| `cheeks.blush` | range | 0…3 (auto 0…2) |

## Włosy, fryzura i łysienie (`hair`)

Group: `details`. Fields: 24. Presets: 20.

| ID | Type | Domain |
|---|---|---|
| `hair.lengthStyle` | select | `none`, `shaved`, `veryShort`, `short`, `ear`, `jaw`, `neck`, `shoulder`, `belowShoulder` |
| `hair.length` | range | 0…15 (auto 0…13) |
| `hair.topMass` | select | `none`, `flat`, `rounded`, `high`, `angular`, `spiky`, `curly`, `afro`, `mohawk`, `irregular`, `tuft` |
| `hair.volumeTop` | range | 0…8 (auto 1…7) |
| `hair.volumeSides` | range | 0…6 (auto 0…5) |
| `hair.volumeBack` | range | 0…6 (auto 1…5) |
| `hair.texture` | select | `straight`, `slightlyWavy`, `wavy`, `veryWavy`, `curly`, `tightCurls`, `afro`, `spiky`, `fluffy`, `smooth`, `heavy`, `messy` |
| `hair.hairline` | select | `veryLow`, `low`, `standard`, `high`, `veryHigh`, `straight`, `rounded`, `softM`, `widowsPeak`, `receded`, `uneven`, `asymmetric`, `deepTemples`, `hidden` |
| `hair.hairlineHeight` | range | 0…7 (auto 1…6) |
| `hair.templeDepth` | range | 0…6 (auto 0…5) |
| `hair.balding` | select | `none`, `slightRecession`, `temples`, `deepTemples`, `crownThin`, `tonsure`, `frontal`, `frontCrown`, `sidesOnly`, `tuft`, `fullBald`, `shaved` |
| `hair.recession` | range | 0…6 (auto 0…5) |
| `hair.crownRadius` | range | 0…5 (auto 0…4) |
| `hair.topDensity` | range | 0…5 (auto 2…5) |
| `hair.parting` | select | `none`, `center`, `left`, `right`, `deepLeft`, `deepRight`, `irregular`, `zigzag` |
| `hair.partPosition` | range | -4…4 (auto -3…3) |
| `hair.fringe` | select | `none`, `shortStraight`, `straight`, `straightLong`, `sideLeft`, `sideRight`, `split`, `curtain`, `uneven`, `choppy`, `singleTuft`, `oneEye`, `bothEyes`, `asymmetric` |
| `hair.fringeLength` | range | 0…9 (auto 1…8) |
| `hair.fringeDensity` | range | 0…4 (auto 1…4) |
| `hair.sides` | select | `none`, `shaved`, `veryShort`, `short`, `close`, `outward`, `partialEars`, `coverEars`, `longStrands`, `asymmetric` |
| `hair.earCoverage` | range | 0…5 (auto 0…4) |
| `hair.back` | select | `none`, `short`, `ear`, `jaw`, `neck`, `shoulder`, `belowShoulder`, `wide`, `narrow`, `rounded`, `straight`, `choppy`, `neckLong` |
| `hair.grayingPattern` | select | `none`, `strands`, `temples`, `front`, `even`, `full` |
| `hair.grayingAmount` | range | 0…5 (auto 0…4) |

## Zarost (`facialHair`)

Group: `details`. Fields: 8. Presets: 5.

| ID | Type | Domain |
|---|---|---|
| `facialHair.style` | select | `none`, `shadow`, `stubble`, `fullStubble`, `shortBeard`, `longBeard`, `pointedBeard`, `squareBeard`, `goatee`, `chinOnly`, `sideburns`, `thinMustache`, `thickMustache`, `curledMustache`, `mustacheBeard`, `asymmetric` |
| `facialHair.density` | range | 0…4 (auto 0…4) |
| `facialHair.length` | range | 0…8 (auto 1…6) |
| `facialHair.mustacheThickness` | range | 0…3 (auto 1…3) |
| `facialHair.chinCoverage` | range | 0…5 (auto 1…5) |
| `facialHair.cheekCoverage` | range | 0…4 (auto 0…3) |
| `facialHair.sideburnLength` | range | 0…7 (auto 1…6) |
| `facialHair.colorMode` | select | `linkedHair`, `darkerHair`, `lighterHair`, `independent` |

## Skóra, cieniowanie i szczegóły (`skin`)

Group: `colors`. Fields: 7. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `skin.tone` | select | `veryFair`, `fair`, `fairWarm`, `fairCool`, `medium`, `olive`, `golden`, `brown`, `darkBrown`, `veryDark`, `fantasyBlue`, `fantasyGreen`, `fantasyRed`, `fantasyPurple`, `fantasyGray` |
| `skin.detail` | select | `none`, `freckles`, `manyFreckles`, `moles`, `scar`, `foreheadWrinkles`, `underEyeWrinkles`, `cheekLines`, `blush`, `underEyeShadow`, `mechanicalJoints`, `scales`, `spots` |
| `skin.detailDensity` | range | 0…4 (auto 0…3) |
| `skin.warmth` | range | -2…2 (auto -1…1) |
| `skin.brightness` | range | -2…2 (auto -1…1) |
| `skin.shadowDepth` | range | 0…3 (auto 1…3) |
| `skin.highlightStrength` | range | 0…3 (auto 1…3) |

## Rogi, anteny i oznaczenia fantasy (`fantasy`)

Group: `details`. Fields: 10. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `fantasy.hornStyle` | select | `none`, `tiny`, `straight`, `curved`, `upward`, `sideways`, `asymmetric`, `single`, `ram`, `antler`, `demon`, `mechanical` |
| `fantasy.hornLength` | range | 0…10 (auto 2…8) |
| `fantasy.hornWidth` | range | 1…5 (auto 1…4) |
| `fantasy.hornAngle` | range | -4…4 (auto -3…3) |
| `fantasy.hornCurvature` | range | 0…5 (auto 1…4) |
| `fantasy.hornAsymmetry` | range | -2…2 (auto -1…1) |
| `fantasy.antennaStyle` | select | `none`, `single`, `double`, `short`, `long`, `ballTip`, `mechanical`, `insect`, `fairy` |
| `fantasy.antennaLength` | range | 0…10 (auto 2…8) |
| `fantasy.marking` | select | `none`, `foreheadRune`, `templeDots`, `cheekStripes`, `circuit`, `scales`, `star`, `thirdEye` |
| `fantasy.markingIntensity` | range | 0…4 (auto 1…3) |

## Odzież bazowa (`clothing`)

Group: `details`. Fields: 8. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `clothing.garment` | select | `plain`, `tShirt`, `shirt`, `hoodie`, `sweater`, `tunic`, `armor`, `jumpsuit`, `coat`, `robe`, `top` |
| `clothing.neckline` | select | `round`, `v`, `high`, `turtleneck`, `square`, `open`, `asymmetric` |
| `clothing.necklineDepth` | range | 0…5 (auto 1…4) |
| `clothing.collarWidth` | range | 0…5 (auto 0…4) |
| `clothing.shoulderCoverage` | range | 0…5 (auto 2…5) |
| `clothing.pattern` | select | `none`, `stripe`, `doubleStripe`, `checker`, `dots`, `diagonal`, `sash`, `trim`, `runes`, `plates` |
| `clothing.patternDensity` | range | 0…4 (auto 1…3) |
| `clothing.shadowStrength` | range | 0…3 (auto 1…3) |

## Kolory i paleta 32-kolorowa (`colors`)

Group: `colors`. Fields: 9. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `colors.paletteStyle` | select | `balanced`, `soft`, `highContrast`, `warm`, `cool`, `vivid` |
| `colors.hairColor` | select | `black`, `darkBrown`, `brown`, `lightBrown`, `blond`, `platinum`, `red`, `auburn`, `gray`, `white`, `blue`, `green`, `pink`, `purple`, `multicolor` |
| `colors.irisColor` | select | `brown`, `darkBrown`, `hazel`, `green`, `blue`, `gray`, `amber`, `violet`, `red`, `black`, `glowCyan`, `glowGold` |
| `colors.mouthColor` | select | `skin`, `softPink`, `red`, `brown`, `purple`, `black`, `coral` |
| `colors.clothColor` | select | `blue`, `navy`, `teal`, `green`, `olive`, `red`, `rust`, `orange`, `yellow`, `purple`, `magenta`, `gray`, `black`, `white` |
| `colors.backgroundColor` | select | `navy`, `slate`, `charcoal`, `cream`, `sand`, `forest`, `teal`, `rust`, `deepPurple`, `black` |
| `colors.outlineMode` | select | `nearBlack`, `softDark`, `colored`, `highContrast` |
| `colors.browIndependent` | select | `black`, `brown`, `blond`, `red`, `gray`, `white`, `blue`, `purple` |
| `colors.facialHairIndependent` | select | `black`, `brown`, `blond`, `red`, `gray`, `white`, `blue`, `purple` |

## V4 · Świat, archetyp i randomizacja (`identityV4`)

Group: `details`. Fields: 7. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.worldStyle` | select | `modern`, `fantasy`, `scienceFiction`, `cyberpunk`, `steampunk`, `postApocalyptic`, `historical`, `military`, `magical`, `horror`, `royal`, `mixed` |
| `v4.archetype` | select | `auto`, `knight`, `wanderingMage`, `rogue`, `pirateCaptain`, `cowboy`, `soldier`, `streetHacker`, `scientist`, `mechanic`, `spacePilot`, `monarch`, `priest`, `barbarian`, `forestElf`, `goblinMechanic`, `robot`, `mutant`, `vampire`, `zombie`, `detective`, `musician`, `doctor`, `chef`, `miner`, `diver` |
| `v4.randomMode` | select | `natural`, `diverse`, `stylized`, `fantasy`, `scifi`, `chaotic`, `rareHeavy`, `minimal` |
| `v4.morphology` | select | `human`, `skull`, `skeleton`, `undead`, `construct` |
| `v4.complexity` | range | 0…100 (auto 25…82) |
| `v4.rarityBias` | range | 0…100 (auto 5…65) |
| `v4.accessoryAsymmetry` | range | 0…5 (auto 0…3) |

## V4 · Nakrycia głowy i hełmy (`headwearV4`)

Group: `wearables`. Fields: 8. Presets: 4.

| ID | Type | Domain |
|---|---|---|
| `v4.headwear` | select | `none`, `baseballCap`, `beanie`, `beret`, `fedora`, `cowboyHat`, `topHat`, `wizardHat`, `strawHat`, `hood`, `bandana`, `headband`, `turban`, `crown`, `boneCrown`, `veil`, `hornedCrown`, `halo`, `hoodedCowl`, `tiara`, `wreath`, `winterHat`, `sailorCap`, `militaryCap`, `chefHat`, `pirateHat`, `helmetKnightOpen`, `helmetKnightClosed`, `helmetNorse`, `helmetGladiator`, `helmetSamurai`, `helmetFuturistic`, `spaceHelmet`, `motorcycleHelmet`, `tacticalHelmet`, `minerHelmet`, `diverHelmet`, `hornedHelmet`, `demonHelmet`, `ceremonialHelmet`, `robotHelmet` |
| `v4.headwearWidth` | range | 8…40 (auto 16…32) |
| `v4.headwearHeight` | range | 2…15 (auto 4…10) |
| `v4.headwearTilt` | range | -3…3 (auto -1…1) |
| `v4.headwearOffsetX` | range | -4…4 (auto -1…1) |
| `v4.headwearCoverage` | range | 0…6 (auto 1…5) |
| `v4.hairCompression` | range | 0…6 (auto 1…5) |
| `v4.headwearDamage` | range | 0…4 (auto 0…2) |

## V4 · Okulary, wizjery i opaski (`eyewearV4`)

Group: `wearables`. Fields: 6. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.eyewear` | select | `none`, `roundGlasses`, `ovalGlasses`, `squareGlasses`, `rectGlasses`, `tinyGlasses`, `oversizeGlasses`, `thinFrames`, `thickFrames`, `rimless`, `halfFrames`, `catEye`, `retro`, `aviator`, `wayfarer`, `narrowShades`, `mirrorShades`, `cyberVisor`, `monoVisor`, `monocleLeft`, `monocleRight`, `eyePatchLeft`, `eyePatchRight`, `targetingLens`, `weldingGoggles` |
| `v4.frameThickness` | range | 1…3 (auto 1…2) |
| `v4.lensHeight` | range | 1…6 (auto 2…4) |
| `v4.bridgeWidth` | range | 1…5 (auto 1…3) |
| `v4.lensTint` | range | 0…5 (auto 0…3) |
| `v4.reflection` | range | 0…3 (auto 0…2) |

## V4 · Maski twarzy (`faceMaskV4`)

Group: `wearables`. Fields: 4. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.faceMask` | select | `none`, `surgicalMask`, `respirator`, `faceBandana`, `ninjaMask`, `gasMask`, `theaterMask`, `venetianMask`, `demonMask`, `robotMask`, `halfMask`, `hockeyMask`, `ceremonialMask`, `skullPlate`, `boneJaw`, `plagueMask`, `oniMask`, `porcelainMask`, `balaclava`, `scarfMask` |
| `v4.maskCoverage` | range | 1…6 (auto 2…5) |
| `v4.maskFilterSize` | range | 0…4 (auto 1…3) |
| `v4.maskDamage` | range | 0…4 (auto 0…2) |

## V4 · Biżuteria i dodatki szyi (`jewelryV4`)

Group: `wearables`. Fields: 5. Presets: 2.

| ID | Type | Domain |
|---|---|---|
| `v4.earJewelry` | select | `none`, `stud`, `smallHoop`, `largeHoop`, `multiPiercing`, `industrial`, `tunnel`, `dangling`, `pearl`, `chainEarring`, `fantasyEarring` |
| `v4.facePiercing` | select | `none`, `noseStud`, `septum`, `browPiercing`, `lipRing`, `labret`, `foreheadGem` |
| `v4.neckJewelry` | select | `none`, `thinChain`, `thickChain`, `choker`, `medallion`, `amulet`, `dogTags`, `beads`, `scarf`, `cravat`, `bowTie`, `tie`, `royalMedallion` |
| `v4.jewelrySize` | range | 1…5 (auto 1…3) |
| `v4.jewelryCount` | range | 1…5 (auto 1…3) |

## V4 · Odzież zaawansowana i zbroje (`armorV4`)

Group: `wearables`. Fields: 7. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.armor` | select | `none`, `leatherArmor`, `chainmail`, `plateArmor`, `samuraiArmor`, `gladiatorArmor`, `ceremonialArmor`, `magicArmor`, `iceArmor`, `demonArmor`, `mechanicalArmor`, `spaceArmor`, `scrapArmor`, `tshirt`, `shirt`, `hoodie`, `jacket`, `vest`, `coat`, `sweater`, `turtleneck`, `blazer`, `uniform`, `apron`, `jumpsuit`, `wizardRobe`, `priestRobe`, `pirateCoat`, `cowboyVest`, `labCoat`, `travelerCoat` |
| `v4.cape` | select | `none`, `shortCape`, `longCape`, `loweredHood`, `scarfBack`, `furCollar`, `angelWings`, `demonWings`, `dragonWings`, `mechanicalWings`, `backpack`, `quiver`, `swordBack`, `energyRifleBack`, `mechanicalTubes` |
| `v4.armorBulk` | range | 0…6 (auto 1…5) |
| `v4.pauldronSize` | range | 0…6 (auto 1…5) |
| `v4.armorDamage` | range | 0…5 (auto 0…3) |
| `v4.armorGlow` | range | 0…4 (auto 0…2) |
| `v4.emblemSize` | range | 0…5 (auto 0…3) |

## V4 · Rekwizyty ust i ramion (`propsV4`)

Group: `wearables`. Fields: 6. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.mouthProp` | select | `none`, `cigarette`, `cigar`, `pipe`, `grassBlade`, `matchstick`, `toothpick`, `lollipop`, `straw`, `flower`, `rose`, `thermometer`, `whistle`, `instrumentMouthpiece`, `cyberCable` |
| `v4.shoulderProp` | select | `none`, `parrot`, `cat`, `smallDragon`, `shoulderRobot`, `ghost`, `insect`, `flowerBundle`, `skull`, `radio`, `flashlight`, `energyOrb` |
| `v4.propSide` | range | -1…1 (auto -1…1) |
| `v4.propAngle` | range | -4…4 (auto -2…2) |
| `v4.propLength` | range | 2…10 (auto 3…8) |
| `v4.smokeAmount` | range | 0…6 (auto 1…5) |

## V4 · Cybernetyka, blizny i oznaczenia (`cyberV4`)

Group: `details`. Fields: 6. Presets: 2.

| ID | Type | Domain |
|---|---|---|
| `v4.cybernetics` | select | `none`, `cyberEyeLeft`, `cyberEyeRight`, `metalJaw`, `templeImplant`, `faceWires`, `cheekPlate`, `artificialEar`, `scanner`, `halfFace`, `neckPorts`, `chestReactor` |
| `v4.scar` | select | `none`, `eyeVertical`, `eyeSlash`, `browScar`, `lipScar`, `chinScar`, `smallScars`, `stitches`, `burn`, `mechanicalCrack` |
| `v4.marking` | select | `none`, `tribal`, `runes`, `geometric`, `warPaint`, `clown`, `skullPaint`, `camouflage`, `cyberLines`, `magicGlyphs` |
| `v4.cyberCoverage` | range | 1…6 (auto 2…5) |
| `v4.cyberGlow` | range | 0…4 (auto 1…3) |
| `v4.markingCoverage` | range | 1…5 (auto 1…3) |

## V4 · Efekty, aura i tło (`effectsV4`)

Group: `effects`. Fields: 6. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.background` | select | `solid`, `blockGradient`, `verticalSplit`, `horizontalSplit`, `diagonalStripes`, `checker`, `dots`, `pixelNoise`, `sunset`, `night`, `neonCity`, `forest`, `space`, `dungeon`, `laboratory`, `spaceship`, `flames`, `snowField`, `rainCity`, `magicAura`, `terminal`, `factionSymbol` |
| `v4.effect` | select | `none`, `smoke`, `steam`, `sparks`, `snow`, `rain`, `dust`, `leaves`, `ash`, `bubbles`, `fire`, `electricity`, `magicParticles`, `glitch`, `hologram`, `embers` |
| `v4.aura` | select | `none`, `soft`, `dark`, `holy`, `fire`, `ice`, `electric`, `magic`, `holographic`, `runic` |
| `v4.particleDensity` | range | 0…6 (auto 1…5) |
| `v4.backgroundContrast` | range | 0…5 (auto 1…4) |
| `v4.vignette` | range | 0…4 (auto 0…3) |

## V4 · Animacja deterministyczna (`animationV4`)

Group: `effects`. Fields: 3. Presets: 3.

| ID | Type | Domain |
|---|---|---|
| `v4.animation` | select | `none`, `blink`, `lookAround`, `idle`, `smoke`, `hairWind`, `jewelrySwing`, `glowPulse`, `auraPulse`, `particles` |
| `v4.animationSpeed` | range | 1…6 (auto 2…4) |
| `v4.animationAmplitude` | range | 1…4 (auto 1…3) |
