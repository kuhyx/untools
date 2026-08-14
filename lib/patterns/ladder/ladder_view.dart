/// Pattern F — a tool worked through as an ordered stack of levels.
///
/// Two shapes share this widget. A **fixed** ladder has levels the method
/// names and the user cannot add to (the Iceberg's four, the Ladder of
/// inference's seven) — the constraint is the point, since the value comes
/// from being made to answer the level you would have skipped. A **growable**
/// ladder starts from a seed the user extends upward or downward.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:uuid/uuid.dart';

/// Slot holding a growable ladder's rungs, ordered top to bottom.
const String kLadderRungsSlot = 'rungs';

/// Renders a ladder, fixed or growable.
class LadderView extends StatelessWidget {
  /// Creates the ladder view.
  const LadderView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's ladder definition.
  final LadderConfig config;

  /// Called with the updated session whenever a level changes.
  final ValueChanged<Session> onChanged;

  @override
  Widget build(BuildContext context) {
    final rungs = config.fixedRungs;
    if (rungs != null) {
      return _FixedLadder(
        session: session,
        rungs: rungs,
        waterlineAfter: config.waterlineAfter,
        onChanged: onChanged,
      );
    }
    return _GrowableLadder(
      session: session,
      spec: config.grow!,
      onChanged: onChanged,
    );
  }
}

class _FixedLadder extends StatelessWidget {
  const _FixedLadder({
    required this.session,
    required this.rungs,
    required this.waterlineAfter,
    required this.onChanged,
  });

  final Session session;
  final List<RungSpec> rungs;
  final int? waterlineAfter;
  final ValueChanged<Session> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (var index = 0; index < rungs.length; index++) ...[
          _RungField(
            key: ValueKey(rungs[index].slotId),
            title: rungs[index].name,
            prompt: rungs[index].prompt,
            initial: session.text(rungs[index].slotId),
            onChanged: (value) =>
                onChanged(session.withSlot(rungs[index].slotId, value)),
          ),
          if (index == waterlineAfter) const _Waterline(),
        ],
      ],
    );
  }
}

/// The line between what is observable and what explains it.
///
/// Drawn rather than described because the whole point of the Iceberg is that
/// the levels below are the ones nobody looks at; a heading alone does not
/// carry that.
class _Waterline extends StatelessWidget {
  const _Waterline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.primary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'below the surface',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _GrowableLadder extends StatelessWidget {
  const _GrowableLadder({
    required this.session,
    required this.spec,
    required this.onChanged,
  });

  final Session session;
  final GrowSpec spec;
  final ValueChanged<Session> onChanged;

  List<Map<String, Object?>> get _rungs {
    final stored = session.records(kLadderRungsSlot);
    if (stored.isNotEmpty) return stored;
    // The seed rung is materialised on first read rather than written at
    // session creation, so the tool config stays the only source of truth for
    // what a fresh ladder looks like.
    return [
      {'id': 'seed', 'label': '', 'seed': true},
    ];
  }

  void _add({required bool above}) {
    final rungs = [..._rungs];
    final entry = {'id': const Uuid().v4(), 'label': '', 'seed': false};
    if (above) {
      rungs.insert(0, entry);
    } else {
      rungs.add(entry);
    }
    onChanged(session.withSlot(kLadderRungsSlot, rungs));
  }

  void _edit(String id, String value) {
    onChanged(
      session.withSlot(kLadderRungsSlot, [
        for (final rung in _rungs)
          if (rung['id'] == id) {...rung, 'label': value} else rung,
      ]),
    );
  }

  void _remove(String id) {
    onChanged(
      session.withSlot(kLadderRungsSlot, [
        for (final rung in _rungs)
          if (rung['id'] != id) rung,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rungs = _rungs;
    return ListView(
      children: [
        OutlinedButton.icon(
          onPressed: () => _add(above: true),
          icon: const Icon(Icons.arrow_upward),
          label: Text('${spec.upLabel}  (broader)'),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final rung in rungs)
          _RungField(
            key: ValueKey(rung['id']),
            title: (rung['seed'] as bool? ?? false)
                ? 'Your starting point'
                : 'Rung',
            prompt: (rung['seed'] as bool? ?? false)
                ? spec.seedPrompt
                : _promptFor(rungs, rung),
            initial: rung['label'] as String? ?? '',
            onChanged: (value) => _edit(rung['id']! as String, value),
            onRemove: (rung['seed'] as bool? ?? false)
                ? null
                : () => _remove(rung['id']! as String),
          ),
        OutlinedButton.icon(
          onPressed: () => _add(above: false),
          icon: const Icon(Icons.arrow_downward),
          label: Text('${spec.downLabel}  (more concrete)'),
        ),
      ],
    );
  }

  String _promptFor(List<Map<String, Object?>> rungs, Map<String, Object?> r) {
    final seedIndex = rungs.indexWhere((e) => e['seed'] as bool? ?? false);
    final index = rungs.indexOf(r);
    return index < seedIndex ? spec.upPrompt : spec.downPrompt;
  }
}

class _RungField extends StatefulWidget {
  const _RungField({
    required this.title,
    required this.prompt,
    required this.initial,
    required this.onChanged,
    super.key,
    this.onRemove,
  });

  final String title;
  final String prompt;
  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_RungField> createState() => _RungFieldState();
}

class _RungFieldState extends State<_RungField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                if (widget.onRemove case final remove?)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove rung',
                    onPressed: remove,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.prompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: null,
              onChanged: widget.onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
