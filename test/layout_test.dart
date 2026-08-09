import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/patterns/graph/graph_model.dart';
import 'package:untools/patterns/graph/layout.dart';

List<GraphNode> nodesFor(int count) => [
  for (var i = 0; i < count; i++) GraphNode(id: '$i', label: 'Node $i'),
];

const canvas = Size(800, 600);

List<PlacedNode> place(GraphVariant variant, int count, [Size size = canvas]) =>
    layoutGraph(variant: variant, nodes: nodesFor(count), size: size);

void main() {
  group('every variant', () {
    test('places one point per node, in order', () {
      for (final variant in GraphVariant.values) {
        final placed = place(variant, 5);

        expect(placed, hasLength(5), reason: '$variant');
        expect(
          placed.map((p) => p.node.id),
          ['0', '1', '2', '3', '4'],
          reason: '$variant',
        );
      }
    });

    test('places nothing for an empty graph', () {
      for (final variant in GraphVariant.values) {
        expect(place(variant, 0), isEmpty, reason: '$variant');
      }
    });

    test('keeps every node inside the canvas', () {
      for (final variant in GraphVariant.values) {
        for (final placed in place(variant, 6)) {
          expect(placed.center.dx, inInclusiveRange(0, canvas.width));
          expect(placed.center.dy, inInclusiveRange(0, canvas.height));
        }
      }
    });

    test('is deterministic — same input, same points', () {
      for (final variant in GraphVariant.values) {
        final first = place(variant, 4);
        final second = place(variant, 4);

        expect(
          first.map((p) => p.center),
          second.map((p) => p.center),
          reason: '$variant',
        );
      }
    });

    test('re-lays out for a smaller canvas rather than clipping', () {
      // The whole reason positions are computed and never stored: a diagram
      // arranged at 1366 wide must still fit at 1024x600.
      for (final variant in GraphVariant.values) {
        const small = Size(400, 300);
        for (final placed in place(variant, 5, small)) {
          expect(placed.center.dx, inInclusiveRange(0, small.width));
          expect(placed.center.dy, inInclusiveRange(0, small.height));
        }
      }
    });

    test('survives a canvas too small for the node radius', () {
      for (final variant in GraphVariant.values) {
        final placed = place(variant, 3, const Size(20, 20));

        expect(placed, hasLength(3), reason: '$variant');
        for (final p in placed) {
          expect(p.center.dx.isFinite, isTrue);
          expect(p.center.dy.isFinite, isTrue);
        }
      }
    });
  });

  group('circle', () {
    test('starts at twelve o clock and runs clockwise', () {
      final placed = place(GraphVariant.circle, 4);
      const center = Offset(400, 300);

      expect(placed[0].center.dx, closeTo(center.dx, 0.01));
      expect(placed[0].center.dy, lessThan(center.dy));
      // Second node is to the right: clockwise, not counter-clockwise.
      expect(placed[1].center.dx, greaterThan(center.dx));
      expect(placed[1].center.dy, closeTo(center.dy, 0.01));
    });

    test('spaces nodes evenly', () {
      final placed = place(GraphVariant.circle, 6);
      final gaps = [
        for (var i = 0; i < placed.length; i++)
          (placed[(i + 1) % placed.length].center - placed[i].center).distance,
      ];

      for (final gap in gaps) {
        expect(gap, closeTo(gaps.first, 0.01));
      }
    });

    test('centres a lone node instead of orbiting it', () {
      final placed = place(GraphVariant.circle, 1);

      expect(placed.single.center, const Offset(400, 300));
    });
  });

  group('fishbone', () {
    test('puts the effect at the head of the spine, on the right', () {
      final placed = place(GraphVariant.fishbone, 5);

      expect(placed.first.center.dy, closeTo(300, 0.01));
      for (final rib in placed.skip(1)) {
        expect(rib.center.dx, lessThan(placed.first.center.dx));
      }
    });

    test('alternates ribs above and below the spine', () {
      final placed = place(GraphVariant.fishbone, 5).skip(1).toList();

      expect(placed[0].center.dy, lessThan(300));
      expect(placed[1].center.dy, greaterThan(300));
      expect(placed[2].center.dy, lessThan(300));
      expect(placed[3].center.dy, greaterThan(300));
    });

    test('spreads ribs along the spine without stacking them', () {
      final xs = [
        for (final p in place(GraphVariant.fishbone, 5).skip(1)) p.center.dx,
      ];

      expect(xs.toSet(), hasLength(xs.length));
    });

    test('handles an effect with no categories yet', () {
      expect(place(GraphVariant.fishbone, 1), hasLength(1));
    });
  });

  group('cloud', () {
    test('reads left to right: objective, needs, proposals', () {
      final placed = place(GraphVariant.cloud, 5);

      expect(placed[0].center.dx, lessThan(placed[1].center.dx));
      expect(placed[1].center.dx, lessThan(placed[3].center.dx));
      // The two needs share a column, as do the two proposals.
      expect(placed[1].center.dx, closeTo(placed[2].center.dx, 0.01));
      expect(placed[3].center.dx, closeTo(placed[4].center.dx, 0.01));
      // Each pair straddles the objective vertically.
      expect(placed[1].center.dy, lessThan(placed[2].center.dy));
    });

    test('places an unexpected sixth node rather than dropping it', () {
      // Unreachable through the UI, but a session from a newer build could
      // carry one and must still render.
      final placed = place(GraphVariant.cloud, 6);

      expect(placed, hasLength(6));
      expect(placed.last.center.dy, greaterThan(placed.first.center.dy));
    });
  });

  group('free', () {
    test('wraps into rows once a row is full', () {
      final placed = place(GraphVariant.free, 12, const Size(400, 600));
      final rows = placed.map((p) => p.center.dy).toSet();

      expect(rows.length, greaterThan(1));
    });

    test('keeps one row on a wide canvas', () {
      final placed = place(GraphVariant.free, 3, const Size(1200, 400));

      expect(placed.map((p) => p.center.dy).toSet(), hasLength(1));
    });
  });
}
