import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/app.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/tools/guide.dart';

import 'app_test.dart' show buildSession;
import 'fake_session_store.dart';

/// Pixel 6a: 1080x2400 physical at 2.625, with the real status/nav insets.
Future<void> pumpPixel(WidgetTester tester, {int sessions = 0}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.625
    ..padding = const FakeViewPadding(top: 132, bottom: 63);
  addTearDown(tester.view.reset);
  final repository = SessionRepository(
    FakeSessionStore([
      for (var i = 0; i < sessions; i++)
        buildSession(id: 's$i', title: 'Session number $i'),
    ]),
  );
  await repository.load();
  await tester.pumpWidget(UntoolsApp(repository: repository));
  await tester.pumpAndSettle();
}

void expectNoVerticalScroll(WidgetTester tester) {
  final scrollables = find.byType(Scrollable);
  for (var i = 0; i < scrollables.evaluate().length; i++) {
    final state = tester.state<ScrollableState>(scrollables.at(i));
    if (state.axisDirection == AxisDirection.down ||
        state.axisDirection == AxisDirection.up) {
      expect(state.position.maxScrollExtent, 0, reason: 'scrollable #$i');
    }
  }
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Where to start fits one screen, for every category', (
    tester,
  ) async {
    await pumpPixel(tester);
    for (final category in ToolCategory.values) {
      await tester.tap(find.widgetWithText(ChoiceChip, category.label));
      await tester.pumpAndSettle();
      expectNoVerticalScroll(tester);
      final first = guideQuestions.firstWhere(
        (q) => toolById(q.toolId)?.primary == category,
      );
      expect(find.text(first.question).hitTestable(), findsOneWidget);
    }
    expect(find.text('All tools').hitTestable(), findsOneWidget);
  });

  testWidgets('All tools fits one screen, for every category', (tester) async {
    await pumpPixel(tester);
    await openTab(tester, 'All tools');
    for (final category in ToolCategory.values) {
      await tester.tap(find.widgetWithText(ChoiceChip, category.label));
      await tester.pumpAndSettle();
      expectNoVerticalScroll(tester);
      final first = toolsInCategory(category).first;
      expect(find.text(first.name).hitTestable(), findsOneWidget);
    }
  });

  testWidgets('long-pressing a tool shows its blurb', (tester) async {
    await pumpPixel(tester);
    await openTab(tester, 'All tools');
    final tool = toolsInCategory(ToolCategory.values.first).first;
    await tester.longPress(find.text(tool.name));
    await tester.pumpAndSettle();
    expect(find.text(tool.blurb), findsOneWidget);
  });

  testWidgets('Sessions fits one screen with 40 sessions, paged', (
    tester,
  ) async {
    await pumpPixel(tester, sessions: 40);
    await openTab(tester, 'Sessions');
    expectNoVerticalScroll(tester);
    // Same updatedAt, so which session leads page one is not fixed.
    expect(find.textContaining('Session number').hitTestable(), findsWidgets);
    expect(find.byKey(const ValueKey<String>('fit-grid-dot-1')), findsOne);
  });

  testWidgets('long-pressing a session offers delete', (tester) async {
    await pumpPixel(tester, sessions: 2);
    await openTab(tester, 'Sessions');
    await tester.longPress(find.text('Session number 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();
    expect(find.text('Session number 0'), findsNothing);
    expect(find.text('Session number 1'), findsOneWidget);
  });
}
