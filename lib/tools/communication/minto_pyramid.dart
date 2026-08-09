/// Minto pyramid — answer first, then support it.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Conclusion, then the reasons, then the evidence.
///
/// Barbara Minto's principle, developed at McKinsey. The instinct is to
/// present the journey you took and arrive at the answer last, which makes the
/// listener hold everything in suspense; leading with the answer lets them
/// judge whether they even need the rest.
const mintoPyramid = LadderConfig(
  id: 'minto-pyramid',
  name: 'Minto pyramid',
  blurb:
      'You have to explain something and want it to land. Say the answer '
      'first, then why, then the evidence — not the order you discovered it '
      'in.',
  attribution: 'Devised by Barbara Minto',
  primary: ToolCategory.communication,
  tags: ['writing', 'structure', 'quick'],
  related: ['feedback-framer', 'issue-trees', 'concept-map'],
  fixedRungs: [
    RungSpec(
      slotId: 'answer',
      name: 'The answer',
      prompt:
          'One sentence. If they read nothing else, what should they know '
          'or do?',
    ),
    RungSpec(
      slotId: 'reasons',
      name: 'Why',
      prompt:
          'The two to four reasons that support it. Each should stand on '
          'its own, and together they should be the whole case.',
    ),
    RungSpec(
      slotId: 'evidence',
      name: 'Evidence',
      prompt:
          'Facts, numbers and examples under each reason. Optional — '
          'include only what this audience needs.',
    ),
  ],
);
