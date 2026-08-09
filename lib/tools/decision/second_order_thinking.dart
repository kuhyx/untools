/// Second-order thinking — and then what?
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Follow each consequence to its own consequences.
///
/// Associated with Howard Marks, who put it at the centre of investment
/// decisions. First-order effects are the ones you intended and are usually
/// obvious; the damage tends to sit two or three steps out, where an incentive
/// you created starts producing behaviour you did not ask for.
const secondOrderThinking = TreeConfig(
  id: 'second-order-thinking',
  name: 'Second-order thinking',
  blurb:
      'The immediate effect looks good. Follow it out — and then what '
      'happens, and then what happens after that?',
  attribution: 'From the investing literature, notably Howard Marks',
  primary: ToolCategory.decisionMaking,
  tags: ['consequences', 'long-term'],
  related: ['inversion', 'ladder-of-inference', 'decision-matrix'],
  rootPrompt: 'What decision or change are you considering?',
  modes: [
    TreeMode(
      id: 'consequences',
      label: 'Consequences',
      childPrompt: 'And then what?',
    ),
  ],
);
