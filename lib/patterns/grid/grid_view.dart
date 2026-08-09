/// Pattern H — options scored against weighted factors.
///
/// The arithmetic lives in `scoring.dart` as plain Dart; this file only
/// renders it and collects edits.
library;

import 'package:flutter/material.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/grid/scoring.dart';
import 'package:untools/ui/theme.dart';
import 'package:uuid/uuid.dart';

/// Renders the grid, recomputing totals as scores change.
class ScoredGridView extends StatelessWidget {
  /// Creates the grid view.
  const ScoredGridView({
    required this.session,
    required this.config,
    required this.onChanged,
    super.key,
  });

  /// The session being edited.
  final Session session;

  /// The tool's grid definition.
  final ScoredGridConfig config;

  /// Called with the updated session whenever a cell changes.
  final ValueChanged<Session> onChanged;

  List<GridFactor> get _factors => [
    for (final record in session.records('factors'))
      GridFactor(
        id: record['id'] as String? ?? '',
        name: record['name'] as String? ?? '',
        weight: record['weight'] as int? ?? 1,
      ),
  ];

  List<GridOption> get _options => [
    for (final record in session.records('options'))
      GridOption(
        id: record['id'] as String? ?? '',
        name: record['name'] as String? ?? '',
        scores: {
          for (final entry
              in (record['scores'] as Map<String, Object?>? ?? const {})
                  .entries)
            entry.key: entry.value as int? ?? 0,
        },
      ),
  ];

  void _addFactor(String name) {
    if (name.trim().isEmpty) return;
    onChanged(
      session.withSlot('factors', [
        ...session.records('factors'),
        {'id': const Uuid().v4(), 'name': name.trim(), 'weight': 1},
      ]),
    );
  }

  void _addOption(String name) {
    if (name.trim().isEmpty) return;
    onChanged(
      session.withSlot('options', [
        ...session.records('options'),
        {
          'id': const Uuid().v4(),
          'name': name.trim(),
          'scores': <String, Object?>{},
        },
      ]),
    );
  }

  void _setWeight(String factorId, int weight) {
    onChanged(
      session.withSlot('factors', [
        for (final record in session.records('factors'))
          if (record['id'] == factorId)
            {...record, 'weight': weight}
          else
            record,
      ]),
    );
  }

  void _setScore(String optionId, String factorId, int score) {
    onChanged(
      session.withSlot('options', [
        for (final record in session.records('options'))
          if (record['id'] == optionId)
            {
              ...record,
              'scores': {
                ...(record['scores'] as Map<String, Object?>? ?? const {}),
                factorId: score,
              },
            }
          else
            record,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factors = _factors;
    final options = _options;
    final results = scoreGrid(options, factors);
    final winner = winnerOf(results);
    final totals = {for (final r in results) r.optionId: r.total};

    return ListView(
      children: [
        _AddField(
          label: 'Add a ${config.columnNoun.toLowerCase()}',
          onSubmit: _addFactor,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AddField(
          label: 'Add an ${config.rowNoun.toLowerCase()}',
          onSubmit: _addOption,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (factors.isEmpty || options.isEmpty)
          Text(
            'Add at least one ${config.rowNoun.toLowerCase()} and one '
            '${config.columnNoun.toLowerCase()} to start scoring.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final factor in factors)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text('${factor.name} — how much it counts')),
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Lower weight',
                  onPressed: factor.weight <= 1
                      ? null
                      : () => _setWeight(factor.id, factor.weight - 1),
                ),
                Text('x${factor.weight}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Raise weight',
                  onPressed: () => _setWeight(factor.id, factor.weight + 1),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        for (final option in options)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${totals[option.id] ?? 0}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: option.id == winner
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  for (final factor in factors)
                    Row(
                      children: [
                        Expanded(child: Text(factor.name)),
                        for (var score = 1; score <= 5; score++)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Score ${factor.name} $score',
                            icon: Icon(
                              (option.scores[factor.id] ?? 0) >= score
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            onPressed: () =>
                                _setScore(option.id, factor.id, score),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (winner == null && results.length > 1)
          Text(
            'No clear winner — the top options tie. Add a factor or change a '
            'weight rather than picking arbitrarily.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _AddField extends StatefulWidget {
  const _AddField({required this.label, required this.onSubmit});

  final String label;
  final ValueChanged<String> onSubmit;

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          tooltip: widget.label,
          onPressed: _submit,
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
