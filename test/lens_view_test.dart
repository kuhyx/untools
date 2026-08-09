import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/lens/lens_view.dart';
import 'package:untools/tools/decision/cynefin_framework.dart';
import 'package:untools/tools/decision/perspective_lenses.dart';

Future<Session Function()> pumpLens(
  WidgetTester tester,
  LensConfig config, {
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
          builder: (context, setState) => LensView(
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
  group('without a classifier', () {
    testWidgets('shows every lens at once', (tester) async {
      // Visiting each frame in turn is the method; hiding them behind a
      // stepper would make it a quiz instead.
      await pumpLens(tester, perspectiveLenses);

      expect(find.text('Process'), findsOneWidget);
      expect(find.text('Facts'), findsOneWidget);
      expect(find.text('Risks'), findsOneWidget);
    });

    testWidgets('stores a note under its own lens slot', (tester) async {
      final session = await pumpLens(tester, perspectiveLenses);

      await tester.enterText(find.byType(TextField).first, 'ship or not');
      await tester.pumpAndSettle();

      expect(session().text('process'), 'ship or not');
    });

    testWidgets('shows stored notes when reopened', (tester) async {
      await pumpLens(
        tester,
        perspectiveLenses,
        slots: {'risks': 'nobody owns the rollback'},
      );

      expect(find.text('nobody owns the rollback'), findsOneWidget);
    });

    testWidgets('offers no reset, having nothing to reset', (tester) async {
      await pumpLens(tester, perspectiveLenses);

      expect(find.text('Answer the questions again'), findsNothing);
    });

    testWidgets('is usable at 1024x600 without overflowing', (tester) async {
      await pumpLens(
        tester,
        perspectiveLenses,
        size: const Size(1024, 600),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('with a classifier', () {
    testWidgets('asks the question before showing any lens', (tester) async {
      // Someone who could already name their domain would not need the
      // framework, so the menu is not the entry point.
      await pumpLens(tester, cynefinFramework);

      expect(find.textContaining('How well do you understand'), findsOneWidget);
      expect(find.text('Complicated'), findsNothing);
    });

    testWidgets('an answer selects exactly one lens', (tester) async {
      final session = await pumpLens(tester, cynefinFramework);

      await tester.tap(find.textContaining('needs expertise'));
      await tester.pumpAndSettle();

      expect(session().text(kSelectedLensSlot), 'complicated');
      expect(find.text('Complicated'), findsOneWidget);
      expect(find.text('Chaotic'), findsNothing);
    });

    testWidgets('offers a way out for "several of these at once"', (
      tester,
    ) async {
      // The most common honest answer; forcing a single choice would push the
      // user into the wrong domain instead of telling them to split it up.
      final session = await pumpLens(tester, cynefinFramework);

      await tester.tap(find.textContaining('Several of these at once'));
      await tester.pumpAndSettle();

      expect(session().text(kSelectedLensSlot), 'disorder');
      expect(find.text('Not sure'), findsOneWidget);
    });

    testWidgets('the selected lens takes notes like any other', (tester) async {
      final session = await pumpLens(
        tester,
        cynefinFramework,
        slots: {kSelectedLensSlot: 'complex'},
      );

      await tester.enterText(find.byType(TextField), 'try a canary release');
      await tester.pumpAndSettle();

      expect(session().text('complex'), 'try a canary release');
    });

    testWidgets('the classifier can be answered again', (tester) async {
      final session = await pumpLens(
        tester,
        cynefinFramework,
        slots: {kSelectedLensSlot: 'clear'},
      );

      await tester.tap(find.text('Answer the questions again'));
      await tester.pumpAndSettle();

      expect(session().text(kSelectedLensSlot), '');
      expect(find.textContaining('How well do you understand'), findsOneWidget);
    });

    testWidgets('re-answering keeps notes already written', (tester) async {
      // Reclassifying is a common second thought; losing what you wrote for
      // it would punish changing your mind.
      final session = await pumpLens(
        tester,
        cynefinFramework,
        slots: {kSelectedLensSlot: 'clear', 'clear': 'apply the runbook'},
      );

      await tester.tap(find.text('Answer the questions again'));
      await tester.pumpAndSettle();

      expect(session().text('clear'), 'apply the runbook');
    });
  });
}
