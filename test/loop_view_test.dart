import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/loop/loop_model.dart';
import 'package:untools/patterns/loop/loop_view.dart';
import 'package:untools/tools/decision/ooda_loop.dart';
import 'package:untools/tools/systems/balancing_loop.dart';
import 'package:untools/tools/systems/reinforcing_loop.dart';

Future<ValueNotifier<Session>> pumpLoop(
  WidgetTester tester,
  LoopConfig tool, {
  Map<String, Object?> slots = const {},
  Size size = const Size(1366, 768),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final now = DateTime(2026, 8, 9, 12);
  final current = ValueNotifier(
    Session(
      id: 's1',
      toolId: tool.id,
      title: 'A session',
      createdAt: now,
      updatedAt: now,
      slots: slots,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<Session>(
          valueListenable: current,
          builder: (context, session, _) => LoopView(
            session: session,
            config: tool,
            onChanged: (updated) => current.value = updated,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(current.dispose);
  return current;
}

void main() {
  group('the cycle', () {
    testWidgets('numbers the phases in order', (tester) async {
      await pumpLoop(tester, oodaLoop);

      expect(find.text('1.'), findsOne);
      expect(find.text('Observe'), findsOne);
      expect(find.text('4.'), findsOne);
      expect(find.text('Act'), findsOne);
    });

    testWidgets('closes the cycle by naming the first phase again', (
      tester,
    ) async {
      await pumpLoop(tester, oodaLoop);

      expect(find.text('…and back to Observe.'), findsOne);
    });

    testWidgets('starts on pass 1', (tester) async {
      await pumpLoop(tester, oodaLoop);

      expect(find.text('Pass 1'), findsOne);
    });

    testWidgets('going round again advances the pass', (tester) async {
      final current = await pumpLoop(tester, oodaLoop);

      await tester.tap(find.text('Go round again'));
      await tester.pumpAndSettle();

      expect(find.text('Pass 2'), findsOne);
      expect(current.value.slots[kLoopIterationSlot], 2);
    });

    testWidgets('shows a stored pass', (tester) async {
      await pumpLoop(tester, oodaLoop, slots: const {kLoopIterationSlot: 3});

      expect(find.text('Pass 3'), findsOne);
    });
  });

  group('answers', () {
    testWidgets('writes an answer against its phase slot', (tester) async {
      final current = await pumpLoop(tester, oodaLoop);

      await tester.enterText(find.byType(TextField).first, 'Two alerts fired');
      await tester.pumpAndSettle();

      expect(current.value.text('observe'), 'Two alerts fired');
    });

    testWidgets('shows a stored answer back', (tester) async {
      await pumpLoop(
        tester,
        oodaLoop,
        slots: const {'observe': 'Latency doubled'},
      );

      expect(find.text('Latency doubled'), findsOne);
    });

    testWidgets('shows each phase prompt', (tester) async {
      await pumpLoop(tester, oodaLoop);

      final prompts = [
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField, skipOffstage: false),
        ))
          field.decoration?.helperText,
      ];

      expect(
        prompts,
        contains('What is actually happening? Raw signals, not conclusions.'),
      );
    });
  });

  group('a fixed loop', () {
    testWidgets('offers no way to add or rename a phase', (tester) async {
      // Boyd's loop is not a template to customise.
      await pumpLoop(tester, oodaLoop);

      expect(find.text('Add a stage'), findsNothing);
      expect(find.byTooltip('Remove stage'), findsNothing);
      expect(find.widgetWithText(TextField, 'Stage'), findsNothing);
    });
  });

  group('a growable loop', () {
    testWidgets('can add a stage', (tester) async {
      final current = await pumpLoop(tester, reinforcingLoop);

      await tester.tap(find.text('Add a stage'));
      await tester.pumpAndSettle();

      expect(current.value.records(kLoopPhasesSlot), hasLength(4));
    });

    testWidgets('can rename a stage', (tester) async {
      final current = await pumpLoop(tester, reinforcingLoop);

      await tester.enterText(
        find.widgetWithText(TextField, 'Stage').first,
        'More users',
      );
      await tester.pumpAndSettle();

      expect(
        current.value.records(kLoopPhasesSlot).first['name'],
        'More users',
      );
    });

    testWidgets('can remove a stage', (tester) async {
      final current = await pumpLoop(tester, balancingLoop);

      await tester.tap(find.byTooltip('Remove stage').first);
      await tester.pumpAndSettle();

      expect(current.value.records(kLoopPhasesSlot), hasLength(3));
    });

    testWidgets('will not shrink below two stages', (tester) async {
      // A one-phase "cycle" is not a cycle.
      await pumpLoop(
        tester,
        reinforcingLoop,
        slots: {
          kLoopPhasesSlot: phasesToRecords(
            reinforcingLoop.phases.take(2).toList(),
          ),
        },
      );

      expect(find.byTooltip('Remove stage'), findsNothing);
    });

    testWidgets('a renamed first stage closes the cycle by its new name', (
      tester,
    ) async {
      await pumpLoop(
        tester,
        reinforcingLoop,
        slots: {
          kLoopPhasesSlot: phasesToRecords([
            const LoopPhase(slotId: 'phase-1', name: 'Signups', prompt: 'p'),
            ...reinforcingLoop.phases.skip(1),
          ]),
        },
      );

      expect(find.text('…and back to Signups.'), findsOne);
    });

    testWidgets('an unnamed first stage still reads as a sentence', (
      tester,
    ) async {
      await pumpLoop(
        tester,
        reinforcingLoop,
        slots: {
          kLoopPhasesSlot: phasesToRecords([
            const LoopPhase(slotId: 'phase-1', name: '', prompt: 'p'),
            ...reinforcingLoop.phases.skip(1),
          ]),
        },
      );

      expect(find.text('…and back to the first stage.'), findsOne);
    });
  });

  testWidgets('is usable at 1024x600 without overflowing', (tester) async {
    await pumpLoop(tester, balancingLoop, size: const Size(1024, 600));

    expect(tester.takeException(), isNull);
  });
}
