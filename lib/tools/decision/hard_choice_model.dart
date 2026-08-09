/// Hard choice model — tell a hard decision from a merely uncomfortable one.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Sort options by how good they are against how easily you can undo them.
///
/// The reversibility axis is Jeff Bezos's one-way/two-way door distinction; the
/// pairing with option quality is standard decision-making practice. The claim
/// worth taking seriously is that most decisions people agonise over are
/// reversible, and the agonising itself is the real cost.
const hardChoiceModel = MatrixConfig(
  id: 'hard-choice-model',
  name: 'Hard choice model',
  blurb:
      'A decision you keep turning over. Check whether it is genuinely hard '
      'or merely uncomfortable — most are reversible and not worth the delay.',
  attribution:
      'The one-way/two-way door framing is Jeff Bezos; the grid is common '
      'decision-making practice',
  primary: ToolCategory.decisionMaking,
  tags: ['reversibility', 'speed'],
  related: ['eisenhower-matrix', 'impact-effort-matrix', 'inversion'],
  xAxis: AxisSpec(
    label: 'Reversibility',
    lowLabel: 'One-way door',
    highLabel: 'Two-way door',
  ),
  yAxis: AxisSpec(
    label: 'Option quality',
    lowLabel: 'Weak option',
    highLabel: 'Strong option',
  ),
  quadrants: [
    QuadrantSpec(
      corner: QuadrantCorner.topRight,
      slotId: 'just-decide',
      name: 'Just decide',
      action: 'Good and undoable. Deliberating costs more than being wrong.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.topLeft,
      slotId: 'take-the-time',
      name: 'Take the time',
      action: 'Good but permanent. This is where the care belongs.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomRight,
      slotId: 'try-it',
      name: 'Try it',
      action: 'Weak but cheap to undo. Run it as an experiment.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomLeft,
      slotId: 'avoid',
      name: 'Avoid',
      action: 'Weak and permanent. Find another option.',
    ),
  ],
);
