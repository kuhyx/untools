/// The tree pattern's data operations, as plain Dart.
///
/// No Flutter import on purpose: this is where the actual logic of the pattern
/// lives (what a subtree is, what removing a node means, how depth is
/// derived), so keeping it free of widgets makes it exhaustively unit-testable
/// and keeps the widget a thin renderer.
///
/// Stored as a **flat, ordered list** rather than nested records. A node's
/// place in the hierarchy comes from its `parentId`, and the list order is the
/// display order. Flat storage means a session slot is a simple JSON array
/// that no recursive codec has to walk, and it makes "insert this child
/// directly after its parent's existing subtree" — the operation the UI
/// actually needs — a single index calculation rather than a tree rewrite.
library;

/// One node of a tree.
class TreeNode {
  /// Creates a node.
  const TreeNode({
    required this.id,
    required this.label,
    this.parentId,
    this.mece = false,
  });

  /// Reads a node from its stored form, tolerating missing fields.
  factory TreeNode.fromRecord(Map<String, Object?> record) {
    return TreeNode(
      id: record['id'] as String? ?? '',
      label: record['label'] as String? ?? '',
      parentId: record['parentId'] as String?,
      mece: record['mece'] as bool? ?? false,
    );
  }

  /// Stable id.
  final String id;

  /// What the user typed.
  final String label;

  /// Parent's id, or null for the root.
  final String? parentId;

  /// Whether this node's children have been marked mutually exclusive and
  /// collectively exhaustive — the check that stops a decomposition from
  /// quietly overlapping or leaving a branch out.
  final bool mece;

  /// This node in its stored form.
  Map<String, Object?> toRecord() => {
    'id': id,
    'label': label,
    'parentId': parentId,
    'mece': mece,
  };

  /// A copy with the given fields replaced.
  TreeNode copyWith({String? label, bool? mece}) => TreeNode(
    id: id,
    label: label ?? this.label,
    parentId: parentId,
    mece: mece ?? this.mece,
  );
}

/// Reads a stored node list.
List<TreeNode> nodesFromRecords(List<Map<String, Object?>> records) => [
  for (final record in records) TreeNode.fromRecord(record),
];

/// Writes a node list back to storage.
List<Map<String, Object?>> nodesToRecords(List<TreeNode> nodes) => [
  for (final node in nodes) node.toRecord(),
];

/// How deep [node] sits, with the root at zero.
///
/// Walks up by `parentId` rather than trusting a stored depth, so a depth can
/// never disagree with the structure. Guards against a cycle — which stored
/// data could contain even though the UI cannot create one — by bounding the
/// walk at the node count instead of looping forever.
int depthOf(TreeNode node, List<TreeNode> all) {
  final byId = {for (final n in all) n.id: n};
  var depth = 0;
  var current = node;
  while (current.parentId != null && depth <= all.length) {
    final parent = byId[current.parentId];
    if (parent == null) break;
    current = parent;
    depth++;
  }
  return depth;
}

/// The direct children of [parentId], in list order.
List<TreeNode> childrenOf(String? parentId, List<TreeNode> all) => [
  for (final node in all)
    if (node.parentId == parentId) node,
];

/// Every descendant of [id], at any depth.
List<TreeNode> descendantsOf(String id, List<TreeNode> all) {
  final found = <TreeNode>[];
  final queue = <String>[id];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    for (final child in childrenOf(current, all)) {
      found.add(child);
      queue.add(child.id);
    }
  }
  return found;
}

/// Inserts [child] directly after [parentId]'s existing subtree.
///
/// Placing it at the end of the subtree rather than the end of the list is
/// what keeps a flat list rendering as a tree: every node stays adjacent to
/// its siblings, so the display order needs no sorting pass.
List<TreeNode> addChild(String parentId, TreeNode child, List<TreeNode> all) {
  final parentIndex = all.indexWhere((node) => node.id == parentId);
  if (parentIndex < 0) return all;
  final subtree = descendantsOf(parentId, all).length;
  final insertAt = parentIndex + subtree + 1;
  return [...all.sublist(0, insertAt), child, ...all.sublist(insertAt)];
}

/// Removes [id] and everything under it.
///
/// Descendants go too: a node whose parent is gone would render at the root,
/// silently promoting a detail to a top-level branch.
List<TreeNode> removeSubtree(String id, List<TreeNode> all) {
  final doomed = {id, for (final node in descendantsOf(id, all)) node.id};
  return [
    for (final node in all)
      if (!doomed.contains(node.id)) node,
  ];
}

/// Replaces the node with [id] using [update].
List<TreeNode> updateNode(
  String id,
  TreeNode Function(TreeNode) update,
  List<TreeNode> all,
) => [
  for (final node in all)
    if (node.id == id) update(node) else node,
];
