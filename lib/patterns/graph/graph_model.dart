/// The graph pattern's data: nodes, signed edges, and their record codec.
///
/// Flutter-free on purpose. The geometry lives in `layout.dart` and the cycle
/// analysis in `cycles.dart`; keeping all three free of widget imports is what
/// makes the 100% coverage gate reachable on a canvas-heavy pattern.
///
/// Both slots are flat lists of records, matching the tree: a session slot
/// stays a plain JSON array that no recursive codec has to walk.
library;

/// Stable key the node list is stored under.
const String kGraphNodesSlot = 'nodes';

/// Stable key the edge list is stored under.
const String kGraphEdgesSlot = 'edges';

/// Reads a stored value as text, treating a wrong-typed value as absent.
String _string(Object? value) => value is String ? value : '';

/// A single element in a graph.
class GraphNode {
  /// Creates a node.
  const GraphNode({
    required this.id,
    required this.label,
    this.slotId,
    this.fixed = false,
  });

  /// Rebuilds a node from its stored record, tolerating missing keys.
  ///
  /// A record written by a newer build can carry keys this one does not know,
  /// or the same key holding a different type. Both are read defensively — a
  /// hand-edited or future-shaped session renders as best it can instead of
  /// throwing on load and taking the whole screen with it.
  factory GraphNode.fromRecord(Map<String, Object?> record) => GraphNode(
    id: _string(record['id']),
    label: _string(record['label']),
    slotId: record['slotId'] is String ? record['slotId']! as String : null,
    fixed: record['fixed'] is bool && record['fixed']! as bool,
  );

  /// Identity used by edges. Never an index — reordering must not relink.
  final String id;

  /// What the user typed.
  final String label;

  /// Set when this node came from a [SeedNode], so a template node keeps its
  /// identity across a reload even if its label was edited.
  final String? slotId;

  /// Whether the node is part of the tool's template and cannot be deleted.
  final bool fixed;

  /// Serialises to a record.
  Map<String, Object?> toRecord() => {
    'id': id,
    'label': label,
    'slotId': slotId,
    'fixed': fixed,
  };

  /// Returns a copy with the given fields replaced.
  GraphNode copyWith({String? label}) => GraphNode(
    id: id,
    label: label ?? this.label,
    slotId: slotId,
    fixed: fixed,
  );
}

/// A directed link between two nodes.
class GraphEdge {
  /// Creates an edge.
  const GraphEdge({
    required this.from,
    required this.to,
    this.label = '',
    this.sign = EdgeSign.none,
  });

  /// Rebuilds an edge from its stored record.
  ///
  /// The sign is stored as the `+`/`-` glyph the exporter already writes,
  /// rather than an enum name, so the Markdown and the store agree.
  factory GraphEdge.fromRecord(Map<String, Object?> record) => GraphEdge(
    from: _string(record['from']),
    to: _string(record['to']),
    label: _string(record['label']),
    sign: EdgeSign.fromGlyph(
      record['sign'] is String ? record['sign']! as String : null,
    ),
  );

  /// Source node id.
  final String from;

  /// Target node id.
  final String to;

  /// Free-text relationship, used by the concept map and the conflict cloud.
  final String label;

  /// Causal polarity, used by connection circles.
  final EdgeSign sign;

  /// Serialises to a record.
  ///
  /// Writes `sign` only when set, so a concept map's edges stay free of a
  /// polarity that means nothing in that variant.
  Map<String, Object?> toRecord() => {
    'from': from,
    'to': to,
    'label': label,
    if (sign != EdgeSign.none) 'sign': sign.glyph,
  };
}

/// Whether a link amplifies or dampens what it points at.
enum EdgeSign {
  /// More of the source means more of the target.
  positive('+'),

  /// More of the source means less of the target.
  negative('-'),

  /// Polarity does not apply to this variant.
  none('');

  const EdgeSign(this.glyph);

  /// Parses the stored glyph, defaulting to [none] for anything unrecognised.
  factory EdgeSign.fromGlyph(String? glyph) => switch (glyph) {
    '+' => positive,
    '-' => negative,
    _ => none,
  };

  /// The character written to the store and the Markdown export.
  final String glyph;
}

/// Rebuilds the node list from stored records.
List<GraphNode> nodesFromRecords(List<Map<String, Object?>> records) => [
  for (final record in records) GraphNode.fromRecord(record),
];

/// Serialises the node list.
List<Map<String, Object?>> nodesToRecords(List<GraphNode> nodes) => [
  for (final node in nodes) node.toRecord(),
];

/// Rebuilds the edge list from stored records.
List<GraphEdge> edgesFromRecords(List<Map<String, Object?>> records) => [
  for (final record in records) GraphEdge.fromRecord(record),
];

/// Serialises the edge list.
List<Map<String, Object?>> edgesToRecords(List<GraphEdge> edges) => [
  for (final edge in edges) edge.toRecord(),
];

/// Drops every edge whose endpoints are not both present in [nodes].
///
/// Deleting a node leaves its edges dangling. Rather than cascade-deleting at
/// the point of removal — which loses the link if the deletion is undone — the
/// reader filters, so a dangling edge is inert but recoverable. The exporter
/// makes the same allowance, printing `?` for the missing end.
List<GraphEdge> connectedEdges(List<GraphNode> nodes, List<GraphEdge> edges) {
  final ids = {for (final node in nodes) node.id};
  return [
    for (final edge in edges)
      if (ids.contains(edge.from) && ids.contains(edge.to)) edge,
  ];
}
