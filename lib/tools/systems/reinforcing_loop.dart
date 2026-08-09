/// Mapping a cycle that feeds itself.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// A loop where each stage amplifies the next, so the whole thing accelerates.
///
/// From system dynamics, in the Forrester and Meadows lineage. A reinforcing
/// loop is what makes growth compound and collapses run away — the same
/// structure either way, which is why naming the stages matters more than
/// judging them. Adding stages is expected: the loop is only useful once it
/// closes on something you had not connected.
const reinforcingLoop = LoopConfig(
  id: 'reinforcing-loop',
  name: 'Reinforcing loop',
  blurb:
      'Something growing or collapsing faster the longer it runs. Name the '
      'stages that feed each other and the engine becomes visible.',
  attribution: 'From system dynamics, in the Forrester and Meadows lineage',
  primary: ToolCategory.systemsThinking,
  tags: ['feedback', 'growth', 'systems'],
  related: ['connection-circles', 'balancing-loop', 'iceberg-model'],
  growable: true,
  phases: [
    LoopPhase(
      slotId: 'phase-1',
      name: 'Starting change',
      prompt: 'Something increases or decreases. What, and in which direction?',
    ),
    LoopPhase(
      slotId: 'phase-2',
      name: 'What that drives',
      prompt: 'What does that change cause more of?',
    ),
    LoopPhase(
      slotId: 'phase-3',
      name: 'Back to the start',
      prompt:
          'How does that feed back into the first stage, pushing it further '
          'the same way?',
    ),
  ],
);
