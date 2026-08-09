/// Finding the feedback loops in a connection circle, and naming them.
///
/// This is the part of the systems-thinking method the app can actually
/// compute. Drawing the circle is the user's job; noticing that four of their
/// arrows close into a reinforcing loop is the machine's, and it is exactly
/// the step people miss by eye.
///
/// Flutter-free: no widget imports here, so this stays fully unit-testable.
library;

import 'package:untools/patterns/graph/graph_model.dart';

/// A closed path through the graph, with its polarity resolved.
class FeedbackLoop {
  /// Creates a loop.
  const FeedbackLoop({required this.nodeIds, required this.reinforcing});

  /// Node ids in traversal order, each linking to the next and the last back
  /// to the first. The first id is the lowest in the cycle, so the same loop
  /// discovered from a different starting node compares equal.
  final List<String> nodeIds;

  /// Whether the loop amplifies itself.
  ///
  /// An even number of negative links (including none) is reinforcing: each
  /// pair of negatives cancels. An odd number is balancing — the loop pushes
  /// back against its own change, which is what makes a system hold steady.
  final bool reinforcing;

  /// How the loop is labelled in the UI and the export.
  String get label => reinforcing ? 'Reinforcing' : 'Balancing';

  /// Stable identity used to deduplicate rotations of the same cycle.
  String get signature => nodeIds.join('>');
}

/// Every distinct simple cycle in the graph, shortest first.
///
/// Dangling edges are ignored via [connectedEdges], matching the exporter's
/// tolerance for an edge that outlived its node. Self-loops (an edge from a
/// node to itself) count: in a causal diagram they are a real, and usually
/// important, one-node feedback loop.
///
/// Cycles are enumerated with a depth-first walk that only starts from, and
/// only revisits, nodes at or above the starting id. That restriction is what
/// makes each cycle surface exactly once rather than once per rotation.
List<FeedbackLoop> findLoops(List<GraphNode> nodes, List<GraphEdge> edges) {
  final live = connectedEdges(nodes, edges);
  final outgoing = <String, List<GraphEdge>>{};
  for (final edge in live) {
    outgoing.putIfAbsent(edge.from, () => []).add(edge);
  }

  final found = <String, FeedbackLoop>{};
  // Sorted so the traversal order — and therefore the reported loop order —
  // does not depend on the order nodes happen to sit in the session slot.
  final startIds = [for (final node in nodes) node.id]..sort();

  for (final start in startIds) {
    final path = <String>[start];
    final negatives = <int>[0];

    void walk(String current) {
      for (final edge in outgoing[current] ?? const <GraphEdge>[]) {
        if (edge.sign == EdgeSign.negative) negatives[0]++;

        if (edge.to == start) {
          final loop = FeedbackLoop(
            nodeIds: List.of(path),
            reinforcing: negatives[0].isEven,
          );
          // A rotation of an already-found cycle keeps whichever spelling was
          // reached first; the canonical-start rule below means that is the
          // one beginning at the lowest id.
          found.putIfAbsent(loop.signature, () => loop);
        } else if (edge.to.compareTo(start) > 0 && !path.contains(edge.to)) {
          // Only walk forward to higher ids: a cycle through a lower id will
          // be found (once) when that lower id is itself the start.
          path.add(edge.to);
          walk(edge.to);
          path.removeLast();
        }

        if (edge.sign == EdgeSign.negative) negatives[0]--;
      }
    }

    walk(start);
  }

  final loops = found.values.toList()
    ..sort((a, b) {
      final byLength = a.nodeIds.length.compareTo(b.nodeIds.length);
      return byLength != 0 ? byLength : a.signature.compareTo(b.signature);
    });
  return loops;
}
