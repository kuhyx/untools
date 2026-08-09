/// Ladder of inference — find the rung where the leap happened.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Seven rungs from raw data to action, walked downward.
///
/// Chris Argyris' model, made widely known by Peter Senge in *The Fifth
/// Discipline*. The climb up happens in about a second and feels like
/// observation; the walk back down is the work. Written top-down here so the
/// conclusion you already reached sits at the top, where you start.
const ladderOfInference = LadderConfig(
  id: 'ladder-of-inference',
  name: 'Ladder of inference',
  blurb:
      'You are certain about something and someone else is not. Walk back '
      'down from the conclusion to the raw data and find the rung where you '
      'jumped.',
  attribution: 'Chris Argyris; popularised by Peter Senge',
  primary: ToolCategory.decisionMaking,
  tags: ['assumptions', 'conflict', 'reasoning'],
  related: ['second-order-thinking', 'inversion', 'iceberg-model'],
  fixedRungs: [
    RungSpec(
      slotId: 'actions',
      name: 'Actions',
      prompt: 'What are you about to do, or already doing?',
    ),
    RungSpec(
      slotId: 'beliefs',
      name: 'Beliefs',
      prompt: 'What do you now believe in general, beyond this one case?',
    ),
    RungSpec(
      slotId: 'conclusions',
      name: 'Conclusions',
      prompt: 'What did you conclude about this situation?',
    ),
    RungSpec(
      slotId: 'assumptions',
      name: 'Assumptions',
      prompt:
          'What did you take as given to reach that? Name the thing so '
          'obvious it felt unnecessary to state.',
    ),
    RungSpec(
      slotId: 'interpretations',
      name: 'Interpretations',
      prompt:
          'What meaning did you add? Where did you infer intent, '
          'competence or attitude?',
    ),
    RungSpec(
      slotId: 'selected-data',
      name: 'Selected data',
      prompt:
          'Which details did you focus on — and, harder, which did you '
          'leave out?',
    ),
    RungSpec(
      slotId: 'available-data',
      name: 'Available data',
      prompt:
          'What could an unbiased observer have recorded? Only what was '
          'said or done, with no reading of motive.',
    ),
  ],
);
