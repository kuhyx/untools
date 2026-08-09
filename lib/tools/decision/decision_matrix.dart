/// Decision matrix — score options against weighted factors.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Make the trade-off explicit instead of arguing about the conclusion.
///
/// A long-standing public method, also known as a weighted scoring or Pugh
/// matrix. The arithmetic is not the point: writing down the weights forces
/// you to say what you actually care about, and the total is often most useful
/// when it disagrees with your gut and you have to work out which one is wrong.
const decisionMatrix = ScoredGridConfig(
  id: 'decision-matrix',
  name: 'Decision matrix',
  blurb:
      'Several decent options and no obvious winner? Score each against '
      'the factors that matter, weighted by how much they matter.',
  attribution: 'A classic weighted-scoring (Pugh) matrix',
  primary: ToolCategory.decisionMaking,
  tags: ['comparison', 'scoring'],
  related: ['hard-choice-model', 'eisenhower-matrix', 'second-order-thinking'],
  mode: GridMode.weightedScore,
  rowNoun: 'Option',
  columnNoun: 'Factor',
);
