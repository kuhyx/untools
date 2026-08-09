/// The tool catalogue's type system.
///
/// Every thinking tool in this app is a *configuration*, not a screen. The 25
/// tools collapse into 8 interaction patterns, so each pattern gets one generic
/// widget and each tool is a `const` value of the matching [ToolConfig]
/// subclass. Adding a 26th tool is a config file, not a feature.
///
/// [ToolConfig] is `sealed` on purpose: an exhaustive `switch` over it needs no
/// `default:` arm, which matters because `analysis_options.yaml` promotes
/// `dead_code` to an error and CI enforces 100% line coverage. A JSON-parsed
/// discriminated union would force an "unknown pattern" branch that is
/// unreachable in practice and therefore impossible to cover.
library;

import 'package:untools/model/pattern_specs.dart';

/// The four families the catalogue is browsed by.
///
/// A tool has exactly one [ToolConfig.primary] category but may carry
/// [ToolConfig.tags] and [ToolConfig.related] entries pointing anywhere — the
/// tools genuinely overlap, so cross-links are modelled as data rather than by
/// duplicating a tool into several categories.
enum ToolCategory {
  /// Seeing structure, feedback and root causes in a system.
  systemsThinking('Systems thinking'),

  /// Choosing between options, and working out what kind of choice it is.
  decisionMaking('Decision making'),

  /// Framing, decomposing and attacking a problem.
  problemSolving('Problem solving'),

  /// Saying a thing so it lands.
  communication('Communication');

  const ToolCategory(this.label);

  /// Human-readable name, shown in the category filter.
  final String label;
}

/// One thinking tool: what it is, who devised it, and how it is worked through.
///
/// Subclasses add the pattern-specific structure. The base holds only what
/// every tool needs for browsing, routing and export.
sealed class ToolConfig {
  /// Creates a tool config.
  const ToolConfig({
    required this.id,
    required this.name,
    required this.blurb,
    required this.attribution,
    required this.primary,
    required this.tags,
    required this.related,
  });

  /// Stable slug, e.g. `inversion`. Used as the storage key linking a
  /// [ToolConfig] to saved sessions, so it must never change once shipped.
  final String id;

  /// Display name.
  final String name;

  /// One or two sentences on what the tool is for. Written fresh for this app.
  final String blurb;

  /// Who devised the method, e.g. `Kaoru Ishikawa`.
  ///
  /// Required on the base class, and therefore enforced by the compiler: the
  /// frameworks here are long-standing public methods, but the phrasing on any
  /// particular website is not, so this app credits the original author and
  /// writes its own prose. A tool cannot be added without naming a source.
  final String attribution;

  /// The single category this tool is filed under.
  final ToolCategory primary;

  /// Free-form tags for cross-cutting concerns, e.g. `prioritisation`.
  final List<String> tags;

  /// Ids of tools worth reaching for next. Validated by the registry test.
  final List<String> related;
}

/// A tool worked through as an ordered sequence of prompts.
///
/// Answers persist between steps, so a later step can quote an earlier one.
final class WizardConfig extends ToolConfig {
  /// Creates a wizard tool.
  const WizardConfig({
    required this.steps,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
  });

  /// The prompts, in order.
  final List<WizardStep> steps;
}

/// A tool that sorts items into the four quadrants of a 2x2 grid.
final class MatrixConfig extends ToolConfig {
  /// Creates a 2x2 matrix tool.
  const MatrixConfig({
    required this.xAxis,
    required this.yAxis,
    required this.quadrants,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
  });

  /// Horizontal axis, low end first.
  final AxisSpec xAxis;

  /// Vertical axis, low end first.
  final AxisSpec yAxis;

  /// The four quadrants. Order is defined by [QuadrantSpec.corner].
  final List<QuadrantSpec> quadrants;
}

/// A tool worked through as a tree of nested nodes.
final class TreeConfig extends ToolConfig {
  /// Creates a tree tool.
  const TreeConfig({
    required this.modes,
    required this.rootPrompt,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
    this.meceCheck = false,
  });

  /// Selectable modes, each relabelling the "add child" action — e.g. Issue
  /// trees switch between asking "why?" (a problem tree) and "how?" (a
  /// solution tree). A single-entry list means no mode switcher is shown.
  final List<TreeMode> modes;

  /// Prompt shown on the root node.
  final String rootPrompt;

  /// Whether to offer a per-level "mutually exclusive, collectively
  /// exhaustive" check.
  final bool meceCheck;
}

/// A tool drawn as nodes joined by directed edges.
final class GraphConfig extends ToolConfig {
  /// Creates a graph tool.
  const GraphConfig({
    required this.variant,
    required this.seeds,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
  });

  /// Which layout and editing rules apply.
  final GraphVariant variant;

  /// Nodes present when a session starts — the fishbone's default ribs, the
  /// conflict cloud's five fixed slots. Empty for free-form graphs.
  final List<SeedNode> seeds;
}

/// A tool drawn as a closed cycle of phases.
final class LoopConfig extends ToolConfig {
  /// Creates a loop tool.
  const LoopConfig({
    required this.phases,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
    this.growable = false,
  });

  /// The phases, in cycle order. The last one feeds back into the first.
  final List<LoopPhase> phases;

  /// Whether the user may add their own phases (feedback loops) or the set is
  /// fixed by the method (OODA).
  final bool growable;
}

/// A tool worked through as an ordered stack of levels.
final class LadderConfig extends ToolConfig {
  /// Creates a ladder tool.
  ///
  /// Exactly one of [fixedRungs] or [grow] describes the ladder: a fixed set
  /// of named levels (the Iceberg's four, the Ladder of inference's seven), or
  /// a seed rung the user extends in one or both directions (Abstraction
  /// laddering).
  const LadderConfig({
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
    this.fixedRungs,
    this.grow,
    this.waterlineAfter,
  });

  /// The named levels, top first. Null for a growable ladder.
  final List<RungSpec>? fixedRungs;

  /// How the user extends a growable ladder. Null for a fixed one.
  final GrowSpec? grow;

  /// Index after which to draw a dividing line — the Iceberg's waterline,
  /// separating what is observable from what explains it.
  final int? waterlineAfter;
}

/// A tool worked through as a set of named perspectives.
final class LensConfig extends ToolConfig {
  /// Creates a lens tool.
  const LensConfig({
    required this.lenses,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
    this.classifier,
  });

  /// The perspectives, in suggested order.
  final List<LensCard> lenses;

  /// Optional question sequence that lands the user on one lens instead of
  /// leaving them to pick — Cynefin's domain sorter.
  final ClassifierSpec? classifier;
}

/// A tool worked through as a grid of options and factors.
final class ScoredGridConfig extends ToolConfig {
  /// Creates a grid tool.
  const ScoredGridConfig({
    required this.mode,
    required this.rowNoun,
    required this.columnNoun,
    required super.id,
    required super.name,
    required super.blurb,
    required super.attribution,
    required super.primary,
    required super.tags,
    required super.related,
  });

  /// Whether the grid scores options against weighted factors, or combines one
  /// value per column into candidate solutions.
  final GridMode mode;

  /// What a row is called, e.g. `Option`.
  final String rowNoun;

  /// What a column is called, e.g. `Factor`.
  final String columnNoun;
}
