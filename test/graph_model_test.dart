import 'package:flutter_test/flutter_test.dart';
import 'package:untools/patterns/graph/graph_model.dart';

void main() {
  group('GraphNode', () {
    test('round-trips through a record', () {
      const node = GraphNode(
        id: 'n1',
        label: 'Rework',
        slotId: 'methods',
        fixed: true,
      );

      final restored = GraphNode.fromRecord(node.toRecord());

      expect(restored.id, 'n1');
      expect(restored.label, 'Rework');
      expect(restored.slotId, 'methods');
      expect(restored.fixed, isTrue);
    });

    test('defaults every field when the record is empty', () {
      // A record from a newer build can be missing keys this one expects;
      // rendering it beats throwing on load.
      final node = GraphNode.fromRecord(const {});

      expect(node.id, '');
      expect(node.label, '');
      expect(node.slotId, isNull);
      expect(node.fixed, isFalse);
    });

    test('ignores a value stored with the wrong type', () {
      // Hand-edited exports and future record shapes both land here. Throwing
      // would take out the whole session screen for one bad field.
      final node = GraphNode.fromRecord(const {
        'id': 7,
        'label': ['a'],
        'slotId': 3,
        'fixed': 'yes',
      });

      expect(node.id, '');
      expect(node.label, '');
      expect(node.slotId, isNull);
      expect(node.fixed, isFalse);
    });

    test('copyWith replaces the label and keeps everything else', () {
      const node = GraphNode(
        id: 'n1',
        label: 'Old',
        slotId: 'people',
        fixed: true,
      );

      final edited = node.copyWith(label: 'New');

      expect(edited.label, 'New');
      expect(edited.id, 'n1');
      expect(edited.slotId, 'people');
      expect(edited.fixed, isTrue);
    });

    test('copyWith with no argument leaves the label alone', () {
      const node = GraphNode(id: 'n1', label: 'Same');

      expect(node.copyWith().label, 'Same');
    });
  });

  group('GraphEdge', () {
    test('round-trips a signed edge', () {
      const edge = GraphEdge(
        from: 'a',
        to: 'b',
        label: 'drives',
        sign: EdgeSign.negative,
      );

      final restored = GraphEdge.fromRecord(edge.toRecord());

      expect(restored.from, 'a');
      expect(restored.to, 'b');
      expect(restored.label, 'drives');
      expect(restored.sign, EdgeSign.negative);
    });

    test('omits the sign when polarity does not apply', () {
      // A concept map's links have no polarity; writing `sign: ''` would put a
      // meaningless key in every stored record.
      const edge = GraphEdge(from: 'a', to: 'b', label: 'is a kind of');

      expect(edge.toRecord().containsKey('sign'), isFalse);
    });

    test('writes the sign as the glyph the exporter prints', () {
      const edge = GraphEdge(from: 'a', to: 'b', sign: EdgeSign.positive);

      expect(edge.toRecord()['sign'], '+');
    });

    test('defaults every field when the record is empty', () {
      final edge = GraphEdge.fromRecord(const {});

      expect(edge.from, '');
      expect(edge.to, '');
      expect(edge.label, '');
      expect(edge.sign, EdgeSign.none);
    });

    test('ignores values stored with the wrong type', () {
      final edge = GraphEdge.fromRecord(const {
        'from': 1,
        'to': 2,
        'label': false,
        'sign': 9,
      });

      expect(edge.from, '');
      expect(edge.to, '');
      expect(edge.label, '');
      expect(edge.sign, EdgeSign.none);
    });
  });

  group('EdgeSign', () {
    test('parses the glyphs it writes', () {
      expect(EdgeSign.fromGlyph('+'), EdgeSign.positive);
      expect(EdgeSign.fromGlyph('-'), EdgeSign.negative);
    });

    test('falls back to none for anything unrecognised', () {
      expect(EdgeSign.fromGlyph(null), EdgeSign.none);
      expect(EdgeSign.fromGlyph(''), EdgeSign.none);
      expect(EdgeSign.fromGlyph('?'), EdgeSign.none);
    });
  });

  group('list codecs', () {
    test('round-trip a node list', () {
      const nodes = [
        GraphNode(id: 'a', label: 'A'),
        GraphNode(id: 'b', label: 'B'),
      ];

      final restored = nodesFromRecords(nodesToRecords(nodes));

      expect(restored.map((n) => n.id), ['a', 'b']);
    });

    test('round-trip an edge list', () {
      const edges = [
        GraphEdge(from: 'a', to: 'b', sign: EdgeSign.positive),
        GraphEdge(from: 'b', to: 'a', label: 'blocks'),
      ];

      final restored = edgesFromRecords(edgesToRecords(edges));

      expect(restored.map((e) => e.from), ['a', 'b']);
      expect(restored.first.sign, EdgeSign.positive);
      expect(restored.last.label, 'blocks');
    });

    test('read empty lists as empty', () {
      expect(nodesFromRecords(const []), isEmpty);
      expect(edgesFromRecords(const []), isEmpty);
    });
  });

  group('connectedEdges', () {
    const nodes = [
      GraphNode(id: 'a', label: 'A'),
      GraphNode(id: 'b', label: 'B'),
    ];

    test('keeps edges whose ends both exist', () {
      const edges = [GraphEdge(from: 'a', to: 'b')];

      expect(connectedEdges(nodes, edges), hasLength(1));
    });

    test('drops an edge whose target was deleted', () {
      const edges = [GraphEdge(from: 'a', to: 'gone')];

      expect(connectedEdges(nodes, edges), isEmpty);
    });

    test('drops an edge whose source was deleted', () {
      const edges = [GraphEdge(from: 'gone', to: 'b')];

      expect(connectedEdges(nodes, edges), isEmpty);
    });

    test('keeps a self-loop', () {
      const edges = [GraphEdge(from: 'a', to: 'a')];

      expect(connectedEdges(nodes, edges), hasLength(1));
    });

    test('leaves the stored list untouched so a deletion stays undoable', () {
      const edges = [GraphEdge(from: 'a', to: 'gone')];

      connectedEdges(nodes, edges);

      expect(edges, hasLength(1));
    });
  });
}
