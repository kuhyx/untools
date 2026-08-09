/// The small value types that make up a [ToolConfig].
///
/// These describe *structure*, never state: a [WizardStep] says what to ask,
/// a [Session] holds what the user answered. Everything here is `const`.
library;

import 'package:untools/model/tool_config.dart';

/// One prompt in a [WizardConfig].
class WizardStep {
  /// Creates a wizard step.
  const WizardStep({
    required this.slotId,
    required this.title,
    required this.prompt,
    this.helper,
    this.multiline = true,
    this.subfields = const [],
  });

  /// Stable key this step's answer is stored under.
  ///
  /// Answers are keyed by slot id, never by list index, so reordering or
  /// inserting a step can never shift a saved answer onto the wrong prompt.
  final String slotId;

  /// Short heading, e.g. `What is the worst option?`.
  final String title;

  /// The question itself.
  final String prompt;

  /// Optional hint under the input.
  final String? helper;

  /// Whether the answer is a paragraph rather than a single line.
  final bool multiline;

  /// Named sub-inputs collected within this one step, e.g. the five fields of
  /// Tim Hurson's DRIVE checklist. Each has its own slot id.
  final List<WizardStep> subfields;
}

/// One axis of a [MatrixConfig].
class AxisSpec {
  /// Creates an axis.
  const AxisSpec({
    required this.label,
    required this.lowLabel,
    required this.highLabel,
  });

  /// What the axis measures, e.g. `Urgency`.
  final String label;

  /// The low end, e.g. `Not urgent`.
  final String lowLabel;

  /// The high end, e.g. `Urgent`.
  final String highLabel;
}

/// Which cell of a 2x2 grid a quadrant occupies.
enum QuadrantCorner {
  /// Low x, high y.
  topLeft,

  /// High x, high y.
  topRight,

  /// Low x, low y.
  bottomLeft,

  /// High x, low y.
  bottomRight,
}

/// One cell of a [MatrixConfig], and what to do with what lands in it.
class QuadrantSpec {
  /// Creates a quadrant.
  const QuadrantSpec({
    required this.corner,
    required this.slotId,
    required this.name,
    required this.action,
  });

  /// Position in the grid.
  final QuadrantCorner corner;

  /// Stable key the items in this quadrant are stored under.
  final String slotId;

  /// What this quadrant is called, e.g. `Quick wins`.
  final String name;

  /// The verb the method prescribes, e.g. `Do it now`.
  final String action;
}

/// A way of extending a [TreeConfig], e.g. asking "why?" versus "how?".
class TreeMode {
  /// Creates a tree mode.
  const TreeMode({
    required this.id,
    required this.label,
    required this.childPrompt,
  });

  /// Stable key, stored on the session so the mode survives a reopen.
  final String id;

  /// Name shown in the mode switcher, e.g. `Problem tree`.
  final String label;

  /// The question asked when adding a child, e.g. `Why is this happening?`.
  final String childPrompt;
}

/// Which layout and editing rules a [GraphConfig] follows.
enum GraphVariant {
  /// Nodes evenly spaced around a circle; edges are signed `+`/`-` and cycles
  /// are detected and labelled. Positions are owned by the layout.
  circle,

  /// A horizontal spine pointing at the problem, with angled category ribs.
  /// The rib set is fixed; sub-causes attach to a rib.
  fishbone,

  /// Five fixed slots: one shared objective, two needs, two proposals.
  /// Nodes cannot be added or removed.
  cloud,

  /// Free placement, labelled edges, no constraints.
  free,
}

/// A node present when a graph session starts.
class SeedNode {
  /// Creates a seed node.
  const SeedNode({
    required this.slotId,
    required this.label,
    this.prompt,
    this.fixed = true,
  });

  /// Stable key this node's text is stored under.
  final String slotId;

  /// Default label, e.g. `Methods`.
  final String label;

  /// Optional prompt shown while editing this node.
  final String? prompt;

  /// Whether the node is part of the template and so cannot be deleted.
  final bool fixed;
}

/// One phase of a [LoopConfig].
class LoopPhase {
  /// Creates a loop phase.
  const LoopPhase({
    required this.slotId,
    required this.name,
    required this.prompt,
  });

  /// Stable key this phase's note is stored under.
  final String slotId;

  /// Phase name, e.g. `Observe`.
  final String name;

  /// What to write here.
  final String prompt;
}

/// One level of a fixed [LadderConfig].
class RungSpec {
  /// Creates a rung.
  const RungSpec({
    required this.slotId,
    required this.name,
    required this.prompt,
  });

  /// Stable key this level's note is stored under.
  final String slotId;

  /// Level name, e.g. `Assumptions`.
  final String name;

  /// The question that interrogates this level.
  final String prompt;
}

/// How a growable ladder is extended.
class GrowSpec {
  /// Creates a grow spec.
  const GrowSpec({
    required this.seedPrompt,
    required this.upLabel,
    required this.upPrompt,
    required this.downLabel,
    required this.downPrompt,
  });

  /// Prompt for the starting rung, which is pinned in the middle.
  final String seedPrompt;

  /// Action that adds a rung above, e.g. `Why?`.
  final String upLabel;

  /// What that rung should contain — a broader framing.
  final String upPrompt;

  /// Action that adds a rung below, e.g. `How?`.
  final String downLabel;

  /// What that rung should contain — a more concrete framing.
  final String downPrompt;
}

/// One perspective in a [LensConfig].
class LensCard {
  /// Creates a lens.
  const LensCard({
    required this.slotId,
    required this.name,
    required this.prompt,
    this.swatch,
  });

  /// Stable key this lens's note is stored under.
  final String slotId;

  /// Lens name, e.g. `Risks`.
  final String name;

  /// What to look for through it.
  final String prompt;

  /// Optional accent colour as `0xAARRGGBB`, for methods that name colours.
  ///
  /// An `int` rather than a `Color` so the model layer stays free of Flutter
  /// imports and remains testable as plain Dart.
  final int? swatch;
}

/// A question that narrows the user down to one lens.
class ClassifierSpec {
  /// Creates a classifier.
  const ClassifierSpec({required this.questions});

  /// The questions, asked in order.
  final List<ClassifierQuestion> questions;
}

/// One question in a [ClassifierSpec].
class ClassifierQuestion {
  /// Creates a classifier question.
  const ClassifierQuestion({required this.prompt, required this.answers});

  /// The question text.
  final String prompt;

  /// The available answers.
  final List<ClassifierAnswer> answers;
}

/// One answer to a [ClassifierQuestion], and where it leads.
class ClassifierAnswer {
  /// Creates a classifier answer.
  const ClassifierAnswer({required this.label, required this.lensSlotId});

  /// Answer text.
  final String label;

  /// The [LensCard.slotId] this answer selects.
  final String lensSlotId;
}

/// What a [ScoredGridConfig]'s grid computes.
enum GridMode {
  /// Rows are options, columns are weighted factors; the total picks a winner.
  weightedScore,

  /// Columns are independent attributes holding candidate values; picking one
  /// value per column composes a candidate solution.
  combination,
}
