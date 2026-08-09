/// Cause-and-effect analysis along a fixed set of categories.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// One effect, and the categories of cause that feed it.
///
/// Kaoru Ishikawa developed the diagram at Kawasaki in the 1960s. The fixed
/// rib set is the whole point: left to free association, a team lists causes
/// from the one or two areas it already suspects. Being asked "and what about
/// measurement?" is what surfaces the cause nobody was looking at.
const ishikawaDiagram = GraphConfig(
  id: 'ishikawa-diagram',
  name: 'Cause-and-effect diagram',
  blurb:
      'A problem with too many candidate causes. Sort them into categories '
      'so you can see which area you have not actually examined.',
  attribution: 'Devised by Kaoru Ishikawa (the fishbone diagram)',
  primary: ToolCategory.systemsThinking,
  tags: ['root cause', 'quality'],
  related: ['issue-trees', 'iceberg-model', 'connection-circles'],
  variant: GraphVariant.fishbone,
  seeds: [
    SeedNode(
      slotId: 'effect',
      label: 'The effect',
      prompt: 'The problem as observed, not its suspected cause.',
    ),
    SeedNode(
      slotId: 'people',
      label: 'People',
      prompt: 'Skills, staffing, handovers, incentives.',
    ),
    SeedNode(
      slotId: 'process',
      label: 'Process',
      prompt: 'Steps, approvals, queues, the way work moves.',
    ),
    SeedNode(
      slotId: 'tools',
      label: 'Tools',
      prompt: 'Equipment, software, anything the work depends on.',
    ),
    SeedNode(
      slotId: 'materials',
      label: 'Materials',
      prompt: 'Inputs, data, supplies and their quality.',
    ),
    SeedNode(
      slotId: 'environment',
      label: 'Environment',
      prompt: 'Physical conditions, deadlines, organisational pressure.',
    ),
    SeedNode(
      slotId: 'measurement',
      label: 'Measurement',
      prompt: 'What is measured, how, and what that makes people do.',
    ),
  ],
);
