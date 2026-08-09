/// Eisenhower matrix — sort work by importance against urgency.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Separate what matters from what merely shouts.
///
/// The urgent/important distinction comes from a 1954 Dwight D. Eisenhower
/// speech, quoting an unnamed college president; the 2x2 grid itself is
/// Stephen Covey's, from *The 7 Habits of Highly Effective People* (1989).
/// Both are credited because the grid is very often misattributed wholesale to
/// Eisenhower, who never drew it.
///
/// The interesting quadrant is important-but-not-urgent: it is the only one
/// that is never forced on you, so it is the one that quietly gets dropped.
const eisenhowerMatrix = MatrixConfig(
  id: 'eisenhower-matrix',
  name: 'Eisenhower matrix',
  blurb:
      'Everything feels urgent. Sort it by whether it actually matters, '
      'and the list stops being flat.',
  attribution: 'Dwight D. Eisenhower (1954 speech); grid by Stephen Covey',
  primary: ToolCategory.decisionMaking,
  tags: ['prioritisation', 'quick'],
  related: ['impact-effort-matrix', 'decision-matrix', 'hard-choice-model'],
  xAxis: AxisSpec(
    label: 'Urgency',
    lowLabel: 'Not urgent',
    highLabel: 'Urgent',
  ),
  yAxis: AxisSpec(
    label: 'Importance',
    lowLabel: 'Not important',
    highLabel: 'Important',
  ),
  quadrants: [
    QuadrantSpec(
      corner: QuadrantCorner.topRight,
      slotId: 'do',
      name: 'Do',
      action: 'Handle it now.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.topLeft,
      slotId: 'schedule',
      name: 'Schedule',
      action:
          'Give it a time. Nothing will force you to, which is why it '
          'slips.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomRight,
      slotId: 'delegate',
      name: 'Delegate',
      action: 'Loud, but not yours. Hand it over.',
    ),
    QuadrantSpec(
      corner: QuadrantCorner.bottomLeft,
      slotId: 'drop',
      name: 'Drop',
      action: 'Delete it and stop revisiting the decision.',
    ),
  ],
);
