import 'package:flutter_test/flutter_test.dart';
import 'package:untools/patterns/graph/cycles.dart';
import 'package:untools/patterns/graph/graph_model.dart';

List<GraphNode> nodesFor(List<String> ids) => [
  for (final id in ids) GraphNode(id: id, label: id.toUpperCase()),
];

GraphEdge link(String from, String to, [EdgeSign sign = EdgeSign.none]) =>
    GraphEdge(from: from, to: to, sign: sign);

void main() {
  group('findLoops', () {
    test('finds nothing in a graph with no edges', () {
      expect(findLoops(nodesFor(['a', 'b']), const []), isEmpty);
    });

    test('finds nothing in an acyclic chain', () {
      final loops = findLoops(nodesFor(['a', 'b', 'c']), [
        link('a', 'b'),
        link('b', 'c'),
      ]);

      expect(loops, isEmpty);
    });

    test('finds a two-node cycle', () {
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b'),
        link('b', 'a'),
      ]);

      expect(loops, hasLength(1));
      expect(loops.single.nodeIds, ['a', 'b']);
    });

    test('counts a self-loop as a one-node cycle', () {
      // A node that feeds itself is a real feedback loop in a causal diagram,
      // not a drawing error, so it must be reported rather than skipped.
      final loops = findLoops(nodesFor(['a']), [link('a', 'a')]);

      expect(loops, hasLength(1));
      expect(loops.single.nodeIds, ['a']);
    });

    test('reports a cycle once rather than once per rotation', () {
      // a>b>c>a, b>c>a>b and c>a>b>c are the same loop; the canonical-start
      // rule is what collapses them.
      final loops = findLoops(nodesFor(['a', 'b', 'c']), [
        link('a', 'b'),
        link('b', 'c'),
        link('c', 'a'),
      ]);

      expect(loops, hasLength(1));
      expect(loops.single.nodeIds, ['a', 'b', 'c']);
    });

    test('finds both loops when two share a node', () {
      final loops = findLoops(nodesFor(['a', 'b', 'c']), [
        link('a', 'b'),
        link('b', 'a'),
        link('a', 'c'),
        link('c', 'a'),
      ]);

      expect(loops.map((l) => l.signature), ['a>b', 'a>c']);
    });

    test('finds loops in separate disconnected components', () {
      final loops = findLoops(nodesFor(['a', 'b', 'x', 'y']), [
        link('a', 'b'),
        link('b', 'a'),
        link('x', 'y'),
        link('y', 'x'),
      ]);

      expect(loops.map((l) => l.signature), ['a>b', 'x>y']);
    });

    test('treats parallel edges between one pair as one cycle spelling', () {
      // Two arrows a>b plus one b>a close the same node sequence twice; the
      // signature dedupe keeps a single loop rather than reporting a phantom.
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b'),
        link('a', 'b', EdgeSign.negative),
        link('b', 'a'),
      ]);

      expect(loops, hasLength(1));
    });

    test('ignores an edge pointing at a node that no longer exists', () {
      // Matches the exporter, which prints `?` rather than throwing.
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b'),
        link('b', 'gone'),
        link('gone', 'a'),
      ]);

      expect(loops, isEmpty);
    });

    test('orders shorter loops before longer ones', () {
      final loops = findLoops(nodesFor(['a', 'b', 'c', 'd']), [
        link('a', 'b'),
        link('b', 'c'),
        link('c', 'd'),
        link('d', 'a'),
        link('b', 'a'),
      ]);

      expect(loops.map((l) => l.nodeIds.length), [2, 4]);
    });

    test('does not depend on the order nodes sit in the slot', () {
      final edges = [link('a', 'b'), link('b', 'c'), link('c', 'a')];

      final forward = findLoops(nodesFor(['a', 'b', 'c']), edges);
      final shuffled = findLoops(nodesFor(['c', 'a', 'b']), edges);

      expect(forward.single.signature, shuffled.single.signature);
    });
  });

  group('polarity', () {
    test('an all-positive loop is reinforcing', () {
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b', EdgeSign.positive),
        link('b', 'a', EdgeSign.positive),
      ]);

      expect(loops.single.reinforcing, isTrue);
      expect(loops.single.label, 'Reinforcing');
    });

    test('one negative link makes a loop balancing', () {
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b', EdgeSign.positive),
        link('b', 'a', EdgeSign.negative),
      ]);

      expect(loops.single.reinforcing, isFalse);
      expect(loops.single.label, 'Balancing');
    });

    test('two negative links cancel back to reinforcing', () {
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b', EdgeSign.negative),
        link('b', 'a', EdgeSign.negative),
      ]);

      expect(loops.single.reinforcing, isTrue);
    });

    test('three negative links are balancing again', () {
      final loops = findLoops(nodesFor(['a', 'b', 'c']), [
        link('a', 'b', EdgeSign.negative),
        link('b', 'c', EdgeSign.negative),
        link('c', 'a', EdgeSign.negative),
      ]);

      expect(loops.single.reinforcing, isFalse);
    });

    test('unsigned links count as neutral, so the loop reinforces', () {
      final loops = findLoops(nodesFor(['a', 'b']), [
        link('a', 'b'),
        link('b', 'a'),
      ]);

      expect(loops.single.reinforcing, isTrue);
    });

    test('polarity is counted per loop, not across the whole graph', () {
      // The negative on the a>c>a loop must not flip the a>b>a loop.
      final loops = findLoops(nodesFor(['a', 'b', 'c']), [
        link('a', 'b', EdgeSign.positive),
        link('b', 'a', EdgeSign.positive),
        link('a', 'c', EdgeSign.negative),
        link('c', 'a', EdgeSign.positive),
      ]);

      expect(
        {
          for (final loop in loops) loop.signature: loop.reinforcing,
        },
        {'a>b': true, 'a>c': false},
      );
    });
  });
}
