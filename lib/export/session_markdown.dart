/// Renders a finished session as Markdown.
///
/// One file with a single exhaustive `switch`, rather than a `toMarkdown()`
/// on each config subclass. Two reasons: the attribution line is a hard
/// requirement on every export, and a single site is the only place that can
/// be guaranteed not to drift as tools are added; and the `switch` over a
/// sealed type means a new pattern fails to compile here until it is handled.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/grid/scoring.dart';
import 'package:untools/patterns/ladder/ladder_view.dart';

/// Renders [session] of [tool] as a Markdown document.
String sessionToMarkdown(Session session, ToolConfig tool, {DateTime? now}) {
  final buffer = StringBuffer()
    ..writeln('# ${session.title.isEmpty ? tool.name : session.title}')
    ..writeln()
    ..writeln('_${tool.name} — ${tool.attribution}_')
    ..writeln()
    ..writeln(tool.blurb)
    ..writeln();

  _writeBody(buffer, session, tool);

  final stamp = (now ?? DateTime.now()).toUtc().toIso8601String().split('T')[0];
  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('Exported $stamp · untools');
  return buffer.toString();
}

void _writeBody(StringBuffer buffer, Session session, ToolConfig tool) {
  switch (tool) {
    case WizardConfig(:final steps):
      for (final step in steps) {
        buffer
          ..writeln('## ${step.title}')
          ..writeln()
          ..writeln(_answerOr(session.text(step.slotId)))
          ..writeln();
        for (final sub in step.subfields) {
          buffer
            ..writeln('### ${sub.title}')
            ..writeln()
            ..writeln(_answerOr(session.text(sub.slotId)))
            ..writeln();
        }
      }

    case MatrixConfig(:final quadrants):
      for (final quadrant in quadrants) {
        buffer
          ..writeln('## ${quadrant.name}')
          ..writeln()
          ..writeln('_${quadrant.action}_')
          ..writeln();
        _writeBullets(buffer, session.records(quadrant.slotId), 'label');
        buffer.writeln();
      }

    case LadderConfig(:final fixedRungs):
      for (final rung in fixedRungs ?? const <RungSpec>[]) {
        buffer
          ..writeln('## ${rung.name}')
          ..writeln()
          ..writeln(_answerOr(session.text(rung.slotId)))
          ..writeln();
      }
      // A growable ladder has no named levels, so its rungs export as an
      // ordered list, top (most abstract) first.
      final rungs = session.records(kLadderRungsSlot);
      if (rungs.isNotEmpty) {
        buffer
          ..writeln('## Rungs, broadest first')
          ..writeln();
        _writeBullets(buffer, rungs, 'label');
        buffer.writeln();
      }

    case LensConfig(:final lenses):
      for (final lens in lenses) {
        buffer
          ..writeln('## ${lens.name}')
          ..writeln()
          ..writeln(_answerOr(session.text(lens.slotId)))
          ..writeln();
      }

    case LoopConfig(:final phases):
      var index = 1;
      for (final phase in phases) {
        buffer.writeln(
          '${index++}. **${phase.name}** — '
          '${_answerOr(session.text(phase.slotId))}',
        );
      }
      buffer
        ..writeln()
        ..writeln('_…and back to ${phases.first.name}._')
        ..writeln();

    case TreeConfig():
      _writeTree(buffer, session.records('nodes'));

    case GraphConfig():
      buffer
        ..writeln('## Elements')
        ..writeln();
      _writeBullets(buffer, session.records('nodes'), 'label');
      buffer
        ..writeln()
        ..writeln('## Links')
        ..writeln();
      final nodes = {
        for (final node in session.records('nodes'))
          node['id'] as String? ?? '': node['label'] as String? ?? '',
      };
      for (final edge in session.records('edges')) {
        final from = nodes[edge['from']] ?? '?';
        final to = nodes[edge['to']] ?? '?';
        final label = edge['label'] as String? ?? edge['sign'] as String? ?? '';
        buffer.writeln('- $from --($label)--> $to');
      }
      buffer.writeln();

    case ScoredGridConfig(:final mode, :final rowNoun, :final columnNoun):
      _writeGrid(buffer, session, mode, rowNoun, columnNoun);
  }
}

void _writeGrid(
  StringBuffer buffer,
  Session session,
  GridMode mode,
  String rowNoun,
  String columnNoun,
) {
  final factors = [
    for (final record in session.records('factors'))
      GridFactor(
        id: record['id'] as String? ?? '',
        name: record['name'] as String? ?? '',
        weight: record['weight'] as int? ?? 1,
      ),
  ];
  final options = [
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

  if (mode == GridMode.combination) {
    buffer
      ..writeln('## $columnNoun values')
      ..writeln();
    for (final factor in factors) {
      buffer.writeln('- **${factor.name}**');
    }
    buffer.writeln();
    return;
  }

  final results = scoreGrid(options, factors);
  final winner = winnerOf(results);
  final totals = {for (final r in results) r.optionId: r.total};

  buffer
    ..writeln(
      '| $rowNoun | '
      '${factors.map((f) => '${f.name} (x${f.weight})').join(' | ')} '
      '| Total |',
    )
    ..writeln('| --- |${' --- |' * (factors.length + 1)}');
  for (final option in options) {
    final cells = factors.map((f) => '${option.scores[f.id] ?? 0}').join(' | ');
    final total = totals[option.id] ?? 0;
    final isWinner = option.id == winner;
    final name = isWinner ? '**${option.name}**' : option.name;
    final shown = isWinner ? '**$total**' : '$total';
    buffer.writeln('| $name | $cells | $shown |');
  }
  buffer.writeln();
  if (winner == null && results.length > 1) {
    buffer
      ..writeln(
        '_No clear winner — the top options tie. Add a factor or '
        'change a weight rather than picking arbitrarily._',
      )
      ..writeln();
  }
}

void _writeTree(StringBuffer buffer, List<Map<String, Object?>> nodes) {
  for (final node in nodes) {
    final depth = node['depth'] as int? ?? 0;
    final label = node['label'] as String? ?? '';
    buffer.writeln('${'  ' * depth}- $label');
  }
  buffer.writeln();
}

void _writeBullets(
  StringBuffer buffer,
  List<Map<String, Object?>> records,
  String key,
) {
  if (records.isEmpty) {
    buffer.writeln('_(nothing here)_');
    return;
  }
  for (final record in records) {
    buffer.writeln('- ${record[key] as String? ?? ''}');
  }
}

String _answerOr(String value) => value.isEmpty ? '_(not answered)_' : value;
