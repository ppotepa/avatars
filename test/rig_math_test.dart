import 'package:avatar_genome/src/geometry/point.dart';
import 'package:avatar_genome/src/rendering/rig_model.dart';
import 'package:avatar_genome/src/rendering/rig_transform_solver.dart';
import 'package:test/test.dart';

void main() {
  test('child world transform respects parent rotation', () {
    final graph = RigGraph(nodes: const <RigNode>[
      RigNode(
        id: 'parent',
        parentId: null,
        slot: RenderSlot.torsoClothing,
        restTransform: RigTransform(
          rotationDegrees: 90,
          pivotX: 0,
          pivotY: 0,
        ),
      ),
      RigNode(
        id: 'child',
        parentId: 'parent',
        slot: RenderSlot.head,
      ),
    ]);
    final pose = RigPose(<String, RigTransform>{
      'child': const RigTransform(dx: 4),
    });
    final matrices = const RigWorldResolver().resolveMatrices(graph, pose);
    final point = matrices['child']!.transformPoint(const PixelPoint(0, 0));
    expect(point.x.abs(), lessThanOrEqualTo(1));
    expect(point.y, 4);
  });

  test('attach constraint keeps child root on parent anchor', () {
    final graph = _attachGraph();
    final solved = const RigConstraintSolver().solve(
      graph,
      RigPose(<String, RigTransform>{
        'child': const RigTransform(dx: 5, dy: 3),
      }),
    );
    _expectAnchorsAttached(graph, solved);
  });

  test('attach correction is converted through a rotated parent', () {
    final graph = _attachGraph();
    final solved = const RigConstraintSolver().solve(
      graph,
      RigPose(<String, RigTransform>{
        'parent': const RigTransform(
          rotationDegrees: 35,
          pivotX: 10,
          pivotY: 10,
        ),
        'child': const RigTransform(dx: 6, dy: -4),
      }),
    );
    _expectAnchorsAttached(graph, solved);
  });

  test('fixed-distance constraint caps an overstretched child', () {
    final graph = RigGraph(
      nodes: const <RigNode>[
        RigNode(
          id: 'root',
          parentId: null,
          slot: RenderSlot.torsoClothing,
        ),
        RigNode(
          id: 'pendant',
          parentId: 'root',
          slot: RenderSlot.frontArms,
        ),
      ],
      anchors: const <RigAnchor>[
        RigAnchor(
          id: 'root.anchor',
          nodeId: 'root',
          localPosition: PixelPoint(0, 0),
        ),
        RigAnchor(
          id: 'pendant.center',
          nodeId: 'pendant',
          localPosition: PixelPoint(10, 0),
        ),
      ],
      constraints: const <RigConstraint>[
        RigConstraint(
          id: 'chain',
          kind: RigConstraintKind.fixedDistance,
          nodeIds: <String>['root', 'pendant'],
          anchorIds: <String>['root.anchor', 'pendant.center'],
          minimum: 6,
          maximum: 12,
        ),
      ],
    );
    final solved = const RigConstraintSolver().solve(
      graph,
      RigPose(<String, RigTransform>{
        'pendant': const RigTransform(dx: 20),
      }),
    );
    final resolver = const RigWorldResolver();
    final root = resolver.worldAnchor(graph, solved, 'root.anchor');
    final pendant = resolver.worldAnchor(graph, solved, 'pendant.center');
    final dx = pendant.x - root.x;
    final dy = pendant.y - root.y;
    expect(dx * dx + dy * dy, lessThanOrEqualTo(12 * 12 + 2));
  });
}

RigGraph _attachGraph() => RigGraph(
      nodes: const <RigNode>[
        RigNode(
          id: 'parent',
          parentId: null,
          slot: RenderSlot.torsoClothing,
        ),
        RigNode(
          id: 'child',
          parentId: 'parent',
          slot: RenderSlot.head,
        ),
      ],
      anchors: const <RigAnchor>[
        RigAnchor(
          id: 'parent.anchor',
          nodeId: 'parent',
          localPosition: PixelPoint(10, 10),
        ),
        RigAnchor(
          id: 'child.root',
          nodeId: 'child',
          localPosition: PixelPoint(10, 10),
        ),
      ],
      constraints: const <RigConstraint>[
        RigConstraint(
          id: 'attachment',
          kind: RigConstraintKind.attach,
          nodeIds: <String>['parent', 'child'],
          anchorIds: <String>['parent.anchor', 'child.root'],
        ),
      ],
    );

void _expectAnchorsAttached(RigGraph graph, RigPose pose) {
  final resolver = const RigWorldResolver();
  final first = resolver.worldAnchor(graph, pose, 'parent.anchor');
  final second = resolver.worldAnchor(graph, pose, 'child.root');
  expect((second.x - first.x).abs(), lessThanOrEqualTo(1));
  expect((second.y - first.y).abs(), lessThanOrEqualTo(1));
}
