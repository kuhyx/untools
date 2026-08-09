import 'package:flutter_test/flutter_test.dart';
import 'package:untools/patterns/grid/scoring.dart';

void main() {
  group('scoreGrid', () {
    test('multiplies each score by its factor weight', () {
      final factors = [
        const GridFactor(id: 'cost', name: 'Cost', weight: 3),
        const GridFactor(id: 'speed', name: 'Speed', weight: 2),
      ];
      final options = [
        const GridOption(
          id: 'a',
          name: 'A',
          scores: {'cost': 4, 'speed': 1},
        ),
      ];

      final results = scoreGrid(options, factors);

      expect(results.single.total, 4 * 3 + 1 * 2);
    });

    test('treats an unscored factor as zero rather than skipping it', () {
      final factors = [
        const GridFactor(id: 'cost', name: 'Cost', weight: 5),
        const GridFactor(id: 'unrated', name: 'Unrated', weight: 10),
      ];
      final options = [
        const GridOption(id: 'a', name: 'A', scores: {'cost': 2}),
      ];

      expect(scoreGrid(options, factors).single.total, 10);
    });

    test('returns options in descending total order', () {
      final factors = [const GridFactor(id: 'f', name: 'F')];
      final options = [
        const GridOption(id: 'low', name: 'Low', scores: {'f': 1}),
        const GridOption(id: 'high', name: 'High', scores: {'f': 9}),
        const GridOption(id: 'mid', name: 'Mid', scores: {'f': 5}),
      ];

      final results = scoreGrid(options, factors);

      expect([for (final r in results) r.optionId], ['high', 'mid', 'low']);
    });

    test('defaults weight to 1', () {
      final results = scoreGrid(
        [
          const GridOption(id: 'a', name: 'A', scores: {'f': 7}),
        ],
        [const GridFactor(id: 'f', name: 'F')],
      );
      expect(results.single.total, 7);
    });

    test('is empty for no options', () {
      expect(scoreGrid([], [const GridFactor(id: 'f', name: 'F')]), isEmpty);
    });
  });

  group('winnerOf', () {
    test('picks the single highest scorer', () {
      final results = scoreGrid(
        [
          const GridOption(id: 'a', name: 'A', scores: {'f': 1}),
          const GridOption(id: 'b', name: 'B', scores: {'f': 2}),
        ],
        [const GridFactor(id: 'f', name: 'F')],
      );

      expect(winnerOf(results), 'b');
    });

    test('declines to pick when the top two tie', () {
      // A tie is a real result: the factors as weighted do not separate the
      // options, so the tool must not invent a winner from list order.
      final results = scoreGrid(
        [
          const GridOption(id: 'a', name: 'A', scores: {'f': 3}),
          const GridOption(id: 'b', name: 'B', scores: {'f': 3}),
        ],
        [const GridFactor(id: 'f', name: 'F')],
      );

      expect(winnerOf(results), isNull);
    });

    test('picks a single option even though it cannot be compared', () {
      final results = scoreGrid(
        [
          const GridOption(id: 'only', name: 'Only', scores: {'f': 1}),
        ],
        [const GridFactor(id: 'f', name: 'F')],
      );

      expect(winnerOf(results), 'only');
    });

    test('is null for an empty grid', () {
      expect(winnerOf([]), isNull);
    });
  });

  group('composeCombination', () {
    test('takes one value per column, in column order', () {
      final columns = [
        const GridFactor(id: 'when', name: 'Timing'),
        const GridFactor(id: 'how', name: 'Format'),
      ];

      final combination = composeCombination(columns, {
        'when': 'Weekly',
        'how': 'Written',
      });

      expect(combination, ['Weekly', 'Written']);
    });

    test('skips columns with nothing selected', () {
      final columns = [
        const GridFactor(id: 'when', name: 'Timing'),
        const GridFactor(id: 'how', name: 'Format'),
      ];

      expect(composeCombination(columns, {'how': 'Written'}), ['Written']);
    });
  });
}
