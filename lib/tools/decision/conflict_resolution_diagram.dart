/// Dissolving a conflict by finding the assumption underneath it.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Five boxes: one shared objective, two needs, two competing proposals.
///
/// Eliyahu Goldratt's "evaporating cloud", from the Theory of Constraints. The
/// method's claim is that a persistent conflict is not a clash of goals but a
/// hidden assumption connecting a need to *one* way of meeting it. Both sides
/// usually share the objective, which is why the diagram starts there.
///
/// The five slots are fixed. A sixth box would make it a different diagram.
const conflictResolutionDiagram = GraphConfig(
  id: 'conflict-resolution-diagram',
  name: 'Conflict resolution diagram',
  blurb:
      'Two options that seem mutually exclusive. Surface the need behind '
      'each, and the assumption forcing the choice often turns out to be '
      'optional.',
  attribution: 'Devised by Eliyahu Goldratt (the evaporating cloud)',
  primary: ToolCategory.decisionMaking,
  tags: ['conflict', 'assumptions', 'constraints'],
  related: ['inversion', 'ladder-of-inference', 'perspective-lenses'],
  variant: GraphVariant.cloud,
  seeds: [
    SeedNode(
      slotId: 'objective',
      label: 'Shared objective',
      prompt:
          'What both sides ultimately want. If you cannot find one, the '
          'disagreement is about goals, not method.',
    ),
    SeedNode(
      slotId: 'need-a',
      label: 'Need A',
      prompt: 'The requirement the first proposal exists to satisfy.',
    ),
    SeedNode(
      slotId: 'need-b',
      label: 'Need B',
      prompt: 'The requirement the second proposal exists to satisfy.',
    ),
    SeedNode(
      slotId: 'proposal-a',
      label: 'Proposal A',
      prompt: 'The first course of action, stated concretely.',
    ),
    SeedNode(
      slotId: 'proposal-b',
      label: 'Proposal B',
      prompt: 'The competing course of action.',
    ),
  ],
);
