/// Where each node sits, and which one a tap landed on.
///
/// **Positions are computed, never stored.** The user edits labels and links;
/// the layout owns coordinates. Three things follow, and all three are the
/// reason for the rule:
///
/// * There is no drag affordance, so there is no drag to mirror with a
///   keyboard path — the pointer-free requirement is satisfied by
///   construction rather than by a parallel implementation.
/// * A session re-lays out at any size, so a diagram arranged on a 1366-wide
///   window is still readable at 1024x600 instead of carrying coordinates that
///   put half of it off-screen.
/// * Sessions stay portable: no pixel values in the stored slots.
///
/// Flutter-free. `Offset` and `Size` come from `dart:ui`, which carries no
/// widget dependency — the same allowance `scoring.dart` relies on.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/patterns/graph/graph_model.dart';

/// Radius of the tappable disc drawn for each node.
const double kNodeRadius = 34;

/// A node paired with the point it was placed at.
class PlacedNode {
  /// Creates a placement.
  const PlacedNode({required this.node, required this.center});

  /// The node being drawn.
  final GraphNode node;

  /// Where its centre sits, in canvas coordinates.
  final Offset center;
}

/// Places every node for [variant] inside [size].
///
/// Returns placements in the same order as [nodes], so a caller can zip the
/// two lists without re-matching on id.
List<PlacedNode> layoutGraph({
  required GraphVariant variant,
  required List<GraphNode> nodes,
  required Size size,
}) => switch (variant) {
  GraphVariant.circle => _circle(nodes, size),
  GraphVariant.fishbone => _fishbone(nodes, size),
  GraphVariant.cloud => _cloud(nodes, size),
  GraphVariant.free => _grid(nodes, size),
};

/// Evenly spaced around a circle, starting at twelve o'clock.
///
/// Starting at the top and running clockwise matches how the method is drawn
/// on paper, which matters when someone is copying a diagram they already have.
List<PlacedNode> _circle(List<GraphNode> nodes, Size size) {
  if (nodes.isEmpty) return const [];
  final center = Offset(size.width / 2, size.height / 2);
  // Inset by the node radius so discs sit inside the canvas, not half over
  // its edge, and never let the radius go negative on a very small canvas.
  final radius = math.max<double>(
    0,
    math.min(size.width, size.height) / 2 - kNodeRadius - 8,
  );

  // A single node has no circle to sit on; centring it reads as intended
  // rather than as a rendering bug.
  if (nodes.length == 1) {
    return [PlacedNode(node: nodes.single, center: center)];
  }

  return [
    for (final (index, node) in nodes.indexed)
      PlacedNode(
        node: node,
        center: Offset(
          center.dx + radius * math.sin(2 * math.pi * index / nodes.length),
          center.dy - radius * math.cos(2 * math.pi * index / nodes.length),
        ),
      ),
  ];
}

/// A horizontal spine with ribs alternating above and below it.
///
/// The first node is the effect and sits at the head of the spine, on the
/// right; the rest are categories fanning back along it. That is the
/// orientation Ishikawa's diagram is conventionally drawn in.
List<PlacedNode> _fishbone(List<GraphNode> nodes, Size size) {
  if (nodes.isEmpty) return const [];
  final spineY = size.height / 2;
  final head = Offset(size.width - kNodeRadius - 8, spineY);
  final ribs = nodes.skip(1).toList();

  final placements = [PlacedNode(node: nodes.first, center: head)];
  if (ribs.isEmpty) return placements;

  // Ribs are distributed along the spine from the tail toward the head, so
  // adding a category shifts spacing rather than colliding with the effect.
  final usable = math.max<double>(0, head.dx - kNodeRadius - 24);
  final step = usable / (ribs.length + 1);
  final offset = math.min<double>(size.height / 2 - kNodeRadius - 8, 90);

  for (final (index, rib) in ribs.indexed) {
    placements.add(
      PlacedNode(
        node: rib,
        center: Offset(
          kNodeRadius + 16 + step * (index + 1),
          // Alternate above and below so consecutive ribs never overlap.
          index.isEven ? spineY - offset : spineY + offset,
        ),
      ),
    );
  }
  return placements;
}

/// The conflict cloud's five fixed slots.
///
/// Objective on the left, the two needs stacked in the middle, the two
/// competing proposals on the right — the shape the method is read in, left to
/// right, so the diagram itself explains the conflict.
List<PlacedNode> _cloud(List<GraphNode> nodes, Size size) {
  const columns = [0.16, 0.5, 0.5, 0.86, 0.86];
  const rows = [0.5, 0.24, 0.76, 0.24, 0.76];

  return [
    for (final (index, node) in nodes.indexed)
      PlacedNode(
        node: node,
        center: index < columns.length
            ? Offset(size.width * columns[index], size.height * rows[index])
            // A sixth node cannot be added through the UI, but a session
            // written by a future build could carry one; place it rather than
            // crash.
            : Offset(size.width / 2, size.height - kNodeRadius - 8),
      ),
  ];
}

/// A wrapped grid, for graphs with no prescribed shape.
List<PlacedNode> _grid(List<GraphNode> nodes, Size size) {
  if (nodes.isEmpty) return const [];
  final perRow = math.max(1, (size.width / (kNodeRadius * 3)).floor());
  final rows = (nodes.length / perRow).ceil();

  return [
    for (final (index, node) in nodes.indexed)
      PlacedNode(
        node: node,
        center: Offset(
          size.width * ((index % perRow) + 1) / (perRow + 1),
          size.height * ((index ~/ perRow) + 1) / (rows + 1),
        ),
      ),
  ];
}
