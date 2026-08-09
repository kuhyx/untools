/// Finding the feedback loops hiding in a list of moving parts.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Elements around a circle, signed arrows between them, loops read off.
///
/// A staple of the systems-thinking teaching tradition — the Waters Center's
/// Habits of a Systems Thinker, drawing on Jay Forrester's system dynamics and
/// popularised by Donella Meadows. The circle is a device: it removes the
/// temptation to arrange things in a causal order you have already assumed, so
/// the loops you find are the ones actually in the arrows.
///
/// This is the tool the app can genuinely compute. Spotting that four arrows
/// close into a reinforcing loop is exactly the step people miss by eye.
const connectionCircles = GraphConfig(
  id: 'connection-circles',
  name: 'Connection circles',
  blurb:
      'A situation that keeps escalating or stubbornly refuses to move. Map '
      'what affects what, and the feedback loops driving it show up.',
  attribution:
      'From the systems-thinking tradition, in the Forrester and Meadows '
      'lineage',
  primary: ToolCategory.systemsThinking,
  tags: ['feedback', 'systems', 'causal'],
  related: ['iceberg-model', 'ishikawa-diagram', 'second-order-thinking'],
  variant: GraphVariant.circle,
  seeds: [],
);
