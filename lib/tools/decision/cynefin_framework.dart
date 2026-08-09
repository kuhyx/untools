/// Cynefin — work out what kind of situation you are in first.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Five domains, each with the response that suits it.
///
/// Dave Snowden's framework (IBM, 1999; set out with Mary Boone in *Harvard
/// Business Review*, 2007). Its value is upstream of any particular action:
/// most bad responses come from treating one kind of situation as another —
/// convening experts for something nobody can analyse, or running experiments
/// where best practice already exists.
///
/// Reached through a classifier rather than a menu, because someone who could
/// already name their domain would not need the framework.
const cynefinFramework = LensConfig(
  id: 'cynefin-framework',
  name: 'Cynefin',
  blurb:
      'Before deciding what to do, work out what kind of situation this '
      'is. The right response to a complicated problem is the wrong response '
      'to a chaotic one.',
  attribution:
      'Devised by Dave Snowden (with Mary Boone, Harvard '
      'Business Review, 2007)',
  primary: ToolCategory.decisionMaking,
  tags: ['sense-making', 'response', 'quick'],
  related: ['ladder-of-inference', 'iceberg-model', 'decision-matrix'],
  classifier: ClassifierSpec(
    questions: [
      ClassifierQuestion(
        prompt: 'How well do you understand what causes what here?',
        answers: [
          ClassifierAnswer(
            label: 'It is obvious — anyone would see it the same way',
            lensSlotId: 'clear',
          ),
          ClassifierAnswer(
            label: 'It can be worked out, but it needs expertise',
            lensSlotId: 'complicated',
          ),
          ClassifierAnswer(
            label: 'Only in hindsight; I cannot predict it',
            lensSlotId: 'complex',
          ),
          ClassifierAnswer(
            label: 'Not at all, and something is on fire right now',
            lensSlotId: 'chaotic',
          ),
          // Reachable on purpose: "several of these at once" is the most
          // common honest answer, and a classifier that forces a single
          // choice would push the user into the wrong domain rather than
          // telling them to split the problem up.
          ClassifierAnswer(
            label: 'Several of these at once, depending on the part',
            lensSlotId: 'disorder',
          ),
        ],
      ),
    ],
  ),
  lenses: [
    LensCard(
      slotId: 'clear',
      name: 'Clear',
      prompt:
          'Sense, categorise, respond. Apply the known practice and move '
          'on. Watch for complacency: this is the domain that quietly turns '
          'chaotic when conditions change and nobody notices.',
    ),
    LensCard(
      slotId: 'complicated',
      name: 'Complicated',
      prompt:
          'Sense, analyse, respond. There is a right answer and expertise '
          'will find it. Budget the analysis — the risk here is over-thinking, '
          'not under-thinking.',
    ),
    LensCard(
      slotId: 'complex',
      name: 'Complex',
      prompt:
          'Probe, sense, respond. Cause only becomes clear afterwards, so '
          'run a small safe-to-fail experiment rather than a plan. What could '
          'you try that would teach you something either way?',
    ),
    LensCard(
      slotId: 'chaotic',
      name: 'Chaotic',
      prompt:
          'Act, sense, respond. Stop the bleeding first and analyse later. '
          'Any action that restores some stability beats the best action taken '
          'too late.',
    ),
    LensCard(
      slotId: 'disorder',
      name: 'Not sure',
      prompt:
          'If none of the others fit, the situation is probably several at '
          'once. Break it into parts and place each part separately — the '
          'blend is what makes it feel unanswerable.',
    ),
  ],
);
