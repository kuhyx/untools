/// Deciding and acting faster than the situation changes.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Observe, Orient, Decide, Act — then round again.
///
/// John Boyd developed the loop from air-combat analysis: the pilot who cycles
/// faster forces the other to react to a situation that has already moved on.
/// Orient is the step people skip and the one Boyd cared most about — it is
/// where your existing assumptions distort what you just observed.
///
/// The four phases are fixed. Boyd's loop is not a template to customise.
const oodaLoop = LoopConfig(
  id: 'ooda-loop',
  name: 'OODA loop',
  blurb:
      'A situation moving faster than your decisions. Cycle deliberately '
      'instead of reacting, and notice where your assumptions distort what '
      'you are seeing.',
  attribution: 'Devised by John Boyd',
  primary: ToolCategory.decisionMaking,
  tags: ['speed', 'uncertainty', 'iteration'],
  related: [
    'cynefin-framework',
    'ladder-of-inference',
    'second-order-thinking',
  ],
  phases: [
    LoopPhase(
      slotId: 'observe',
      name: 'Observe',
      prompt: 'What is actually happening? Raw signals, not conclusions.',
    ),
    LoopPhase(
      slotId: 'orient',
      name: 'Orient',
      prompt:
          'What frame are you reading this through, and whose view would '
          'differ? This is the step that decides the other three.',
    ),
    LoopPhase(
      slotId: 'decide',
      name: 'Decide',
      prompt: 'Given that orientation, what is the next action?',
    ),
    LoopPhase(
      slotId: 'act',
      name: 'Act',
      prompt: 'Do it, and note what you expect to observe as a result.',
    ),
  ],
);
