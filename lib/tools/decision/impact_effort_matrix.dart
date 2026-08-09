/// Impact-effort matrix — find the work that pays for itself soonest.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Sort candidate work by what it returns against what it costs.
///
/// A staple of lean and agile prioritisation practice with no single named
/// originator; the action-priority framing is widely taught in project
/// management. The quadrant that earns the grid its keep is high-effort,
/// low-impact: naming something a thankless task is much easier on a diagram
/// than in a meeting.
const impactEffortMatrix = MatrixConfig(
  id: 'impact-effort-matrix',
  name: 'Impact-effort matrix',
  blurb:
      'A backlog where everything looks worth doing. Place each item by '
      'payoff against cost and the order stops being a matter of opinion.',
  attribution: 'From lean and agile prioritisation practice',
  primary: ToolCategory.decisionMaking,
  tags: ['prioritisation', 'planning'],
  related: ['eisenhower-matrix', 'decision-matrix', 'hard-choice-model'],
  xAxis: AxisSpec(
    label: 'Effort',
    lowLabel: 'Low effort',
    highLabel: 'High effort',
  ),
  yAxis: AxisSpec(
    label: 'Impact',
    lowLabel: 'Low impact',
    highLabel: 'High impact',
  ),
  quadrants: [
    QuadrantSpec(
      corner: QuadrantCorner.topLeft,
      slotId: 'quick-wins',
      name: 'Quick wins',
      action: 'Do these first.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.topRight,
      slotId: 'big-bets',
      name: 'Big bets',
      action: 'Worth it, but plan them properly.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomLeft,
      slotId: 'fill-ins',
      name: 'Fill-ins',
      action: 'Cheap. Do them when there is slack.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomRight,
      slotId: 'thankless',
      name: 'Thankless tasks',
      action: 'Drop these, or say out loud why you cannot.',
    ),
  ],
);
