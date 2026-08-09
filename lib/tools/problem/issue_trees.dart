/// Issue trees — break a problem into parts you can actually attack.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// One tree, two directions: "why?" maps causes, "how?" maps solutions.
///
/// The method comes from management-consulting practice, where it is usually
/// paired with MECE — mutually exclusive, collectively exhaustive. That check
/// is the discipline: branches that overlap double-count the problem, and
/// branches that leave a gap hide the cause you never considered.
const issueTrees = TreeConfig(
  id: 'issue-trees',
  name: 'Issue trees',
  blurb:
      'A problem too big to hold in your head. Split it into branches, '
      'then split those, until you reach something you can act on.',
  attribution: 'From management-consulting practice (the MECE issue tree)',
  primary: ToolCategory.problemSolving,
  tags: ['decomposition', 'structure'],
  related: ['first-principles', 'abstraction-laddering', 'iceberg-model'],
  rootPrompt: 'State the problem you are breaking down.',
  meceCheck: true,
  modes: [
    TreeMode(
      id: 'why',
      label: 'Causes (why?)',
      childPrompt: 'Why does this happen?',
    ),
    TreeMode(
      id: 'how',
      label: 'Solutions (how?)',
      childPrompt: 'How might we fix this?',
    ),
  ],
);
