/// The router that turns "I am stuck" into a specific tool.
///
/// This is the app's primary entry point, not the alphabetical tool list. A
/// catalogue of 25 frameworks is only useful if you already know which one you
/// need, and someone in the middle of a problem usually does not — they know
/// the *shape* of being stuck. So the first screen asks that instead.
library;

/// A symptom of being stuck, and the tool that addresses it.
class GuideQuestion {
  /// Creates a guide entry.
  const GuideQuestion({required this.question, required this.toolId});

  /// The user's situation, in their words rather than the method's.
  final String question;

  /// The [ToolConfig.id] to open. Validated by the registry test.
  final String toolId;
}

/// The question-to-tool table, in the order shown.
///
/// Only questions whose tool is registered appear; the registry test enforces
/// that, so an entry can be written the moment its tool lands rather than
/// being tracked separately.
const List<GuideQuestion> guideQuestions = [
  GuideQuestion(
    question: 'I can only picture this going well.',
    toolId: 'inversion',
  ),
  GuideQuestion(
    question: 'Everything on my list feels urgent.',
    toolId: 'eisenhower-matrix',
  ),
  GuideQuestion(
    question: 'I have several good options and cannot choose.',
    toolId: 'decision-matrix',
  ),
];
