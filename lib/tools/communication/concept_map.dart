/// Laying out what you know about a subject, and how the pieces relate.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Free-form concepts joined by links that say *how* they relate.
///
/// Developed by Joseph Novak and Alberto Cañas at Cornell, out of Ausubel's
/// work on meaningful learning. The labelled link is the discipline: "caching"
/// next to "latency" records nothing, while "caching → reduces → latency" is a
/// claim you can check and be wrong about. Unlabelled boxes are the failure
/// mode this tool exists to prevent.
const conceptMap = GraphConfig(
  id: 'concept-map',
  name: 'Concept map',
  blurb:
      'A subject you half-understand. Write down the pieces and name the '
      'relationship on every link — the gaps become obvious.',
  attribution: 'Devised by Joseph Novak and Alberto Cañas',
  primary: ToolCategory.communication,
  tags: ['learning', 'structure', 'explanation'],
  related: ['minto-pyramid', 'abstraction-laddering', 'connection-circles'],
  variant: GraphVariant.free,
  seeds: [],
);
