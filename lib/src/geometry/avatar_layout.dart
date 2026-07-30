import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../graph/avatar_graph.dart';
import '../util/math_utils.dart';
import 'pixel_rect.dart';
import 'point.dart';

final class AvatarSlot {
  const AvatarSlot({
    required this.anchor,
    required this.bounds,
    required this.acceptedCategories,
  });

  final PixelPoint anchor;
  final PixelRect? bounds;
  final List<String> acceptedCategories;

  Map<String, Object?> toJson() => <String, Object?>{
        'anchor': anchor.toJson(),
        'bounds': bounds?.toJson(),
        'acceptedCategories': acceptedCategories,
      };
}

final class AvatarLayout {
  AvatarLayout({
    required this.values,
    required this.landmarks,
    required this.slots,
    required this.graph,
  });

  final Map<String, Object> values;
  final Map<String, PixelPoint> landmarks;
  final Map<String, AvatarSlot> slots;
  final AvatarGraph graph;

  int integer(String id, [int fallback = 0]) {
    final value = values[id];
    return value is num ? value.toInt() : fallback;
  }

  String string(String id, [String fallback = 'none']) {
    final value = values[id];
    return value is String ? value : fallback;
  }
}

abstract interface class LayoutResolver {
  AvatarLayout resolve(AvatarGenome genome, ConstraintEngine guard);
}

final class V41LayoutResolver implements LayoutResolver {
  const V41LayoutResolver();

  @override
  AvatarLayout resolve(AvatarGenome genome, ConstraintEngine guard) {
    final graph = AvatarGraph()
      ..addValue('canvas.width', 'constant', 48)
      ..addValue('canvas.height', 'constant', 48)
      ..addValue('canvas.centerX', 'landmark', 23.5);
    for (final entry in genome.values.entries) {
      graph.addValue(
        entry.key,
        entry.value is String ? 'variant' : 'parameter',
        entry.value,
        meta: genome.sources[entry.key]?.toJson() ?? const <String, Object?>{},
      );
    }
    graph
      ..addDerived(
        'body.shoulderY',
        'landmark',
        const <String>[
          'body.verticalPosition',
          'body.heightBias',
          'shoulders.height'
        ],
        (v) => clampInt(
          35 +
              (v['body.verticalPosition']! as int) +
              (v['body.heightBias']! as int) +
              (v['shoulders.height']! as int),
          32,
          39,
        ),
      )
      ..addDerived(
        'body.neckBaseY',
        'landmark',
        const <String>['body.shoulderY'],
        (v) => (v['body.shoulderY']! as int) + 3,
      )
      ..addDerived(
        'body.neckTopY',
        'landmark',
        const <String>['body.neckBaseY', 'neck.length'],
        (v) => (v['body.neckBaseY']! as int) - (v['neck.length']! as int) + 1,
      )
      ..addDerived(
        'head.bottomY',
        'landmark',
        const <String>['body.neckTopY', 'head.chinDepth'],
        (v) => (v['body.neckTopY']! as int) + 2 + (v['head.chinDepth']! as int),
      )
      ..addDerived(
        'head.maxHeight',
        'constraint',
        const <String>['head.bottomY'],
        (v) => clampInt((v['head.bottomY']! as int) - 1, 18, 48),
      )
      ..addDerived(
        'head.actualHeight',
        'parameter',
        const <String>['head.height', 'head.maxHeight'],
        (v) {
          final before = v['head.height']! as int;
          final max = v['head.maxHeight']! as int;
          return guard.correct(
            'head.height.layout',
            before,
            clampInt(before, 18, max),
            'Head height was fitted to the canvas.',
          );
        },
      )
      ..addDerived(
        'head.topY',
        'landmark',
        const <String>['head.bottomY', 'head.actualHeight'],
        (v) =>
            (v['head.bottomY']! as int) - (v['head.actualHeight']! as int) + 1,
      )
      ..addDerived(
        'head.leftX',
        'landmark',
        const <String>['head.width', 'head.asymmetry'],
        (v) => (23.5 -
                (v['head.width']! as int) / 2 +
                (v['head.asymmetry']! as int) * 0.5)
            .round(),
      )
      ..addDerived(
        'head.rightX',
        'landmark',
        const <String>['head.leftX', 'head.width'],
        (v) => (v['head.leftX']! as int) + (v['head.width']! as int) - 1,
      )
      ..addDerived(
        'face.eyeY',
        'landmark',
        const <String>[
          'head.topY',
          'forehead.height',
          'eyes.positionY',
          'head.actualHeight',
        ],
        (v) => clampInt(
          (v['head.topY']! as int) +
              (v['forehead.height']! as int) +
              4 +
              (v['eyes.positionY']! as int),
          (v['head.topY']! as int) + 6,
          (v['head.topY']! as int) +
              ((v['head.actualHeight']! as int) * 0.58).floor(),
        ),
      )
      ..addDerived(
        'face.leftEyeX',
        'landmark',
        const <String>['canvas.centerX', 'eyes.spacing', 'eyes.width'],
        (v) => ((v['canvas.centerX']! as double) -
                ((v['eyes.spacing']! as int) + (v['eyes.width']! as int)) / 2)
            .round(),
      )
      ..addDerived(
        'face.rightEyeX',
        'landmark',
        const <String>['canvas.centerX', 'eyes.spacing', 'eyes.width'],
        (v) => ((v['canvas.centerX']! as double) +
                ((v['eyes.spacing']! as int) + (v['eyes.width']! as int)) / 2)
            .round(),
      )
      ..addDerived(
        'face.noseTipY',
        'landmark',
        const <String>[
          'face.eyeY',
          'nose.length',
          'nose.positionY',
          'head.bottomY'
        ],
        (v) => clampInt(
          (v['face.eyeY']! as int) +
              ((v['nose.length']! as int) < 2
                  ? 2
                  : (v['nose.length']! as int)) +
              (v['nose.positionY']! as int),
          (v['face.eyeY']! as int) + 2,
          (v['head.bottomY']! as int) - 7,
        ),
      )
      ..addDerived(
        'face.mouthY',
        'landmark',
        const <String>['face.noseTipY', 'mouth.positionY', 'head.bottomY'],
        (v) => clampInt(
          (v['face.noseTipY']! as int) + 3 + (v['mouth.positionY']! as int),
          (v['face.noseTipY']! as int) + 2,
          (v['head.bottomY']! as int) - 3,
        ),
      )
      ..addDerived(
        'ears.centerY',
        'landmark',
        const <String>['face.eyeY', 'face.noseTipY', 'ears.positionY'],
        (v) => (((v['face.eyeY']! as int) + (v['face.noseTipY']! as int)) / 2 +
                (v['ears.positionY']! as int))
            .round(),
      )
      ..addDerived(
        'hair.maxTopVolume',
        'constraint',
        const <String>['head.topY'],
        (v) => clampInt(v['head.topY']! as int, 0, 48),
      )
      ..addDerived(
        'hair.actualTopVolume',
        'parameter',
        const <String>['hair.volumeTop', 'hair.maxTopVolume'],
        (v) {
          final before = v['hair.volumeTop']! as int;
          final max = v['hair.maxTopVolume']! as int;
          return guard.correct(
            'hair.volumeTop.layout',
            before,
            clampInt(before, 0, max),
            'Hair volume was fitted to the canvas.',
          );
        },
      )
      ..addDerived(
        'hair.topY',
        'landmark',
        const <String>['head.topY', 'hair.actualTopVolume'],
        (v) => clampInt(
            (v['head.topY']! as int) - (v['hair.actualTopVolume']! as int),
            0,
            47),
      )
      ..addDerived(
        'torso.topY',
        'landmark',
        const <String>['body.shoulderY', 'torso.height'],
        (v) => (v['body.shoulderY']! as int) < 48 - (v['torso.height']! as int)
            ? (v['body.shoulderY']! as int)
            : 48 - (v['torso.height']! as int),
      )
      ..addEdge('body.neckBaseY', 'neck', 'attachedTo')
      ..addEdge('body.neckTopY', 'head.neckAttach', 'attachedTo')
      ..addEdge('head.topY', 'hair.topY', 'attachedTo')
      ..addEdge('head', 'eyes', 'boundedBy')
      ..addEdge('head', 'nose', 'boundedBy')
      ..addEdge('head', 'mouth', 'boundedBy')
      ..addEdge('hair.front', 'head', 'occludes')
      ..evaluate();

    final values = <String, Object>{
      ...genome.values,
      'seedHash': fnv1a32('${genome.generatorVersion}:${genome.seed}'),
      for (final entry in graph.nodes.entries)
        if (entry.value.value != null) entry.key: entry.value.value!,
    };
    final landmarks = <String, PixelPoint>{
      'body.shoulderCenter': PixelPoint(24, values['body.shoulderY']! as int),
      'body.neckBase': PixelPoint(
        24 + (values['neck.offsetX']! as int),
        values['body.neckBaseY']! as int,
      ),
      'body.neckTop': PixelPoint(
        24 + (values['neck.offsetX']! as int),
        values['body.neckTopY']! as int,
      ),
      'head.neckAttach': PixelPoint(24, (values['head.bottomY']! as int) - 1),
      'face.leftEye': PixelPoint(
        values['face.leftEyeX']! as int,
        values['face.eyeY']! as int,
      ),
      'face.rightEye': PixelPoint(
        values['face.rightEyeX']! as int,
        values['face.eyeY']! as int,
      ),
      'face.noseTip': PixelPoint(24, values['face.noseTipY']! as int),
      'face.mouth': PixelPoint(24, values['face.mouthY']! as int),
      'hair.top': PixelPoint(24, values['hair.topY']! as int),
      'v4.shoulderLeft': const PixelPoint(8, 34),
      'v4.shoulderRight': const PixelPoint(39, 34),
      'v4.back': const PixelPoint(24, 37),
      'v4.forehead': PixelPoint(24, (values['face.eyeY']! as int) - 5),
    };
    final slots = <String, AvatarSlot>{
      'headwear': AvatarSlot(
        anchor: landmarks['hair.top']!,
        bounds: PixelRect(
          clampInt((values['head.leftX']! as int) - 4, 0, 47),
          0,
          clampInt((values['head.width']! as int) + 8, 1, 48),
          14,
        ),
        acceptedCategories: const <String>['hat', 'crown', 'helmet'],
      ),
      'eyewear': AvatarSlot(
        anchor: PixelPoint(24, values['face.eyeY']! as int),
        bounds: PixelRect(
          (values['head.leftX']! as int) + 1,
          (values['face.eyeY']! as int) - 3,
          (values['head.width']! as int) - 2,
          7,
        ),
        acceptedCategories: const <String>['glasses', 'mask'],
      ),
      'mouthProp': AvatarSlot(
        anchor: landmarks['face.mouth']!,
        bounds: PixelRect(10, (values['face.mouthY']! as int) - 3, 28, 9),
        acceptedCategories: const <String>['mouthProp'],
      ),
      'shoulderLeft': const AvatarSlot(
        anchor: PixelPoint(8, 34),
        bounds: PixelRect(0, 25, 17, 23),
        acceptedCategories: <String>['shoulderProp'],
      ),
      'shoulderRight': const AvatarSlot(
        anchor: PixelPoint(39, 34),
        bounds: PixelRect(31, 25, 17, 23),
        acceptedCategories: <String>['shoulderProp'],
      ),
      'back': const AvatarSlot(
        anchor: PixelPoint(24, 37),
        bounds: PixelRect(0, 20, 48, 28),
        acceptedCategories: <String>['cape', 'backProp', 'wings'],
      ),
    };
    return AvatarLayout(
      values: Map.unmodifiable(values),
      landmarks: Map.unmodifiable(landmarks),
      slots: Map.unmodifiable(slots),
      graph: graph,
    );
  }
}
