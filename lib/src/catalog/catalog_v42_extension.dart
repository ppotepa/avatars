/// Additive V4.2 catalog data layered on top of the preserved V4.1 source.
///
/// Keeping the extension separate avoids rewriting the imported V4.1 reference
/// catalog while still exposing every new field through the metadata-driven
/// server editor.
const String kV42CatalogExtensionJson = r'''
{
  "fieldOptions": {
    "fantasy.hornStyle": [
      {"value":"ramCurl","label":"Ram curl"},
      {"value":"bullForward","label":"Bull forward"},
      {"value":"bullWide","label":"Bull wide"},
      {"value":"antelopeTall","label":"Antelope tall"},
      {"value":"gazelleThin","label":"Gazelle thin"},
      {"value":"deerBranching","label":"Deer branching"},
      {"value":"mooseFlat","label":"Moose flat"},
      {"value":"demonHook","label":"Demon hook"},
      {"value":"demonJagged","label":"Demon jagged"},
      {"value":"dragonBack","label":"Dragon back"},
      {"value":"dragonSpikes","label":"Dragon spikes"},
      {"value":"crownHorns","label":"Crown horns"},
      {"value":"brokenLeft","label":"Broken left"},
      {"value":"brokenRight","label":"Broken right"},
      {"value":"unicorn","label":"Unicorn"},
      {"value":"boneHorns","label":"Bone horns"},
      {"value":"obsidianHorns","label":"Obsidian horns"},
      {"value":"crystalHorns","label":"Crystal horns"},
      {"value":"mechanicalHorns","label":"Mechanical horns"},
      {"value":"neonHorns","label":"Neon horns"},
      {"value":"coralHorns","label":"Coral horns"},
      {"value":"iceAntlers","label":"Ice antlers"}
    ],
    "v4.background": [
      {"value":"sunrise","label":"Sunrise"},
      {"value":"sunsetMountains","label":"Sunset mountains"},
      {"value":"moonlitForest","label":"Moonlit forest"},
      {"value":"foggyForest","label":"Foggy forest"},
      {"value":"desertDunes","label":"Desert dunes"},
      {"value":"oceanHorizon","label":"Ocean horizon"},
      {"value":"snowMountains","label":"Snow mountains"},
      {"value":"volcanicSky","label":"Volcanic sky"},
      {"value":"caveGlow","label":"Cave glow"},
      {"value":"citySkyline","label":"City skyline"},
      {"value":"castleWall","label":"Castle wall"},
      {"value":"throneRoom","label":"Throne room"},
      {"value":"cathedralWindow","label":"Cathedral window"},
      {"value":"libraryShelves","label":"Library shelves"},
      {"value":"factorySmoke","label":"Factory smoke"},
      {"value":"runeCircle","label":"Rune circle"},
      {"value":"portalRift","label":"Portal rift"},
      {"value":"floatingIslands","label":"Floating islands"},
      {"value":"crystalCave","label":"Crystal cave"},
      {"value":"astralPlane","label":"Astral plane"},
      {"value":"demonicGate","label":"Demonic gate"},
      {"value":"celestialHall","label":"Celestial hall"},
      {"value":"spaceStation","label":"Space station"},
      {"value":"starshipBridge","label":"Starship bridge"},
      {"value":"dataGrid","label":"Data grid"},
      {"value":"warpTunnel","label":"Warp tunnel"},
      {"value":"alienPlanet","label":"Alien planet"},
      {"value":"graveyard","label":"Graveyard"},
      {"value":"bloodMoon","label":"Blood moon"},
      {"value":"mistSwamp","label":"Mist swamp"},
      {"value":"deadForest","label":"Dead forest"},
      {"value":"voidStatic","label":"Void static"}
    ],
    "v4.aura": [
      {"value":"radiant","label":"Radiant"},
      {"value":"divine","label":"Divine"},
      {"value":"corrupted","label":"Corrupted"},
      {"value":"shadowFlame","label":"Shadow flame"},
      {"value":"storm","label":"Storm"},
      {"value":"plasma","label":"Plasma"},
      {"value":"poison","label":"Poison"},
      {"value":"nature","label":"Nature"},
      {"value":"bloodMist","label":"Blood mist"},
      {"value":"arcaneCircle","label":"Arcane circle"},
      {"value":"void","label":"Void"},
      {"value":"dream","label":"Dream"},
      {"value":"starlight","label":"Starlight"},
      {"value":"goldenDust","label":"Golden dust"},
      {"value":"sacredRunes","label":"Sacred runes"},
      {"value":"toxicSteam","label":"Toxic steam"}
    ]
  },
  "categories": [
    {
      "id":"expressionV42",
      "label":"V4.2 · Ekspresja twarzy",
      "group":"details",
      "presets":{
        "happy":{"v4.expression":"bigSmile","v4.eyeExpression":"happy","v4.browExpression":"relaxed","v4.mouthExpression":"wideSmile","v4.faceAnimation":"happy"},
        "laugh":{"v4.expression":"laugh","v4.eyeExpression":"laughing","v4.mouthExpression":"laughOpen","v4.faceAnimation":"laugh"},
        "angry":{"v4.expression":"angry","v4.eyeExpression":"angry","v4.browExpression":"angryDown","v4.mouthExpression":"snarl","v4.faceAnimation":"angry"},
        "sleepy":{"v4.expression":"sleepy","v4.eyeExpression":"halfLidded","v4.browExpression":"sleepyFlat","v4.mouthExpression":"breathingOpen","v4.faceAnimation":"sleepy"},
        "smug":{"v4.expression":"confident","v4.eyeExpression":"suspicious","v4.browExpression":"skepticalSingle","v4.mouthExpression":"smirkLeft","v4.faceAnimation":"smirk"}
      },
      "fields":[
        {"id":"v4.expression","label":"Ekspresja","type":"select","options":[
          {"value":"neutral","label":"Neutral"},{"value":"softSmile","label":"Soft smile"},{"value":"smile","label":"Smile"},{"value":"bigSmile","label":"Big smile"},{"value":"grin","label":"Grin"},{"value":"smirkLeft","label":"Smirk left"},{"value":"smirkRight","label":"Smirk right"},{"value":"laugh","label":"Laugh"},{"value":"openLaugh","label":"Open laugh"},{"value":"mischievous","label":"Mischievous"},{"value":"serious","label":"Serious"},{"value":"stern","label":"Stern"},{"value":"angry","label":"Angry"},{"value":"furious","label":"Furious"},{"value":"sad","label":"Sad"},{"value":"worried","label":"Worried"},{"value":"shy","label":"Shy"},{"value":"surprised","label":"Surprised"},{"value":"shocked","label":"Shocked"},{"value":"suspicious","label":"Suspicious"},{"value":"confident","label":"Confident"},{"value":"proud","label":"Proud"},{"value":"sleepy","label":"Sleepy"},{"value":"tired","label":"Tired"},{"value":"bored","label":"Bored"},{"value":"annoyed","label":"Annoyed"},{"value":"determined","label":"Determined"},{"value":"evilSmile","label":"Evil smile"},{"value":"manic","label":"Manic"},{"value":"crying","label":"Crying"},{"value":"blushingHappy","label":"Blushing happy"},{"value":"disgusted","label":"Disgusted"}
        ]},
        {"id":"v4.eyeExpression","label":"Ekspresja oczu","type":"select","options":[
          {"value":"auto","label":"Auto"},{"value":"neutral","label":"Neutral"},{"value":"happy","label":"Happy"},{"value":"laughing","label":"Laughing"},{"value":"soft","label":"Soft"},{"value":"focused","label":"Focused"},{"value":"wide","label":"Wide"},{"value":"narrowed","label":"Narrowed"},{"value":"suspicious","label":"Suspicious"},{"value":"sleepy","label":"Sleepy"},{"value":"halfLidded","label":"Half lidded"},{"value":"angry","label":"Angry"},{"value":"sad","label":"Sad"},{"value":"sparkly","label":"Sparkly"},{"value":"empty","label":"Empty"},{"value":"crazy","label":"Crazy"},{"value":"determined","label":"Determined"},{"value":"teary","label":"Teary"},{"value":"glowing","label":"Glowing"}
        ]},
        {"id":"v4.browExpression","label":"Ekspresja brwi","type":"select","options":[
          {"value":"auto","label":"Auto"},{"value":"relaxed","label":"Relaxed"},{"value":"liftedInner","label":"Lifted inner"},{"value":"liftedOuter","label":"Lifted outer"},{"value":"arched","label":"Arched"},{"value":"angryDown","label":"Angry down"},{"value":"sadUp","label":"Sad up"},{"value":"confidentTilt","label":"Confident tilt"},{"value":"skepticalSingle","label":"Skeptical single"},{"value":"sleepyFlat","label":"Sleepy flat"},{"value":"furrowed","label":"Furrowed"},{"value":"surprisedHigh","label":"Surprised high"},{"value":"mischiefCurve","label":"Mischief curve"}
        ]},
        {"id":"v4.mouthExpression","label":"Ekspresja ust","type":"select","options":[
          {"value":"auto","label":"Auto"},{"value":"neutral","label":"Neutral"},{"value":"smallSmile","label":"Small smile"},{"value":"closedSmile","label":"Closed smile"},{"value":"wideSmile","label":"Wide smile"},{"value":"openSmile","label":"Open smile"},{"value":"grin","label":"Grin"},{"value":"toothyGrin","label":"Toothy grin"},{"value":"smirkLeft","label":"Smirk left"},{"value":"smirkRight","label":"Smirk right"},{"value":"laughOpen","label":"Laugh open"},{"value":"laughWide","label":"Laugh wide"},{"value":"oShape","label":"O shape"},{"value":"shout","label":"Shout"},{"value":"frown","label":"Frown"},{"value":"sadFrown","label":"Sad frown"},{"value":"pout","label":"Pout"},{"value":"grimace","label":"Grimace"},{"value":"clenched","label":"Clenched"},{"value":"snarl","label":"Snarl"},{"value":"fangSmile","label":"Fang smile"},{"value":"tinySmile","label":"Tiny smile"},{"value":"flatAnnoyed","label":"Flat annoyed"},{"value":"kiss","label":"Kiss"},{"value":"chewing","label":"Chewing"},{"value":"speakingA","label":"Speaking A"},{"value":"speakingE","label":"Speaking E"},{"value":"speakingO","label":"Speaking O"},{"value":"speakingM","label":"Speaking M"},{"value":"breathingOpen","label":"Breathing open"}
        ]},
        {"id":"v4.emotionMark","label":"Znacznik emocji","type":"select","options":[
          {"value":"none","label":"None"},{"value":"blush","label":"Blush"},{"value":"tearLeft","label":"Tear left"},{"value":"tearBoth","label":"Tear both"},{"value":"sweatDrop","label":"Sweat drop"},{"value":"angerMark","label":"Anger mark"},{"value":"stressLines","label":"Stress lines"},{"value":"sleepBubble","label":"Sleep bubble"},{"value":"sparkleMarks","label":"Sparkle marks"},{"value":"heartMark","label":"Heart mark"},{"value":"cheekStars","label":"Cheek stars"},{"value":"underEyeShadow","label":"Under-eye shadow"},{"value":"magicFreckles","label":"Magic freckles"},{"value":"voidTears","label":"Void tears"}
        ]},
        {"id":"v4.expressionIntensity","label":"Intensywność ekspresji","type":"range","min":0,"max":5,"step":1,"auto":[1,4]},
        {"id":"v4.mouthOpen","label":"Otwarcie ust","type":"range","min":0,"max":4,"step":1,"auto":[0,2]},
        {"id":"v4.cheekLift","label":"Uniesienie policzków","type":"range","min":0,"max":4,"step":1,"auto":[0,3]},
        {"id":"v4.tearAmount","label":"Ilość łez","type":"range","min":0,"max":4,"step":1,"auto":[0,2]},
        {"id":"v4.faceAnimation","label":"Animacja emocji","type":"select","options":[
          {"value":"none","label":"None"},{"value":"laugh","label":"Laugh"},{"value":"talk","label":"Talk"},{"value":"smirk","label":"Smirk"},{"value":"angry","label":"Angry"},{"value":"sleepy","label":"Sleepy"},{"value":"curious","label":"Curious"},{"value":"proud","label":"Proud"},{"value":"sad","label":"Sad"},{"value":"surprised","label":"Surprised"},{"value":"evil","label":"Evil"},{"value":"happy","label":"Happy"},{"value":"bashful","label":"Bashful"},{"value":"confused","label":"Confused"}
        ]},
        {"id":"v4.mouthMotionStyle","label":"Ruch ust","type":"select","options":[
          {"value":"none","label":"None"},{"value":"talkSmall","label":"Talk small"},{"value":"talkNormal","label":"Talk normal"},{"value":"talkFast","label":"Talk fast"},{"value":"laughLoop","label":"Laugh loop"},{"value":"chewLoop","label":"Chew loop"},{"value":"breathLoop","label":"Breath loop"}
        ]},
        {"id":"v4.blinkStyle","label":"Styl mrugania","type":"select","options":[
          {"value":"normalBlink","label":"Normal blink"},{"value":"slowBlink","label":"Slow blink"},{"value":"doubleBlink","label":"Double blink"},{"value":"winkLeft","label":"Wink left"},{"value":"winkRight","label":"Wink right"},{"value":"sleepyBlink","label":"Sleepy blink"},{"value":"happyBlink","label":"Happy blink"},{"value":"nervousBlink","label":"Nervous blink"}
        ]},
        {"id":"v4.expressionSpeed","label":"Szybkość ekspresji","type":"range","min":1,"max":6,"step":1,"auto":[2,4]}
      ]
    },
    {
      "id":"adornmentV42",
      "label":"V4.2 · Aureole i dodatki",
      "group":"wearables",
      "presets":{
        "angelic":{"v4.halo":"holySpikes","v4.haloGlow":4,"v4.backAdornment":"wingsFeatherRoyal","v4.relic":"sacredRelic"},
        "cyber":{"v4.halo":"neonHalo","v4.headAdornment":"circuitMark","v4.backAdornment":"wingsHologram","v4.relic":"orbPendant"},
        "occult":{"v4.halo":"thornHalo","v4.symbolOverlay":"magicCircle","v4.headAdornment":"sigil","v4.relic":"boneNecklace"}
      },
      "fields":[
        {"id":"v4.halo","label":"Aureola","type":"select","options":[
          {"value":"none","label":"None"},{"value":"simpleRing","label":"Simple ring"},{"value":"thinHalo","label":"Thin halo"},{"value":"thickHalo","label":"Thick halo"},{"value":"brokenHalo","label":"Broken halo"},{"value":"doubleHalo","label":"Double halo"},{"value":"tiltedHalo","label":"Tilted halo"},{"value":"floatingSegments","label":"Floating segments"},{"value":"runicHalo","label":"Runic halo"},{"value":"holySpikes","label":"Holy spikes"},{"value":"solarDisc","label":"Solar disc"},{"value":"mechanicalHalo","label":"Mechanical halo"},{"value":"neonHalo","label":"Neon halo"},{"value":"glitchHalo","label":"Glitch halo"},{"value":"crownHalo","label":"Crown halo"},{"value":"thornHalo","label":"Thorn halo"},{"value":"flameHalo","label":"Flame halo"},{"value":"iceHalo","label":"Ice halo"},{"value":"electricHalo","label":"Electric halo"},{"value":"cosmicHalo","label":"Cosmic halo"}
        ]},
        {"id":"v4.haloSize","label":"Rozmiar aureoli","type":"range","min":6,"max":22,"step":1,"auto":[10,18]},
        {"id":"v4.haloHeight","label":"Wysokość aureoli","type":"range","min":-6,"max":6,"step":1,"auto":[-2,3]},
        {"id":"v4.haloTilt","label":"Pochylenie aureoli","type":"range","min":-3,"max":3,"step":1,"auto":[-1,1]},
        {"id":"v4.haloGlow","label":"Blask aureoli","type":"range","min":0,"max":5,"step":1,"auto":[1,4]},
        {"id":"v4.haloBreakage","label":"Pęknięcia aureoli","type":"range","min":0,"max":5,"step":1,"auto":[0,3]},
        {"id":"v4.haloOrbitSpeed","label":"Prędkość aureoli","type":"range","min":1,"max":6,"step":1,"auto":[2,4]},
        {"id":"v4.headAdornment","label":"Ozdoba czoła","type":"select","options":[
          {"value":"none","label":"None"},{"value":"foreheadGem","label":"Forehead gem"},{"value":"thirdEyeMark","label":"Third eye mark"},{"value":"moonCrescent","label":"Moon crescent"},{"value":"sunDisc","label":"Sun disc"},{"value":"sigil","label":"Sigil"},{"value":"runeStrip","label":"Rune strip"},{"value":"boneCharm","label":"Bone charm"},{"value":"chainForehead","label":"Chain forehead"},{"value":"crownFrontlet","label":"Crown frontlet"},{"value":"tiaraGem","label":"Tiara gem"},{"value":"laurelFront","label":"Laurel front"},{"value":"bandageForehead","label":"Bandage forehead"},{"value":"warPaintStripe","label":"War paint stripe"},{"value":"ritualDots","label":"Ritual dots"},{"value":"mechanicalPlate","label":"Mechanical plate"},{"value":"visorPlate","label":"Visor plate"},{"value":"crackGlow","label":"Crack glow"}
        ]},
        {"id":"v4.sideHeadFeature","label":"Boczne cechy głowy","type":"select","options":[
          {"value":"none","label":"None"},{"value":"finFrill","label":"Fin frill"},{"value":"featherTuft","label":"Feather tuft"},{"value":"gillSlits","label":"Gill slits"},{"value":"sideSpikes","label":"Side spikes"},{"value":"smallHorns","label":"Small horns"},{"value":"antennaBulb","label":"Antenna bulb"},{"value":"antennaFeather","label":"Antenna feather"},{"value":"mechanicalPort","label":"Mechanical port"},{"value":"audioReceiver","label":"Audio receiver"},{"value":"orbitalNode","label":"Orbital node"},{"value":"leafEarsAccent","label":"Leaf ears accent"},{"value":"furTufts","label":"Fur tufts"}
        ]},
        {"id":"v4.creatureTrait","label":"Cecha stworzenia","type":"select","options":[
          {"value":"none","label":"None"},{"value":"fangs","label":"Fangs"},{"value":"tusks","label":"Tusks"},{"value":"whiskers","label":"Whiskers"},{"value":"snoutHint","label":"Snout hint"},{"value":"catNose","label":"Cat nose"},{"value":"beakHint","label":"Beak hint"},{"value":"gills","label":"Gills"},{"value":"scales","label":"Scales"},{"value":"furPatches","label":"Fur patches"},{"value":"featherCheeks","label":"Feather cheeks"},{"value":"glowVeins","label":"Glow veins"},{"value":"stoneSkin","label":"Stone skin"},{"value":"barkSkin","label":"Bark skin"},{"value":"slimeDroplets","label":"Slime droplets"},{"value":"crystalGrowth","label":"Crystal growth"},{"value":"mushroomGrowth","label":"Mushroom growth"},{"value":"voidCracks","label":"Void cracks"}
        ]},
        {"id":"v4.symbolOverlay","label":"Symboliczna dekoracja","type":"select","options":[
          {"value":"none","label":"None"},{"value":"runes","label":"Runes"},{"value":"magicCircle","label":"Magic circle"},{"value":"glyphs","label":"Glyphs"},{"value":"crosshair","label":"Crosshair"},{"value":"targetLock","label":"Target lock"},{"value":"musicNotes","label":"Music notes"},{"value":"prayerText","label":"Prayer text"},{"value":"stars","label":"Stars"},{"value":"hearts","label":"Hearts"},{"value":"spiral","label":"Spiral"},{"value":"chains","label":"Chains"},{"value":"thorns","label":"Thorns"},{"value":"warningTriangles","label":"Warning triangles"},{"value":"electroLines","label":"Electro lines"},{"value":"smokeSwirls","label":"Smoke swirls"},{"value":"petalSwirls","label":"Petal swirls"},{"value":"constellationLines","label":"Constellation lines"},{"value":"clockworkRing","label":"Clockwork ring"}
        ]},
        {"id":"v4.symbolDensity","label":"Gęstość symboli","type":"range","min":0,"max":6,"step":1,"auto":[1,4]},
        {"id":"v4.symbolRotation","label":"Obrót symboli","type":"range","min":-4,"max":4,"step":1,"auto":[-2,2]},
        {"id":"v4.backAdornment","label":"Dodatek na plecach","type":"select","options":[
          {"value":"none","label":"None"},{"value":"bannerBack","label":"Banner back"},{"value":"totemPoleBack","label":"Totem pole back"},{"value":"spiritRibbon","label":"Spirit ribbon"},{"value":"prayerScrollBack","label":"Prayer scroll back"},{"value":"energyBackpack","label":"Energy backpack"},{"value":"jetpackSmall","label":"Jetpack small"},{"value":"jetpackLarge","label":"Jetpack large"},{"value":"crystalClusterBack","label":"Crystal cluster back"},{"value":"boneSpineBack","label":"Bone spine back"},{"value":"capeTorn","label":"Cape torn"},{"value":"capeRoyal","label":"Cape royal"},{"value":"cloakStarry","label":"Cloak starry"},{"value":"wingsInsect","label":"Wings insect"},{"value":"wingsBatLarge","label":"Wings bat large"},{"value":"wingsFeatherRoyal","label":"Wings feather royal"},{"value":"wingsEnergy","label":"Wings energy"},{"value":"wingsHologram","label":"Wings hologram"},{"value":"wingsGhostly","label":"Wings ghostly"}
        ]},
        {"id":"v4.extraShoulderProp","label":"Dodatkowy towarzysz","type":"select","options":[
          {"value":"none","label":"None"},{"value":"owl","label":"Owl"},{"value":"crow","label":"Crow"},{"value":"raven","label":"Raven"},{"value":"bat","label":"Bat"},{"value":"snake","label":"Snake"},{"value":"frog","label":"Frog"},{"value":"mushroomBuddy","label":"Mushroom buddy"},{"value":"floatingSkull","label":"Floating skull"},{"value":"miniDrone","label":"Mini drone"},{"value":"candle","label":"Candle"},{"value":"lanternSpirit","label":"Lantern spirit"},{"value":"starOrb","label":"Star orb"},{"value":"bookFamiliar","label":"Book familiar"},{"value":"cloudSpirit","label":"Cloud spirit"}
        ]},
        {"id":"v4.relic","label":"Relikwia","type":"select","options":[
          {"value":"none","label":"None"},{"value":"amuletLarge","label":"Amulet large"},{"value":"multipleChains","label":"Multiple chains"},{"value":"prayerBeads","label":"Prayer beads"},{"value":"crystalPendant","label":"Crystal pendant"},{"value":"boneNecklace","label":"Bone necklace"},{"value":"fangNecklace","label":"Fang necklace"},{"value":"orbPendant","label":"Orb pendant"},{"value":"medalCluster","label":"Medal cluster"},{"value":"factionSeal","label":"Faction seal"},{"value":"sacredRelic","label":"Sacred relic"},{"value":"voidLocket","label":"Void locket"}
        ]}
      ]
    },
    {
      "id":"atmosphereV42",
      "label":"V4.2 · Pogoda i atmosfera",
      "group":"effects",
      "presets":{
        "storm":{"v4.weather":"heavyRain","v4.backgroundEvent":"lightningBranch","v4.ambientOverlay":"stormClouds"},
        "inferno":{"v4.backFlames":"hellfire","v4.flameIntensity":6,"v4.weather":"embers","v4.backgroundEvent":"fireBurst"},
        "cosmic":{"v4.cosmicLayer":"nebula","v4.weather":"meteorShower","v4.backgroundEvent":"starTwinkleBurst"},
        "dream":{"v4.cosmicLayer":"auroraSky","v4.weather":"petals","v4.ambientOverlay":"dreamHaze"}
      },
      "fields":[
        {"id":"v4.weather","label":"Pogoda","type":"select","options":[
          {"value":"none","label":"None"},{"value":"rain","label":"Rain"},{"value":"heavyRain","label":"Heavy rain"},{"value":"snow","label":"Snow"},{"value":"blizzard","label":"Blizzard"},{"value":"embers","label":"Embers"},{"value":"ash","label":"Ash"},{"value":"dust","label":"Dust"},{"value":"fog","label":"Fog"},{"value":"mist","label":"Mist"},{"value":"fallingLeaves","label":"Falling leaves"},{"value":"petals","label":"Petals"},{"value":"sparks","label":"Sparks"},{"value":"bubbles","label":"Bubbles"},{"value":"sandstorm","label":"Sandstorm"},{"value":"lightDrizzle","label":"Light drizzle"},{"value":"meteorShower","label":"Meteor shower"},{"value":"fireflies","label":"Fireflies"},{"value":"pollen","label":"Pollen"},{"value":"glitchNoise","label":"Glitch noise"},{"value":"magicDust","label":"Magic dust"}
        ]},
        {"id":"v4.weatherDensity","label":"Gęstość pogody","type":"range","min":0,"max":6,"step":1,"auto":[1,5]},
        {"id":"v4.weatherDrift","label":"Dryf pogody","type":"range","min":-4,"max":4,"step":1,"auto":[-2,2]},
        {"id":"v4.weatherDepth","label":"Warstwy pogody","type":"range","min":0,"max":4,"step":1,"auto":[1,3]},
        {"id":"v4.backgroundEvent","label":"Zdarzenie tła","type":"select","options":[
          {"value":"none","label":"None"},{"value":"lightningFlash","label":"Lightning flash"},{"value":"lightningBranch","label":"Lightning branch"},{"value":"sunPulse","label":"Sun pulse"},{"value":"moonGlow","label":"Moon glow"},{"value":"fireBurst","label":"Fire burst"},{"value":"lavaPulse","label":"Lava pulse"},{"value":"portalPulse","label":"Portal pulse"},{"value":"neonFlicker","label":"Neon flicker"},{"value":"screenScan","label":"Screen scan"},{"value":"alarmFlash","label":"Alarm flash"},{"value":"cometPass","label":"Comet pass"},{"value":"starTwinkleBurst","label":"Star twinkle burst"},{"value":"eclipsePulse","label":"Eclipse pulse"},{"value":"ghostPass","label":"Ghost pass"},{"value":"shadowSweep","label":"Shadow sweep"}
        ]},
        {"id":"v4.eventFrequency","label":"Częstotliwość zdarzeń","type":"range","min":1,"max":8,"step":1,"auto":[2,6]},
        {"id":"v4.eventIntensity","label":"Intensywność zdarzeń","type":"range","min":0,"max":5,"step":1,"auto":[1,4]},
        {"id":"v4.cosmicLayer","label":"Warstwa kosmiczna","type":"select","options":[
          {"value":"none","label":"None"},{"value":"starsSparse","label":"Stars sparse"},{"value":"starsDense","label":"Stars dense"},{"value":"nebula","label":"Nebula"},{"value":"galaxySwirl","label":"Galaxy swirl"},{"value":"planets","label":"Planets"},{"value":"moonAndStars","label":"Moon and stars"},{"value":"shootingStars","label":"Shooting stars"},{"value":"comets","label":"Comets"},{"value":"constellation","label":"Constellation"},{"value":"auroraSky","label":"Aurora sky"},{"value":"blackHole","label":"Black hole"},{"value":"asteroidField","label":"Asteroid field"},{"value":"ringPlanet","label":"Ring planet"},{"value":"cosmicDust","label":"Cosmic dust"},{"value":"holographicStars","label":"Holographic stars"}
        ]},
        {"id":"v4.cosmicDensity","label":"Gęstość kosmosu","type":"range","min":0,"max":6,"step":1,"auto":[1,5]},
        {"id":"v4.backFlames","label":"Ogień za postacią","type":"select","options":[
          {"value":"none","label":"None"},{"value":"smallFlames","label":"Small flames"},{"value":"wideFlames","label":"Wide flames"},{"value":"ritualFire","label":"Ritual fire"},{"value":"blueFire","label":"Blue fire"},{"value":"greenFire","label":"Green fire"},{"value":"hellfire","label":"Hellfire"},{"value":"torchGlow","label":"Torch glow"},{"value":"energyFire","label":"Energy fire"},{"value":"smokeAndFire","label":"Smoke and fire"}
        ]},
        {"id":"v4.flameHeight","label":"Wysokość płomieni","type":"range","min":0,"max":8,"step":1,"auto":[2,7]},
        {"id":"v4.flameIntensity","label":"Intensywność płomieni","type":"range","min":0,"max":6,"step":1,"auto":[1,5]},
        {"id":"v4.flameFlicker","label":"Migotanie płomieni","type":"range","min":0,"max":6,"step":1,"auto":[1,5]},
        {"id":"v4.ambientOverlay","label":"Nakładka atmosferyczna","type":"select","options":[
          {"value":"none","label":"None"},{"value":"softFog","label":"Soft fog"},{"value":"deepFog","label":"Deep fog"},{"value":"stormClouds","label":"Storm clouds"},{"value":"heatHaze","label":"Heat haze"},{"value":"dreamHaze","label":"Dream haze"},{"value":"voidVeil","label":"Void veil"},{"value":"holyLight","label":"Holy light"},{"value":"toxicCloud","label":"Toxic cloud"},{"value":"dustVeil","label":"Dust veil"},{"value":"underwaterLight","label":"Underwater light"},{"value":"neonMist","label":"Neon mist"}
        ]},
        {"id":"v4.ambientDensity","label":"Gęstość atmosfery","type":"range","min":0,"max":6,"step":1,"auto":[1,5]}
      ]
    },
    {
      "id":"motionV42",
      "label":"V4.2 · Ruch ekspresyjny",
      "group":"effects",
      "presets":{
        "talking":{"v4.poseMotion":"breathe","v4.gazeMotion":"leftRight","v4.browMotion":"bounce","v4.faceAnimation":"talk","v4.mouthMotionStyle":"talkNormal"},
        "dramatic":{"v4.poseMotion":"headTilt","v4.gazeMotion":"suspicious","v4.browMotion":"raiseLeft","v4.eventMotion":"haloPulse"}
      },
      "fields":[
        {"id":"v4.poseMotion","label":"Ruch pozy","type":"select","options":[
          {"value":"none","label":"None"},{"value":"headNod","label":"Head nod"},{"value":"headTilt","label":"Head tilt"},{"value":"tinyShake","label":"Tiny shake"},{"value":"proudPose","label":"Proud pose"},{"value":"shyLookAway","label":"Shy look away"},{"value":"breathe","label":"Breathe"}
        ]},
        {"id":"v4.gazeMotion","label":"Ruch spojrzenia","type":"select","options":[
          {"value":"none","label":"None"},{"value":"leftRight","label":"Left right"},{"value":"lookUp","label":"Look up"},{"value":"lookDown","label":"Look down"},{"value":"suspicious","label":"Suspicious"},{"value":"curious","label":"Curious"}
        ]},
        {"id":"v4.browMotion","label":"Ruch brwi","type":"select","options":[
          {"value":"none","label":"None"},{"value":"raiseLeft","label":"Raise left"},{"value":"raiseRight","label":"Raise right"},{"value":"bounce","label":"Bounce"},{"value":"angry","label":"Angry"},{"value":"sad","label":"Sad"}
        ]},
        {"id":"v4.eventMotion","label":"Ruch efektu","type":"select","options":[
          {"value":"none","label":"None"},{"value":"haloPulse","label":"Halo pulse"},{"value":"haloOrbit","label":"Halo orbit"},{"value":"symbolOrbit","label":"Symbol orbit"},{"value":"flameSurge","label":"Flame surge"},{"value":"lightning","label":"Lightning"}
        ]},
        {"id":"v4.motionIntensity","label":"Intensywność ruchu","type":"range","min":0,"max":5,"step":1,"auto":[1,4]},
        {"id":"v4.motionSpeed","label":"Szybkość ruchu","type":"range","min":1,"max":6,"step":1,"auto":[2,4]},
        {"id":"v4.motionPhaseOffset","label":"Przesunięcie fazy","type":"range","min":0,"max":31,"step":1,"auto":[0,31]}
      ]
    }
  ]
}
''';
