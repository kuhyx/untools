/// Pattern G — a tool worked through as a set of named perspectives.
///
/// Two shapes again. Most lens tools want you to visit *every* perspective in
/// turn, one at a time, which is the whole trick: thinking about benefits and
/// risks separately produces more of each than trying to weigh them at once.
/// Others exist to land you on exactly *one* perspective, reached through a
/// short classifier — there the answer is which lens applies, not what you
/// wrote under each.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';

/// Slot recording which lens a classifier selected.
const String kSelectedLensSlot = 'selected-lens';

/// Renders the lens cards, optionally behind a classifier.
class LensView extends StatelessWidget {
  /// Creates the lens view.
  const LensView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's lens definitions.
  final LensConfig config;

  /// Called with the updated session whenever a note or selection changes.
  final ValueChanged<Session> onChanged;

  @override
  Widget build(BuildContext context) {
    final classifier = config.classifier;
    if (classifier != null && session.text(kSelectedLensSlot).isEmpty) {
      return _Classifier(
        spec: classifier,
        onSelected: (slotId) =>
            onChanged(session.withSlot(kSelectedLensSlot, slotId)),
      );
    }

    final selected = session.text(kSelectedLensSlot);
    final lenses = selected.isEmpty
        ? config.lenses
        : [
            for (final lens in config.lenses)
              if (lens.slotId == selected) lens,
          ];

    return ListView(
      children: [
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () =>
                  onChanged(session.withSlot(kSelectedLensSlot, '')),
              icon: const Icon(Icons.refresh),
              label: const Text('Answer the questions again'),
            ),
          ),
        for (final lens in lenses)
          _LensCard(
            key: ValueKey(lens.slotId),
            lens: lens,
            initial: session.text(lens.slotId),
            onChanged: (value) =>
                onChanged(session.withSlot(lens.slotId, value)),
          ),
      ],
    );
  }
}

/// Asks the classifier's questions and reports the lens they land on.
///
/// Every question is shown, each answer selecting a lens directly — there is
/// no multi-step wizard state, because a classifier that needed one would be
/// asking the user to do the sorting the tool exists to do. If a future tool
/// genuinely needs branching questions, that is a real feature to add here,
/// not a `_index` field kept around unused in the meantime.
class _Classifier extends StatelessWidget {
  const _Classifier({required this.spec, required this.onSelected});

  final ClassifierSpec spec;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        for (final question in spec.questions) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
            child: Text(question.prompt, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final answer in question.answers)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(answer.label),
                onTap: () => onSelected(answer.lensSlotId),
              ),
            ),
        ],
      ],
    );
  }
}

class _LensCard extends StatefulWidget {
  const _LensCard({
    required this.lens,
    required this.initial,
    required this.onChanged,
    super.key,
  });

  final LensCard lens;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_LensCard> createState() => _LensCardState();
}

class _LensCardState extends State<_LensCard> {
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
    // The swatch is a stripe rather than a fill: these methods name colours,
    // but a card flooded with one would fail contrast against body text and
    // fight the single-accent palette.
    final swatch = widget.lens.swatch;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (swatch != null) ...[
                  Container(
                    width: AppSpacing.xs,
                    height: AppTextSize.subtitle,
                    color: Color(swatch),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    widget.lens.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.lens.prompt,
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
