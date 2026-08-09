/// Iceberg model — look under the event for what keeps producing it.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Four levels: what happened, what keeps happening, what makes it happen,
/// and what makes that seem normal.
///
/// Standard systems-thinking teaching material, in the lineage of Donella
/// Meadows' work on structure and leverage. The deeper you go the more
/// leverage you have and the less comfortable the answer gets, which is
/// exactly why most analysis stops at the top level.
const icebergModel = LadderConfig(
  id: 'iceberg-model',
  name: 'Iceberg model',
  blurb:
      'The same problem keeps coming back. Look under the incident for the '
      'pattern, the structure producing it, and the belief that keeps that '
      'structure in place.',
  attribution: 'Systems-thinking canon, in the Donella Meadows lineage',
  primary: ToolCategory.systemsThinking,
  tags: ['root-cause', 'recurring'],
  related: ['connection-circles', 'issue-trees', 'inversion'],
  waterlineAfter: 1,
  fixedRungs: [
    RungSpec(
      slotId: 'events',
      name: 'Events',
      prompt: 'What happened? Just the incident, as it appeared.',
    ),
    RungSpec(
      slotId: 'patterns',
      name: 'Patterns',
      prompt:
          'What has been happening over time? Has this occurred before, '
          'and is it getting more or less frequent?',
    ),
    RungSpec(
      slotId: 'structures',
      name: 'Structures',
      prompt:
          'What arrangement produces that pattern? Incentives, processes, '
          'schedules, who talks to whom, what is measured.',
    ),
    RungSpec(
      slotId: 'mental-models',
      name: 'Mental models',
      prompt:
          'What belief makes that structure seem reasonable? This is the '
          'level with the most leverage and the least comfort.',
    ),
  ],
);
