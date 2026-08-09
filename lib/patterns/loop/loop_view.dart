/// Pattern E — a tool worked through as a repeating cycle of phases.
///
/// Rendered as a numbered list that closes with "…and back to the first
/// stage", not as a drawn ring. The list is what the method actually asks of
/// you — answer each phase in order, then go round again — and it stays
/// keyboard-operable and readable on a phone, where a circular canvas does
/// not. It also matches the Markdown export line for line.
///
/// A growable loop adds and removes its own phases through buttons. There is
/// no drag-to-reorder: a drag has no keyboard analogue.
library;

import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/loop/loop_model.dart';
import 'package:untools/ui/theme.dart';

/// Renders the cycle and collects an answer per phase.
class LoopView extends StatelessWidget {
  /// Creates the loop view.
  const LoopView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's cycle definition.
  final LoopConfig config;

  /// Called with the updated session whenever anything changes.
  final ValueChanged<Session> onChanged;

  /// The phases to show: the config's own, plus any the user added.
  List<LoopPhase> get _phases => phasesFor(config, session);

  /// Which pass round the cycle the user is on, counting from 1.
  int get _iteration => iterationOf(session);

  void _write(List<LoopPhase> phases) =>
      onChanged(session.withSlot(kLoopPhasesSlot, phasesToRecords(phases)));

  void _addPhase() => _write([
    ..._phases,
    LoopPhase(
      slotId: nextPhaseSlotId(_phases),
      name: '',
      prompt: 'What happens at this stage?',
    ),
  ]);

  void _removePhase(String slotId) => _write([
    for (final phase in _phases)
      if (phase.slotId != slotId) phase,
  ]);

  void _renamePhase(String slotId, String name) => _write([
    for (final phase in _phases)
      if (phase.slotId == slotId)
        LoopPhase(slotId: phase.slotId, name: name, prompt: phase.prompt)
      else
        phase,
  ]);

  static String _firstStageName(List<LoopPhase> phases) =>
      phases.first.name.isEmpty ? 'the first stage' : phases.first.name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phases = _phases;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pass $_iteration',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => onChanged(
                session.withSlot(kLoopIterationSlot, _iteration + 1),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Go round again'),
            ),
          ],
        ),
        Text(
          'The cycle is the point: each pass starts from what the last one '
          'told you.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (index, phase) in phases.indexed)
          _PhaseCard(
            key: ValueKey(phase.slotId),
            number: index + 1,
            phase: phase,
            answer: session.text(phase.slotId),
            editableName: config.growable,
            onAnswer: (value) =>
                onChanged(session.withSlot(phase.slotId, value)),
            onRename: config.growable
                ? (value) => _renamePhase(phase.slotId, value)
                : null,
            // The method's own phases stay; only user-added ones can go, and
            // never the last two — a one-phase "cycle" is not a cycle.
            onRemove: config.growable && phases.length > 2
                ? () => _removePhase(phase.slotId)
                : null,
          ),
        if (config.growable)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _addPhase,
              icon: const Icon(Icons.add),
              label: const Text('Add a stage'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (phases.isNotEmpty)
          Text(
            '…and back to ${_firstStageName(phases)}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

/// One phase of the cycle.
class _PhaseCard extends StatefulWidget {
  const _PhaseCard({
    required this.number,
    required this.phase,
    required this.answer,
    required this.editableName,
    required this.onAnswer,
    super.key,
    this.onRename,
    this.onRemove,
  });

  final int number;
  final LoopPhase phase;
  final String answer;
  final bool editableName;
  final ValueChanged<String> onAnswer;
  final ValueChanged<String>? onRename;
  final VoidCallback? onRemove;

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  late final TextEditingController _answer = TextEditingController(
    text: widget.answer,
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.phase.name,
  );

  @override
  void dispose() {
    _answer.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              '${widget.number}.',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.editableName)
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Stage'),
                    onChanged: widget.onRename,
                  )
                else
                  Text(widget.phase.name, style: theme.textTheme.titleMedium),
                TextField(
                  controller: _answer,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    helperText: widget.phase.prompt,
                    helperMaxLines: 2,
                  ),
                  onChanged: widget.onAnswer,
                ),
              ],
            ),
          ),
          if (widget.onRemove != null)
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'Remove stage',
            ),
        ],
      ),
    );
  }
}
