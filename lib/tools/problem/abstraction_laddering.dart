/// Abstraction laddering — check you are solving the right problem.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Ask "why?" to go broader, "how?" to go narrower.
///
/// Grounded in S.I. Hayakawa's ladder of abstraction and adapted into design
/// practice. A problem stated too narrowly hides the better solution one rung
/// up; stated too broadly it has no handle. The pinned starting rung matters:
/// you want to see how far you have moved from where you began.
const abstractionLaddering = LadderConfig(
  id: 'abstraction-laddering',
  name: 'Abstraction laddering',
  blurb:
      'Your problem statement may be the wrong altitude. Go up for a '
      'broader framing, down for a more concrete one, and pick the rung worth '
      'solving.',
  attribution:
      "From S.I. Hayakawa's ladder of abstraction, adapted for "
      'design practice',
  primary: ToolCategory.problemSolving,
  tags: ['reframing', 'quick'],
  related: ['first-principles', 'issue-trees', 'inversion'],
  grow: GrowSpec(
    seedPrompt: 'State the problem as you currently have it.',
    upLabel: 'Why does that matter?',
    upPrompt:
        'A broader statement of the same problem. What is the point of '
        'solving the rung below?',
    downLabel: 'How would you do it?',
    downPrompt:
        'A more concrete statement. What specifically would solving '
        'the rung above involve?',
  ),
);
