/// First principles — rebuild from what you know is true.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Strip a problem to what cannot be reduced further, then build back up.
///
/// The idea is Aristotle's; its modern currency comes from engineering and
/// investing practice. The work is resisting the answer you already have:
/// reasoning by analogy ("this is like X, so do what X did") is faster and
/// almost always where the received wisdom you are trying to escape came from.
const firstPrinciples = TreeConfig(
  id: 'first-principles',
  name: 'First principles',
  blurb:
      'Everyone does it a certain way and you suspect the reason is habit. '
      'Break the problem down to what is actually, unavoidably true.',
  attribution: 'From Aristotle; a staple of modern engineering practice',
  primary: ToolCategory.problemSolving,
  tags: ['decomposition', 'innovation'],
  related: ['issue-trees', 'inversion', 'abstraction-laddering'],
  rootPrompt: 'What are you trying to work out from scratch?',
  modes: [
    TreeMode(
      id: 'decompose',
      label: 'Decompose',
      childPrompt: 'What is this made of? Why must that be so?',
    ),
  ],
);
