import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/patterns/grid/grid_view.dart';
import 'package:untools/tools/decision/decision_matrix.dart';

Session buildSession({Map<String, Object?> slots = const {}}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: decisionMatrix.id,
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

Future<Session Function()> pumpGrid(
  WidgetTester tester, {
  Map<String, Object?> slots = const {},
  Size size = const Size(1366, 768),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  var current = buildSession(slots: slots);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ScoredGridView(
            session: current,
            config: decisionMatrix,
            onChanged: (updated) => setState(() => current = updated),
          ),
        ),
      ),
    ),
  );
  return () => current;
}

Map<String, Object?> gridSlots({
  int weight = 1,
  int scoreA = 1,
  int scoreB = 1,
}) => {
  'factors': [
    {'id': 'f1', 'name': 'Cost', 'weight': weight},
  ],
  'options': [
    {
      'id': 'a',
      'name': 'Option A',
      'scores': <String, Object?>{'f1': scoreA},
    },
    {
      'id': 'b',
      'name': 'Option B',
      'scores': <String, Object?>{'f1': scoreB},
    },
  ],
};

void main() {
  testWidgets('asks for a row and a column before it can score', (
    tester,
  ) async {
    await pumpGrid(tester);
    expect(find.textContaining('to start scoring'), findsOneWidget);
  });

  testWidgets('adding a factor names it as a column', (tester) async {
    final session = await pumpGrid(tester);

    await tester.enterText(find.byType(TextField).first, 'Cost');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(session().records('factors').single['name'], 'Cost');
  });

  testWidgets('adding an option names it as a row', (tester) async {
    final session = await pumpGrid(tester);

    await tester.enterText(find.byType(TextField).last, 'Option A');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(session().records('options').single['name'], 'Option A');
  });

  testWidgets('refuses to add a blank factor or option', (tester) async {
    final session = await pumpGrid(tester);

    await tester.enterText(find.byType(TextField).first, '  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.enterText(find.byType(TextField).last, '  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(session().records('factors'), isEmpty);
    expect(session().records('options'), isEmpty);
  });

  testWidgets('a new factor starts at weight 1', (tester) async {
    await pumpGrid(tester, slots: gridSlots());
    expect(find.text('x1'), findsOneWidget);
  });

  testWidgets('a factor weight can be raised', (tester) async {
    final session = await pumpGrid(tester, slots: gridSlots());

    await tester.tap(find.byTooltip('Raise weight'));
    await tester.pumpAndSettle();

    expect(session().records('factors').single['weight'], 2);
  });

  testWidgets('a factor weight can be lowered', (tester) async {
    final session = await pumpGrid(tester, slots: gridSlots(weight: 3));

    await tester.tap(find.byTooltip('Lower weight'));
    await tester.pumpAndSettle();

    expect(session().records('factors').single['weight'], 2);
  });

  testWidgets('a weight cannot go below 1', (tester) async {
    // A zero weight silently deletes a factor from the result without
    // removing it from the table, which reads as a bug.
    await pumpGrid(tester, slots: gridSlots());

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove),
        matching: find.byType(IconButton),
      ),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('scoring an option updates its total', (tester) async {
    final session = await pumpGrid(tester, slots: gridSlots(weight: 2));

    // Fifth star of the first option's only factor.
    await tester.tap(find.byTooltip('Score Cost 5').first);
    await tester.pumpAndSettle();

    final option = session().records('options').first;
    expect((option['scores']! as Map<String, Object?>)['f1'], 5);
  });

  testWidgets('shows a running total per option', (tester) async {
    await pumpGrid(tester, slots: gridSlots(weight: 2, scoreA: 3, scoreB: 1));

    expect(find.text('6'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('says so instead of inventing a winner on a tie', (
    tester,
  ) async {
    await pumpGrid(tester, slots: gridSlots(scoreA: 2, scoreB: 2));

    expect(find.textContaining('No clear winner'), findsOneWidget);
  });

  testWidgets('does not cry tie when there is a leader', (tester) async {
    await pumpGrid(tester, slots: gridSlots(scoreA: 5, scoreB: 1));

    expect(find.textContaining('No clear winner'), findsNothing);
  });

  testWidgets('scoring one option leaves the others untouched', (
    tester,
  ) async {
    final session = await pumpGrid(tester, slots: gridSlots(scoreB: 4));

    await tester.tap(find.byTooltip('Score Cost 5').first);
    await tester.pumpAndSettle();

    final other = session().records('options').last;
    expect((other['scores']! as Map<String, Object?>)['f1'], 4);
  });

  testWidgets('raising one factor weight leaves the others untouched', (
    tester,
  ) async {
    final session = await pumpGrid(
      tester,
      slots: {
        'factors': [
          {'id': 'f1', 'name': 'Cost', 'weight': 1},
          {'id': 'f2', 'name': 'Speed', 'weight': 3},
        ],
        'options': [
          {
            'id': 'a',
            'name': 'Option A',
            'scores': <String, Object?>{'f1': 1},
          },
        ],
      },
    );

    await tester.tap(find.byTooltip('Raise weight').first);
    await tester.pumpAndSettle();

    final factors = session().records('factors');
    expect(factors.first['weight'], 2);
    expect(factors.last['weight'], 3);
  });

  testWidgets('is usable at 1024x600 without overflowing', (tester) async {
    await pumpGrid(
      tester,
      slots: gridSlots(),
      size: const Size(1024, 600),
    );

    expect(tester.takeException(), isNull);
  });
}
