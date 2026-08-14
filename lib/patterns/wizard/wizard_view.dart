/// Pattern A — a tool worked through as an ordered sequence of prompts.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';

/// Renders each step as a titled prompt with a text field.
///
/// All steps are shown at once rather than one-at-a-time behind a Next button:
/// these methods work by letting a later answer send you back to revise an
/// earlier one, and a stepper that hides the earlier answers actively fights
/// that. Scrolling is the affordance; the sequence is conveyed by order.
class WizardView extends StatelessWidget {
  /// Creates the wizard view.
  const WizardView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's step definitions.
  final WizardConfig config;

  /// Called with the updated session whenever an answer changes.
  final ValueChanged<Session> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final step in config.steps) ...[
          _StepField(
            step: step,
            session: session,
            onChanged: onChanged,
          ),
          for (final sub in step.subfields)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: _StepField(
                step: sub,
                session: session,
                onChanged: onChanged,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepField extends StatefulWidget {
  const _StepField({
    required this.step,
    required this.session,
    required this.onChanged,
  });

  final WizardStep step;
  final Session session;
  final ValueChanged<Session> onChanged;

  @override
  State<_StepField> createState() => _StepFieldState();
}

class _StepFieldState extends State<_StepField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.session.text(widget.step.slotId),
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
            Text(widget.step.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.step.prompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              maxLines: widget.step.multiline ? null : 1,
              minLines: widget.step.multiline ? 3 : 1,
              decoration: InputDecoration(helperText: widget.step.helper),
              onChanged: (value) => widget.onChanged(
                widget.session.withSlot(widget.step.slotId, value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
