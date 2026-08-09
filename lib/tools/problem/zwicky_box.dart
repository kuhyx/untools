/// Zwicky box — build solutions you would not have thought of, by combining
/// parts.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Break a problem into independent attributes, then mix one value from each.
///
/// Fritz Zwicky called it morphological analysis and used it to enumerate
/// astrophysical possibilities systematically rather than by inspiration. The
/// point is coverage: listing values per attribute and combining them produces
/// candidates nobody would propose out loud, including the good ones that
/// sound wrong until you see them written down.
const zwickyBox = ScoredGridConfig(
  id: 'zwicky-box',
  name: 'Zwicky box',
  blurb:
      'You keep generating variations on the same idea. Split the problem '
      'into independent attributes, list the options for each, and combine '
      'across them.',
  attribution: 'Devised by Fritz Zwicky (morphological analysis)',
  primary: ToolCategory.problemSolving,
  tags: ['ideation', 'combinations', 'coverage'],
  related: ['first-principles', 'abstraction-laddering', 'decision-matrix'],
  mode: GridMode.combination,
  rowNoun: 'Value',
  columnNoun: 'Attribute',
);
