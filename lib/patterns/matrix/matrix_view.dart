/// Pattern B — sorting items into the four cells of a 2x2 grid.
///
/// Items are draggable, but drag is never the *only* way to move one: every
/// card carries a "move to" menu reachable by keyboard. The design system
/// requires pointer-free operability, and a drag has no keyboard analogue, so
/// the menu is built alongside the drag rather than added later.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:uuid/uuid.dart';

/// Renders the four quadrants and the items sorted into them.
class MatrixView extends StatelessWidget {
  /// Creates the matrix view.
  const MatrixView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's axis and quadrant definitions.
  final MatrixConfig config;

  /// Called with the updated session whenever an item moves.
  final ValueChanged<Session> onChanged;

  QuadrantSpec _quadrant(QuadrantCorner corner) =>
      config.quadrants.firstWhere((q) => q.corner == corner);

  void _add(String text, String slotId) {
    if (text.trim().isEmpty) return;
    final items = [
      ...session.records(slotId),
      {'id': const Uuid().v4(), 'label': text.trim()},
    ];
    onChanged(session.withSlot(slotId, items));
  }

  void _move(String itemId, String fromSlot, String toSlot) {
    if (fromSlot == toSlot) return;
    final moving = session
        .records(fromSlot)
        .where((item) => item['id'] == itemId)
        .toList();
    if (moving.isEmpty) return;
    final remaining = [
      for (final item in session.records(fromSlot))
        if (item['id'] != itemId) item,
    ];
    final updated = session.withSlot(fromSlot, remaining).withSlot(toSlot, [
      ...session.records(toSlot),
      ...moving,
    ]);
    onChanged(updated);
  }

  void _remove(String itemId, String slotId) {
    onChanged(
      session.withSlot(slotId, [
        for (final item in session.records(slotId))
          if (item['id'] != itemId) item,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Short landscape screens are a stated target, so the grid scrolls rather
    // than compressing the cells until they clip.
    return ListView(
      children: [
        _AddItemField(
          onSubmit: (text) => _add(text, config.quadrants.first.slotId),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${config.yAxis.label} (vertical) x ${config.xAxis.label} '
          '(horizontal)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final corner in QuadrantCorner.values)
          _QuadrantCard(
            quadrant: _quadrant(corner),
            allQuadrants: config.quadrants,
            items: session.records(_quadrant(corner).slotId),
            onMove: _move,
            onRemove: _remove,
            onAdd: _add,
          ),
      ],
    );
  }
}

class _AddItemField extends StatefulWidget {
  const _AddItemField({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_AddItemField> createState() => _AddItemFieldState();
}

class _AddItemFieldState extends State<_AddItemField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Add an item',
        helperText: 'Enter adds it to the first quadrant; move it from there.',
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add item',
          onPressed: _submit,
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}

class _QuadrantCard extends StatelessWidget {
  const _QuadrantCard({
    required this.quadrant,
    required this.allQuadrants,
    required this.items,
    required this.onMove,
    required this.onRemove,
    required this.onAdd,
  });

  final QuadrantSpec quadrant;
  final List<QuadrantSpec> allQuadrants;
  final List<Map<String, Object?>> items;
  final void Function(String itemId, String fromSlot, String toSlot) onMove;
  final void Function(String itemId, String slotId) onRemove;
  final void Function(String text, String slotId) onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<_MatrixDrag>(
      onAcceptWithDetails: (details) =>
          onMove(details.data.itemId, details.data.fromSlot, quadrant.slotId),
      builder: (context, candidate, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          color: candidate.isEmpty
              ? null
              : theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quadrant.name, style: theme.textTheme.titleMedium),
                Text(
                  quadrant.action,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (items.isEmpty)
                  Text(
                    'Empty',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (final item in items)
                  _ItemTile(
                    itemId: item['id'] as String? ?? '',
                    label: item['label'] as String? ?? '',
                    fromSlot: quadrant.slotId,
                    quadrants: allQuadrants,
                    onMove: onMove,
                    onRemove: onRemove,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatrixDrag {
  const _MatrixDrag(this.itemId, this.fromSlot);

  final String itemId;
  final String fromSlot;
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.itemId,
    required this.label,
    required this.fromSlot,
    required this.quadrants,
    required this.onMove,
    required this.onRemove,
  });

  final String itemId;
  final String label;
  final String fromSlot;
  final List<QuadrantSpec> quadrants;
  final void Function(String itemId, String fromSlot, String toSlot) onMove;
  final void Function(String itemId, String slotId) onRemove;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: true,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The keyboard-reachable equivalent of dragging the card.
          PopupMenuButton<String>(
            icon: const Icon(Icons.drive_file_move_outline),
            tooltip: 'Move to quadrant',
            onSelected: (slot) => onMove(itemId, fromSlot, slot),
            itemBuilder: (context) => [
              for (final quadrant in quadrants)
                if (quadrant.slotId != fromSlot)
                  PopupMenuItem(
                    value: quadrant.slotId,
                    child: Text(quadrant.name),
                  ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove item',
            onPressed: () => onRemove(itemId, fromSlot),
          ),
        ],
      ),
    );
    return Draggable<_MatrixDrag>(
      data: _MatrixDrag(itemId, fromSlot),
      feedback: Material(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(label),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }
}
