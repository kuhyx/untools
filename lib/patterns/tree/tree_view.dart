/// Pattern C — a tool worked through as a tree of nested nodes.
///
/// Rendered as an indented list rather than a drawn diagram: the operation
/// that matters is "break this into parts", which reads perfectly well as
/// indentation and stays usable on a phone, where a node-and-edge canvas does
/// not. The logic lives in `tree_model.dart` as plain Dart; this file only
/// renders and collects edits.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/tree/tree_model.dart';
import 'package:uuid/uuid.dart';

/// Slot holding the flat, ordered node list.
const String kTreeNodesSlot = 'nodes';

/// Slot holding the selected [TreeMode.id].
const String kTreeModeSlot = 'tree-mode';

/// Indentation per level. One spacing step reads as hierarchy without
/// pushing deep nodes off a narrow screen.
const double kTreeIndent = AppSpacing.lg;

/// Renders the tree and its add/remove/rename controls.
class TreeView extends StatelessWidget {
  /// Creates the tree view.
  const TreeView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's tree definition.
  final TreeConfig config;

  /// Called with the updated session whenever the tree changes.
  final ValueChanged<Session> onChanged;

  TreeMode get _mode {
    final stored = session.text(kTreeModeSlot);
    for (final mode in config.modes) {
      if (mode.id == stored) return mode;
    }
    return config.modes.first;
  }

  List<TreeNode> get _nodes {
    final stored = nodesFromRecords(session.records(kTreeNodesSlot));
    if (stored.isNotEmpty) return stored;
    // Materialised on first read so the config stays the only description of
    // what a fresh tree looks like.
    return const [TreeNode(id: 'root', label: '')];
  }

  void _write(List<TreeNode> nodes) =>
      onChanged(session.withSlot(kTreeNodesSlot, nodesToRecords(nodes)));

  void _add(String parentId) => _write(
    addChild(
      parentId,
      TreeNode(
        id: const Uuid().v4(),
        label: '',
        parentId: parentId,
      ),
      _nodes,
    ),
  );

  void _rename(String id, String label) =>
      _write(updateNode(id, (node) => node.copyWith(label: label), _nodes));

  void _toggleMece(String id) => _write(
    updateNode(id, (node) => node.copyWith(mece: !node.mece), _nodes),
  );

  void _remove(String id) => _write(removeSubtree(id, _nodes));

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes;
    final mode = _mode;
    return ListView(
      children: [
        if (config.modes.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SegmentedButton<String>(
              segments: [
                for (final option in config.modes)
                  ButtonSegment(value: option.id, label: Text(option.label)),
              ],
              selected: {mode.id},
              onSelectionChanged: (selection) => onChanged(
                session.withSlot(kTreeModeSlot, selection.first),
              ),
            ),
          ),
        for (final node in nodes)
          _NodeRow(
            key: ValueKey(node.id),
            node: node,
            depth: depthOf(node, nodes),
            isRoot: node.parentId == null,
            rootPrompt: config.rootPrompt,
            childPrompt: mode.childPrompt,
            meceCheck:
                config.meceCheck && childrenOf(node.id, nodes).isNotEmpty,
            onRename: (value) => _rename(node.id, value),
            onAddChild: () => _add(node.id),
            onToggleMece: () => _toggleMece(node.id),
            onRemove: node.parentId == null ? null : () => _remove(node.id),
          ),
      ],
    );
  }
}

class _NodeRow extends StatefulWidget {
  const _NodeRow({
    required this.node,
    required this.depth,
    required this.isRoot,
    required this.rootPrompt,
    required this.childPrompt,
    required this.meceCheck,
    required this.onRename,
    required this.onAddChild,
    required this.onToggleMece,
    super.key,
    this.onRemove,
  });

  final TreeNode node;
  final int depth;
  final bool isRoot;
  final String rootPrompt;
  final String childPrompt;
  final bool meceCheck;
  final ValueChanged<String> onRename;
  final VoidCallback onAddChild;
  final VoidCallback onToggleMece;
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: widget.depth * kTreeIndent,
        bottom: AppSpacing.sm,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isRoot)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  widget.rootPrompt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.isRoot ? null : widget.childPrompt,
              ),
              onChanged: widget.onRename,
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: widget.onAddChild,
                  icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                  label: Text(widget.childPrompt),
                ),
                if (widget.meceCheck)
                  // Offered only where it means something — on a node that
                  // actually has children to be exhaustive about.
                  IconButton(
                    tooltip: widget.node.mece
                        ? 'Marked as covering every case, without overlap'
                        : 'Mark as covering every case, without overlap',
                    icon: Icon(
                      widget.node.mece
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: widget.node.mece
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    onPressed: widget.onToggleMece,
                  ),
                if (widget.onRemove case final remove?)
                  IconButton(
                    tooltip: 'Remove this branch',
                    icon: const Icon(Icons.close),
                    onPressed: remove,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
