/// Five whys — follow a symptom down to something worth fixing.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Ask "why?" of each answer in turn until the cause is one you can act on.
///
/// Sakichi Toyoda's method, embedded in the Toyota Production System by Taiichi
/// Ohno. Five is a rule of thumb, not a target — stopping at a person rather
/// than a process is the usual failure, and it is why the prompts here push
/// toward conditions instead of blame.
const fiveWhys = TreeConfig(
  id: 'five-whys',
  name: 'Five whys',
  blurb:
      'A problem you have already fixed once. Follow it down through each '
      '"why" until you reach a cause that stays fixed.',
  attribution: 'Devised by Sakichi Toyoda, developed at Toyota by Taiichi Ohno',
  primary: ToolCategory.problemSolving,
  tags: ['root cause', 'quick'],
  related: ['issue-trees', 'ishikawa-diagram', 'iceberg-model'],
  rootPrompt: 'State the problem exactly as it was observed.',
  modes: [
    TreeMode(
      id: 'why',
      label: 'Why?',
      childPrompt:
          'Why did that happen? Name a condition or a process, not a person.',
    ),
  ],
);
