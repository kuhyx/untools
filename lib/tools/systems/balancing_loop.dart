/// Mapping a cycle that pushes back against its own change.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// A loop that resists change and holds a system near a target.
///
/// From system dynamics, in the Forrester and Meadows lineage. A balancing
/// loop is why an effort produces less than expected: something in the cycle
/// is correcting toward a goal you may not have noticed you set. Finding the
/// gap between the current state and that implicit goal is the whole exercise.
const balancingLoop = LoopConfig(
  id: 'balancing-loop',
  name: 'Balancing loop',
  blurb:
      'A situation that stubbornly returns to where it started however hard '
      'you push. Find the correction holding it there, and the goal it is '
      'correcting toward.',
  attribution: 'From system dynamics, in the Forrester and Meadows lineage',
  primary: ToolCategory.systemsThinking,
  tags: ['feedback', 'stability', 'systems'],
  related: ['connection-circles', 'reinforcing-loop', 'iceberg-model'],
  growable: true,
  phases: [
    LoopPhase(
      slotId: 'phase-1',
      name: 'Current state',
      prompt: 'Where is the thing you are trying to move, right now?',
    ),
    LoopPhase(
      slotId: 'phase-2',
      name: 'Implicit goal',
      prompt:
          'What level does the system behave as though it wants? Often nobody '
          'chose this on purpose.',
    ),
    LoopPhase(
      slotId: 'phase-3',
      name: 'The gap',
      prompt: 'How far apart are those two, and who notices the difference?',
    ),
    LoopPhase(
      slotId: 'phase-4',
      name: 'Corrective action',
      prompt:
          'What does the system do in response, pulling the state back toward '
          'the goal?',
    ),
  ],
);
