/// Weighted scoring and combination generation for the grid pattern.
///
/// Pure Dart, no Flutter import: this is the arithmetic the app does *for* the
/// user, so it is the part most worth testing exhaustively.
library;

/// One column of a scored grid: a factor and how much it counts.
class GridFactor {
  /// Creates a factor.
  const GridFactor({required this.id, required this.name, this.weight = 1});

  /// Stable id, referenced by [GridOption.scores].
  final String id;

  /// What the factor is called.
  final String name;

  /// How much this factor counts relative to the others.
  final int weight;
}

/// One row of a scored grid: an option and its per-factor scores.
class GridOption {
  /// Creates an option.
  const GridOption({
    required this.id,
    required this.name,
    this.scores = const {},
  });

  /// Stable id.
  final String id;

  /// What the option is called.
  final String name;

  /// Score per [GridFactor.id]. A missing factor counts as zero.
  final Map<String, int> scores;
}

/// An option's computed total.
class GridResult {
  /// Creates a result.
  const GridResult({required this.optionId, required this.total});

  /// Which option this is the total for.
  final String optionId;

  /// Sum of `score * weight` across every factor.
  final int total;
}

/// Scores every option against every factor.
///
/// Returned in descending total order, so the first entry is the leader. Ties
/// are preserved rather than broken arbitrarily — see [winnerOf], which
/// declines to pick a winner when the top two are level.
List<GridResult> scoreGrid(List<GridOption> options, List<GridFactor> factors) {
  final results = [
    for (final option in options)
      GridResult(optionId: option.id, total: _totalFor(option, factors)),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return results;
}

int _totalFor(GridOption option, List<GridFactor> factors) {
  var total = 0;
  for (final factor in factors) {
    total += (option.scores[factor.id] ?? 0) * factor.weight;
  }
  return total;
}

/// The single highest-scoring option, or null when there is no clear winner.
///
/// Null on an empty grid, and null on a tie: a tie is a real and useful
/// result — it means the factors as weighted do not separate the options, and
/// the honest response is to add a factor or change a weight, not to let the
/// tool pick whichever happened to be entered first.
String? winnerOf(List<GridResult> results) {
  if (results.isEmpty) return null;
  if (results.length > 1 && results[0].total == results[1].total) return null;
  return results.first.optionId;
}

/// Composes one candidate by taking [selection]'s value from each column.
///
/// Used by the combination grid, where columns are independent attributes and
/// a solution is one value per column. Columns with no selection are skipped.
List<String> composeCombination(
  List<GridFactor> columns,
  Map<String, String> selection,
) {
  return [
    for (final column in columns) ?selection[column.id],
  ];
}
