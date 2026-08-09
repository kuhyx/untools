/// Inversion — attack the problem from the failure end.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Work out how to fail, then refuse to do those things.
///
/// Attributed to Carl Gustav Jacob Jacobi ("invert, always invert") and made
/// widely known by Charlie Munger.
const inversion = WizardConfig(
  id: 'inversion',
  name: 'Inversion',
  blurb:
      'Stuck picturing only the good outcome? Describe the disaster '
      'instead, then work out what would have caused it.',
  attribution: 'Carl Gustav Jacob Jacobi; popularised by Charlie Munger',
  primary: ToolCategory.problemSolving,
  tags: ['reframing', 'risk', 'quick'],
  related: ['first-principles', 'abstraction-laddering'],
  steps: [
    WizardStep(
      slotId: 'worst',
      title: 'Describe the worst version',
      prompt: 'What would the most damaging way to handle this look like?',
      helper: 'Be specific and unkind. Vague failures give vague lessons.',
    ),
    WizardStep(
      slotId: 'why-bad',
      title: 'Say why that is bad',
      prompt: 'What exactly makes that outcome so damaging?',
      helper: 'One reason per line. These become your constraints.',
    ),
    WizardStep(
      slotId: 'inverted',
      title: 'Invert each reason',
      prompt: 'For each reason above, what would prevent it?',
      helper:
          'This list is your plan — it is built from avoided failures '
          'rather than imagined successes.',
    ),
  ],
);
