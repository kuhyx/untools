/// Pattern D — a tool worked through as nodes joined by links.
///
/// The diagram is a `Stack`: a `CustomPainter` draws the *edges* underneath,
/// and every node is a real focusable widget positioned on top. That split is
/// deliberate and load-bearing.
///
/// Painting nodes into the canvas would have meant hit-testing taps against
/// drawn discs, and a painted disc cannot be tabbed to, read by a screen
/// reader, or reached without a pointer — the design system's pointer-free
/// rule forbids it. Real widgets get focus traversal, semantics and text
/// editing for free, so the keyboard path is not a parallel implementation
/// that can drift; it is the only implementation.
///
/// Positions come from `layout.dart` and are never stored. Links are created
/// through a form rather than by dragging between nodes, for the same reason.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/graph/cycles.dart';
import 'package:untools/patterns/graph/graph_model.dart';
import 'package:untools/patterns/graph/layout.dart';
import 'package:uuid/uuid.dart';

/// Height reserved for the diagram before the editing list.
const double kCanvasHeight = 320;

/// Width a node's label may occupy, wider than the disc it labels.
const double kNodeLabelWidth = 132;

/// Renders the graph and the controls that edit it.
class GraphView extends StatelessWidget {
  /// Creates the graph view.
  const GraphView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's graph definition.
  final GraphConfig config;

  /// Called with the updated session whenever the graph changes.
  final ValueChanged<Session> onChanged;

  /// The stored nodes, or the tool's seeds the first time it is opened.
  ///
  /// Materialised on read so the config stays the only description of what a
  /// fresh diagram looks like.
  List<GraphNode> get _nodes {
    final stored = nodesFromRecords(session.records(kGraphNodesSlot));
    if (stored.isNotEmpty) return stored;
    return [
      for (final seed in config.seeds)
        GraphNode(
          id: seed.slotId,
          label: seed.label,
          slotId: seed.slotId,
          fixed: seed.fixed,
        ),
    ];
  }

  List<GraphEdge> get _edges =>
      edgesFromRecords(session.records(kGraphEdgesSlot));

  /// Whether this variant lets the user add and remove nodes.
  ///
  /// The conflict cloud's five slots are the method — an extra box would make
  /// the diagram mean something else — and the fishbone's ribs are fixed by
  /// its config, so both are template-only.
  bool get _canEditNodes =>
      config.variant != GraphVariant.cloud &&
      config.variant != GraphVariant.fishbone;

  /// Whether links carry a `+`/`-` polarity.
  bool get _signed => config.variant == GraphVariant.circle;

  void _writeNodes(List<GraphNode> nodes) =>
      onChanged(session.withSlot(kGraphNodesSlot, nodesToRecords(nodes)));

  void _writeEdges(List<GraphEdge> edges) =>
      onChanged(session.withSlot(kGraphEdgesSlot, edgesToRecords(edges)));

  void _addNode() => _writeNodes([
    ..._nodes,
    GraphNode(id: const Uuid().v4(), label: ''),
  ]);

  void _rename(String id, String label) => _writeNodes([
    for (final node in _nodes)
      if (node.id == id) node.copyWith(label: label) else node,
  ]);

  void _removeNode(String id) {
    _writeNodes([
      for (final node in _nodes)
        if (node.id != id) node,
    ]);
  }

  void _addEdge(GraphEdge edge) => _writeEdges([..._edges, edge]);

  void _removeEdge(int index) => _writeEdges([
    for (final (i, edge) in _edges.indexed)
      if (i != index) edge,
  ]);

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes;
    final edges = _edges;
    final loops = _signed ? findLoops(nodes, edges) : const <FeedbackLoop>[];

    return ListView(
      children: [
        // Hidden until there is something to draw. On a phone the canvas is a
        // third of the screen, and reserving it for an empty diagram pushes
        // the controls you need first — "Add element" — below the fold.
        if (nodes.isNotEmpty) ...[
          SizedBox(
            height: kCanvasHeight,
            child: _Diagram(
              variant: config.variant,
              nodes: nodes,
              edges: edges,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _SectionHeading(
          title: 'Elements',
          action: _canEditNodes
              ? TextButton.icon(
                  onPressed: _addNode,
                  icon: const Icon(Icons.add),
                  label: const Text('Add element'),
                )
              : null,
        ),
        for (final node in nodes)
          _NodeRow(
            key: ValueKey(node.id),
            node: node,
            prompt: _promptFor(node),
            onRename: (value) => _rename(node.id, value),
            onRemove: _canEditNodes && !node.fixed
                ? () => _removeNode(node.id)
                : null,
          ),
        const SizedBox(height: AppSpacing.md),
        const _SectionHeading(title: 'Links'),
        if (edges.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('No links yet.'),
          ),
        for (final (index, edge) in edges.indexed)
          _EdgeRow(
            key: ValueKey('$index-${edge.from}-${edge.to}'),
            edge: edge,
            nodes: nodes,
            onRemove: () => _removeEdge(index),
          ),
        _EdgeComposer(nodes: nodes, signed: _signed, onAdd: _addEdge),
        if (_signed) ...[
          const SizedBox(height: AppSpacing.md),
          _LoopSummary(loops: loops, nodes: nodes),
        ],
      ],
    );
  }

  /// The seed's prompt, when this node came from the template.
  String? _promptFor(GraphNode node) {
    for (final seed in config.seeds) {
      if (seed.slotId == node.slotId) return seed.prompt;
    }
    return null;
  }
}

/// The drawn diagram: painted edges, real widgets for nodes.
class _Diagram extends StatelessWidget {
  const _Diagram({
    required this.variant,
    required this.nodes,
    required this.edges,
  });

  final GraphVariant variant;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final placements = layoutGraph(
          variant: variant,
          nodes: nodes,
          size: size,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EdgePainter(
                  placements: placements,
                  edges: connectedEdges(nodes, edges),
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            // Laid out wider than the disc it is centred on: a 68px circle
            // cannot hold even a short word, and clipping the label inside it
            // turned "Rework" into "Rewor" on a phone. The text sits over the
            // gap between nodes instead, which the layout keeps clear.
            for (final placed in placements)
              Positioned(
                left: placed.center.dx - kNodeLabelWidth / 2,
                top: placed.center.dy - kNodeRadius,
                width: kNodeLabelWidth,
                height: kNodeRadius * 2,
                child: _NodeChip(node: placed.node),
              ),
          ],
        );
      },
    );
  }
}

/// A node as drawn on the canvas.
///
/// Read-only and excluded from focus traversal: it mirrors the editable row
/// below rather than duplicating it, so tabbing does not stop twice on the
/// same node. Its label is exposed to semantics so the diagram is not silent
/// to a screen reader.
class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.node});

  final GraphNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: node.label.isEmpty ? 'Unnamed element' : node.label,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: kNodeRadius * 2,
            height: kNodeRadius * 2,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
          Text(
            node.label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Draws the links between placed nodes.
class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.placements,
    required this.edges,
    required this.color,
  });

  final List<PlacedNode> placements;
  final List<GraphEdge> edges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = {
      for (final placed in placements) placed.node.id: placed.center,
    };
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = centers[edge.from];
      final to = centers[edge.to];
      if (from == null || to == null) continue;

      if (edge.from == edge.to) {
        // A self-loop has no direction to draw along, so it becomes a small
        // ring above the node rather than a zero-length line.
        canvas.drawCircle(
          from.translate(0, -kNodeRadius),
          kNodeRadius * 0.6,
          paint,
        );
        continue;
      }
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.placements.length != placements.length ||
      oldDelegate.edges.length != edges.length ||
      oldDelegate.color != color ||
      // Labels move the nodes' text but not their count, so compare the
      // geometry itself: renaming or relinking must redraw.
      !_sameGeometry(oldDelegate);

  bool _sameGeometry(_EdgePainter other) {
    for (final (index, placed) in placements.indexed) {
      if (other.placements[index].center != placed.center) return false;
      if (other.placements[index].node.id != placed.node.id) return false;
    }
    for (final (index, edge) in edges.indexed) {
      if (other.edges[index].from != edge.from) return false;
      if (other.edges[index].to != edge.to) return false;
    }
    return true;
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    );
  }
}

/// One editable element.
class _NodeRow extends StatefulWidget {
  const _NodeRow({
    required this.node,
    required this.onRename,
    super.key,
    this.prompt,
    this.onRemove,
  });

  final GraphNode node;
  final String? prompt;
  final ValueChanged<String> onRename;
  final VoidCallback? onRemove;

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.node.label,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.node.label.isEmpty ? 'Element' : null,
                helperText: widget.prompt,
                helperMaxLines: 2,
              ),
              onChanged: widget.onRename,
            ),
          ),
          if (widget.onRemove != null)
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'Remove element',
            ),
        ],
      ),
    );
  }
}

/// One existing link, with the plain-language reading of it.
class _EdgeRow extends StatelessWidget {
  const _EdgeRow({
    required this.edge,
    required this.nodes,
    required this.onRemove,
    super.key,
  });

  final GraphEdge edge;
  final List<GraphNode> nodes;
  final VoidCallback onRemove;

  String _labelFor(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node.label.isEmpty ? 'Unnamed element' : node.label;
      }
    }
    // Kept rather than hidden: the node may come back, and silently dropping
    // the row would look like the link was lost.
    return 'a deleted element';
  }

  @override
  Widget build(BuildContext context) {
    final relationship = edge.label.isNotEmpty
        ? edge.label
        : switch (edge.sign) {
            EdgeSign.positive => 'increases',
            EdgeSign.negative => 'decreases',
            EdgeSign.none => 'affects',
          };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${_labelFor(edge.from)} $relationship ${_labelFor(edge.to)}',
      ),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close),
        tooltip: 'Remove link',
      ),
    );
  }
}

/// The form that creates a link.
///
/// A form rather than dragging between nodes: two dropdowns and a button are
/// operable from the keyboard, and a drag is not.
class _EdgeComposer extends StatefulWidget {
  const _EdgeComposer({
    required this.nodes,
    required this.signed,
    required this.onAdd,
  });

  final List<GraphNode> nodes;
  final bool signed;
  final ValueChanged<GraphEdge> onAdd;

  @override
  State<_EdgeComposer> createState() => _EdgeComposerState();
}

class _EdgeComposerState extends State<_EdgeComposer> {
  String? _from;
  String? _to;
  EdgeSign _sign = EdgeSign.positive;
  final TextEditingController _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  bool get _ready => _from != null && _to != null;

  void _submit() {
    widget.onAdd(
      GraphEdge(
        from: _from!,
        to: _to!,
        label: widget.signed ? '' : _label.text,
        sign: widget.signed ? _sign : EdgeSign.none,
      ),
    );
    setState(() {
      _from = null;
      _to = null;
      _label.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text('Add two elements to start linking them.'),
      );
    }

    final labels = [
      for (final node in widget.nodes)
        node.label.isEmpty ? 'Unnamed element' : node.label,
    ];
    final items = [
      for (final (index, node) in widget.nodes.indexed)
        DropdownMenuItem(
          value: node.id,
          child: Text(labels[index], overflow: TextOverflow.ellipsis),
        ),
    ];
    // `isExpanded` is what stops a long element name overflowing the field:
    // without it the dropdown lays its row out at intrinsic width and pushes
    // straight past the fixed-width box it sits in.
    List<Widget> selected(BuildContext context) => [
      for (final label in labels)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _from,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'From'),
              items: items,
              selectedItemBuilder: selected,
              onChanged: (value) => setState(() => _from = value),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _to,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'To'),
              items: items,
              selectedItemBuilder: selected,
              onChanged: (value) => setState(() => _to = value),
            ),
          ),
          if (widget.signed)
            SegmentedButton<EdgeSign>(
              segments: const [
                ButtonSegment(
                  value: EdgeSign.positive,
                  label: Text('Increases'),
                ),
                ButtonSegment(
                  value: EdgeSign.negative,
                  label: Text('Decreases'),
                ),
              ],
              selected: {_sign},
              onSelectionChanged: (selection) =>
                  setState(() => _sign = selection.first),
            )
          else
            SizedBox(
              width: 180,
              child: TextField(
                controller: _label,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
            ),
          FilledButton(
            onPressed: _ready ? _submit : null,
            child: const Text('Add link'),
          ),
        ],
      ),
    );
  }
}

/// What the computed feedback loops say about the system.
class _LoopSummary extends StatelessWidget {
  const _LoopSummary({required this.loops, required this.nodes});

  final List<FeedbackLoop> loops;
  final List<GraphNode> nodes;

  String _labelFor(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node.label.isEmpty ? 'Unnamed element' : node.label;
      }
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feedback loops', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (loops.isEmpty)
          const Text(
            'No closed loops yet. A loop needs links that lead back to '
            'where they started.',
          )
        else
          for (final loop in loops)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '${loop.label}: '
                '${loop.nodeIds.map(_labelFor).join(' → ')} → '
                '${_labelFor(loop.nodeIds.first)}',
              ),
            ),
      ],
    );
  }
}
