import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/wizard/wizard_view.dart';

/// A wizard with a nested subfield, of the shape the Productive Thinking
/// Model's DRIVE checklist will use when it lands.
const _nested = WizardConfig(
  id: 'nested',
  name: 'Nested',
  blurb: 'b',
  attribution: 'a',
  primary: ToolCategory.problemSolving,
  tags: [],
  related: [],
  steps: [
    WizardStep(
      slotId: 'parent',
      title: 'Define success',
      prompt: 'What does done look like?',
      subfields: [
        WizardStep(
          slotId: 'child',
          title: 'Restrictions',
          prompt: 'What must not happen?',
          multiline: false,
        ),
      ],
    ),
  ],
);

Future<Session Function()> pumpWizard(
  WidgetTester tester,
  WizardConfig config, {
  Map<String, Object?> slots = const {},
}) async {
  tester.view
    ..physicalSize = const Size(1366, 768)
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
          builder: (context, setState) => WizardView(
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
  testWidgets('shows a nested subfield under its parent step', (tester) async {
    await pumpWizard(tester, _nested);

    expect(find.text('Define success'), findsOneWidget);
    expect(find.text('Restrictions'), findsOneWidget);
  });

  testWidgets('a subfield answer is stored under its own slot', (
    tester,
  ) async {
    // Slot-id keying is what lets a subfield be added, moved or renamed
    // without disturbing any answer already saved.
    final session = await pumpWizard(tester, _nested);

    await tester.enterText(find.byType(TextField).last, 'No downtime');
    await tester.pumpAndSettle();

    expect(session().text('child'), 'No downtime');
  });

  testWidgets('shows a stored answer when the session is reopened', (
    tester,
  ) async {
    await pumpWizard(tester, _nested, slots: {'parent': 'Shipped and quiet'});

    expect(find.text('Shipped and quiet'), findsOneWidget);
  });

  testWidgets('every step is visible at once rather than behind a Next', (
    tester,
  ) async {
    // These methods work by letting a later answer send you back to revise an
    // earlier one; a stepper that hides earlier answers fights that.
    await pumpWizard(tester, _nested);

    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('a single-line step is not multiline', (tester) async {
    await pumpWizard(tester, _nested);

    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.maxLines, 1);
  });
}
