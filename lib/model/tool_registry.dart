/// The tool catalogue and the queries over it.
library;

import 'package:untools/model/tool_config.dart';
import 'package:untools/tools/communication/feedback_framer.dart';
import 'package:untools/tools/communication/minto_pyramid.dart';
import 'package:untools/tools/decision/cynefin_framework.dart';
import 'package:untools/tools/decision/decision_matrix.dart';
import 'package:untools/tools/decision/eisenhower_matrix.dart';
import 'package:untools/tools/decision/ladder_of_inference.dart';
import 'package:untools/tools/decision/perspective_lenses.dart';
import 'package:untools/tools/problem/abstraction_laddering.dart';
import 'package:untools/tools/problem/inversion.dart';
import 'package:untools/tools/problem/productive_thinking_model.dart';
import 'package:untools/tools/systems/iceberg_model.dart';

/// Every tool in the app.
///
/// The single place a new tool is registered. A registry test walks this list
/// and asserts ids are unique, attributions are present, and every
/// [ToolConfig.related] id resolves — so a tool added wrong fails CI rather
/// than shipping a dead link.
const List<ToolConfig> allTools = [
  inversion,
  abstractionLaddering,
  productiveThinkingModel,
  eisenhowerMatrix,
  decisionMatrix,
  ladderOfInference,
  perspectiveLenses,
  cynefinFramework,
  icebergModel,
  mintoPyramid,
  feedbackFramer,
];

/// Looks up a tool by [ToolConfig.id], or null when there is no such tool.
///
/// Returns null rather than throwing because the caller is usually resolving
/// an id read from a stored session, where a tool removed in a later build is
/// an expected condition, not a bug.
ToolConfig? toolById(String id) {
  for (final tool in allTools) {
    if (tool.id == id) return tool;
  }
  return null;
}

/// Every tool filed under [category], in registry order.
List<ToolConfig> toolsInCategory(ToolCategory category) => [
  for (final tool in allTools)
    if (tool.primary == category) tool,
];

/// The tools [tool] cross-links to, skipping any id that does not resolve.
List<ToolConfig> relatedTools(ToolConfig tool) => [
  for (final id in tool.related) ?toolById(id),
];
