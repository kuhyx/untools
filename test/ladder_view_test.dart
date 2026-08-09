import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/ladder/ladder_view.dart';
import 'package:untools/tools/decision/ladder_of_inference.dart';
import 'package:untools/tools/problem/abstraction_laddering.dart';
import 'package:untools/tools/systems/iceberg_model.dart';

Future<Session Function()> pumpLadder(
  WidgetTester tester,
  LadderConfig config, {
  Map<String, Object?> slots = const {},
  Size size = const Size(1366, 768),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final now = DateTime(2026, 8, 9, 12);
  var current = Session(
    id: 's1',
    toolId: config.id,
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => LadderView(
            session: current,
            config: config,
            onChanged: (updated) => setState(() => current = updated),
          ),
        ),
      ),
    ),
  );
  return () => current;
}

void main() {
  group('fixed ladder', () {
    testWidgets('shows every named level', (tester) async {
      await pumpLadder(tester, icebergModel);

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Patterns'), findsOneWidget);
      expect(find.text('Structures'), findsOneWidget);
      expect(find.text('Mental models'), findsOneWidget);
    });

    testWidgets('draws the waterline where the config says', (tester) async {
      // Drawn rather than described: the point of the Iceberg is that the
      // levels below are the ones nobody looks at.
      await pumpLadder(tester, icebergModel);

      expect(find.text('below the surface'), findsOneWidget);
    });

    testWidgets('omits the waterline when unset', (tester) async {
      await pumpLadder(tester, ladderOfInference);

      expect(find.text('below the surface'), findsNothing);
    });

    testWidgets('stores an answer under its own slot', (tester) async {
      final session = await pumpLadder(tester, icebergModel);

      await tester.enterText(find.byType(TextField).first, 'the outage');
      await tester.pumpAndSettle();

      expect(session().text('events'), 'the outage');
    });

    testWidgets('shows stored answers when reopened', (tester) async {
      await pumpLadder(
        tester,
        icebergModel,
        slots: {'mental-models': 'shipping fast is what we reward'},
      );

      expect(find.text('shipping fast is what we reward'), findsOneWidget);
    });

    testWidgets('offers no way to add or remove a level', (tester) async {
      // The fixed set is the method: being made to answer the level you would
      // have skipped is where the value is.
      await pumpLadder(tester, ladderOfInference);

      expect(find.byTooltip('Remove rung'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('runs conclusion-first, so Actions sits above the raw data', (
      tester,
    ) async {
      // The climb up happens in a second and feels like observation; the walk
      // back down is the work. So the conclusion you already reached is at the
      // top, where you start — asserted by screen position, since the lower
      // rungs are below the fold and absent from the widget list entirely.
      await pumpLadder(tester, ladderOfInference);

      final actions = tester.getTopLeft(find.text('Actions')).dy;
      final beliefs = tester.getTopLeft(find.text('Beliefs')).dy;
      expect(actions, lessThan(beliefs));
    });
  });

  group('growable ladder', () {
    testWidgets('starts with a single seed rung', (tester) async {
      await pumpLadder(tester, abstractionLaddering);

      expect(find.text('Your starting point'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('adds a broader rung above', (tester) async {
      final session = await pumpLadder(tester, abstractionLaddering);

      await tester.tap(find.textContaining('Why does that matter?'));
      await tester.pumpAndSettle();

      expect(session().records(kLadderRungsSlot), hasLength(2));
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('adds a more concrete rung below', (tester) async {
      final session = await pumpLadder(tester, abstractionLaddering);

      await tester.tap(find.textContaining('How would you do it?'));
      await tester.pumpAndSettle();

      expect(session().records(kLadderRungsSlot), hasLength(2));
    });

    testWidgets('a rung above is prompted to be broader', (tester) async {
      await pumpLadder(tester, abstractionLaddering);

      await tester.tap(find.textContaining('Why does that matter?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('A broader statement'), findsOneWidget);
    });

    testWidgets('a rung below is prompted to be more concrete', (tester) async {
      await pumpLadder(tester, abstractionLaddering);

      await tester.tap(find.textContaining('How would you do it?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('A more concrete statement'), findsOneWidget);
    });

    testWidgets('stores what is typed into a rung', (tester) async {
      final session = await pumpLadder(tester, abstractionLaddering);

      await tester.enterText(
        find.byType(TextField).first,
        'Design a better can opener',
      );
      await tester.pumpAndSettle();

      final rungs = session().records(kLadderRungsSlot);
      expect(rungs.single['label'], 'Design a better can opener');
    });

    testWidgets('an added rung can be removed', (tester) async {
      final session = await pumpLadder(tester, abstractionLaddering);
      await tester.tap(find.textContaining('Why does that matter?'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove rung').first);
      await tester.pumpAndSettle();

      expect(session().records(kLadderRungsSlot), hasLength(1));
    });

    testWidgets('the seed rung cannot be removed', (tester) async {
      // Removing the starting point would lose the "how far have I moved"
      // reference that makes the ladder worth drawing.
      await pumpLadder(tester, abstractionLaddering);

      expect(find.byTooltip('Remove rung'), findsNothing);
    });

    testWidgets('is usable at 1024x600 without overflowing', (tester) async {
      await pumpLadder(
        tester,
        ladderOfInference,
        size: const Size(1024, 600),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
