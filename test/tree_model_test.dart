import 'package:flutter_test/flutter_test.dart';
import 'package:untools/patterns/tree/tree_model.dart';

/// Builds a small tree:
///   root
///     a
///       a1
///     b
List<TreeNode> sampleTree() => const [
  TreeNode(id: 'root', label: 'Root'),
  TreeNode(id: 'a', label: 'A', parentId: 'root'),
  TreeNode(id: 'a1', label: 'A1', parentId: 'a'),
  TreeNode(id: 'b', label: 'B', parentId: 'root'),
];

void main() {
  group('TreeNode records', () {
    test('round-trips through its stored form', () {
      const node = TreeNode(
        id: 'n',
        label: 'Label',
        parentId: 'p',
        mece: true,
      );

      final restored = TreeNode.fromRecord(node.toRecord());

      expect(restored.id, 'n');
      expect(restored.label, 'Label');
      expect(restored.parentId, 'p');
      expect(restored.mece, isTrue);
    });

    test('tolerates a record with fields missing', () {
      // Stored sessions outlive the code that wrote them.
      final node = TreeNode.fromRecord(const {});

      expect(node.id, '');
      expect(node.label, '');
      expect(node.parentId, isNull);
      expect(node.mece, isFalse);
    });

    test('copyWith replaces only what is given', () {
      const node = TreeNode(id: 'n', label: 'Old', parentId: 'p');

      final renamed = node.copyWith(label: 'New');

      expect(renamed.label, 'New');
      expect(renamed.id, 'n');
      expect(renamed.parentId, 'p');
      expect(renamed.mece, isFalse);
    });

    test('copyWith can set the MECE flag alone', () {
      const node = TreeNode(id: 'n', label: 'Keep');

      final flagged = node.copyWith(mece: true);

      expect(flagged.mece, isTrue);
      expect(flagged.label, 'Keep');
    });

    test('a node list converts to and from records', () {
      final records = nodesToRecords(sampleTree());

      expect(nodesFromRecords(records).map((n) => n.id), [
        'root',
        'a',
        'a1',
        'b',
      ]);
    });
  });

  group('depthOf', () {
    test('puts the root at zero', () {
      final tree = sampleTree();
      expect(depthOf(tree.first, tree), 0);
    });

    test('counts each level', () {
      final tree = sampleTree();
      expect(depthOf(tree[1], tree), 1);
      expect(depthOf(tree[2], tree), 2);
    });

    test('stops when a parent is missing rather than looping', () {
      // An orphan can exist in stored data even though the UI cannot make one.
      const orphan = TreeNode(id: 'x', label: 'X', parentId: 'gone');
      expect(depthOf(orphan, const [orphan]), 0);
    });

    test('terminates on a cycle in stored data', () {
      // Derived from parentId rather than a stored depth, so a corrupt file
      // must not be able to hang the render.
      const a = TreeNode(id: 'a', label: 'A', parentId: 'b');
      const b = TreeNode(id: 'b', label: 'B', parentId: 'a');

      expect(depthOf(a, const [a, b]), lessThanOrEqualTo(3));
    });
  });

  group('childrenOf', () {
    test('finds direct children only', () {
      final tree = sampleTree();
      expect(childrenOf('root', tree).map((n) => n.id), ['a', 'b']);
    });

    test('finds the root by passing null', () {
      final tree = sampleTree();
      expect(childrenOf(null, tree).map((n) => n.id), ['root']);
    });

    test('is empty for a leaf', () {
      final tree = sampleTree();
      expect(childrenOf('a1', tree), isEmpty);
    });
  });

  group('descendantsOf', () {
    test('finds children at every depth', () {
      final tree = sampleTree();
      expect(descendantsOf('root', tree).map((n) => n.id), ['a', 'b', 'a1']);
    });

    test('is empty for a leaf', () {
      expect(descendantsOf('a1', sampleTree()), isEmpty);
    });
  });

  group('addChild', () {
    test('inserts directly after the parent when it has no children', () {
      final tree = sampleTree();

      final grown = addChild(
        'b',
        const TreeNode(id: 'b1', label: 'B1', parentId: 'b'),
        tree,
      );

      expect(grown.map((n) => n.id), ['root', 'a', 'a1', 'b', 'b1']);
    });

    test('inserts after the parent\'s whole existing subtree', () {
      // Keeping siblings adjacent is what lets a flat list render as a tree
      // with no sorting pass.
      final tree = sampleTree();

      final grown = addChild(
        'a',
        const TreeNode(id: 'a2', label: 'A2', parentId: 'a'),
        tree,
      );

      expect(grown.map((n) => n.id), ['root', 'a', 'a1', 'a2', 'b']);
    });

    test('appends under the root without disturbing other branches', () {
      final tree = sampleTree();

      final grown = addChild(
        'root',
        const TreeNode(id: 'c', label: 'C', parentId: 'root'),
        tree,
      );

      expect(grown.map((n) => n.id), ['root', 'a', 'a1', 'b', 'c']);
    });

    test('does nothing when the parent does not exist', () {
      final tree = sampleTree();

      final grown = addChild(
        'nope',
        const TreeNode(id: 'x', label: 'X', parentId: 'nope'),
        tree,
      );

      expect(grown, tree);
    });
  });

  group('removeSubtree', () {
    test('removes the node and everything under it', () {
      // Leaving descendants behind would silently promote a detail to a
      // top-level branch, since a parentless node renders at the root.
      final tree = sampleTree();

      final pruned = removeSubtree('a', tree);

      expect(pruned.map((n) => n.id), ['root', 'b']);
    });

    test('removes a leaf without touching its siblings', () {
      final pruned = removeSubtree('a1', sampleTree());
      expect(pruned.map((n) => n.id), ['root', 'a', 'b']);
    });

    test('removing the root empties the tree', () {
      expect(removeSubtree('root', sampleTree()), isEmpty);
    });

    test('is a no-op for an unknown id', () {
      final tree = sampleTree();
      expect(removeSubtree('nope', tree).length, tree.length);
    });
  });

  group('updateNode', () {
    test('replaces only the matching node', () {
      final tree = sampleTree();

      final updated = updateNode(
        'a',
        (node) => node.copyWith(label: 'Renamed'),
        tree,
      );

      expect(updated[1].label, 'Renamed');
      expect(updated[3].label, 'B');
    });

    test('keeps list order', () {
      final updated = updateNode(
        'a1',
        (node) => node.copyWith(mece: true),
        sampleTree(),
      );

      expect(updated.map((n) => n.id), ['root', 'a', 'a1', 'b']);
    });

    test('is a no-op for an unknown id', () {
      final tree = sampleTree();
      final updated = updateNode('nope', (n) => n.copyWith(label: '!'), tree);

      expect(updated.map((n) => n.label), ['Root', 'A', 'A1', 'B']);
    });
  });
}
