import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/screens/session_screen.dart';
import 'package:untools/tools/decision/decision_matrix.dart';
import 'package:untools/tools/decision/eisenhower_matrix.dart';
import 'package:untools/tools/problem/inversion.dart';

import 'fake_session_store.dart';

Session buildSession(ToolConfig tool) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: tool.id,
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: const {},
  );
}

Future<SessionRepository> pumpSession(
  WidgetTester tester,
  ToolConfig tool, {
  bool seed = true,
  Future<void> Function(String markdown, {required String filename})? share,
}) async {
  tester.view
    ..physicalSize = const Size(1366, 768)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final session = buildSession(tool);
  final repository = SessionRepository(
    FakeSessionStore(seed ? [session] : const []),
  );
  await repository.load();
  await tester.pumpWidget(
    MaterialApp(
      home: SessionScreen(
        sessionId: session.id,
        tool: tool,
        repository: repository,
        share: share ?? (markdown, {required filename}) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('dispatches a wizard tool to the wizard view', (tester) async {
    await pumpSession(tester, inversion);
    expect(find.text('Describe the worst version'), findsOneWidget);
  });

  testWidgets('dispatches a matrix tool to the matrix view', (tester) async {
    await pumpSession(tester, eisenhowerMatrix);
    expect(find.text('Handle it now.'), findsOneWidget);
  });

  testWidgets('dispatches a grid tool to the grid view', (tester) async {
    await pumpSession(tester, decisionMatrix);
    expect(find.textContaining('to start scoring'), findsOneWidget);
  });

  testWidgets('says so when the session has been deleted', (tester) async {
    // Reachable in the real app: delete a session on one screen while its
    // detail route is still on the stack.
    await pumpSession(tester, inversion, seed: false);
    expect(find.text('This session was deleted.'), findsOneWidget);
  });

  testWidgets('offers a Markdown export', (tester) async {
    await pumpSession(tester, inversion);
    expect(find.byTooltip('Export as Markdown'), findsOneWidget);
  });

  testWidgets('exporting hands over the rendered document', (tester) async {
    String? exported;
    String? name;
    await pumpSession(
      tester,
      inversion,
      share: (markdown, {required filename}) async {
        exported = markdown;
        name = filename;
      },
    );

    await tester.tap(find.byTooltip('Export as Markdown'));
    await tester.pumpAndSettle();

    expect(name, 'inversion.md');
    expect(exported, contains('# A session'));
    // The attribution is a hard requirement on every export.
    expect(exported, contains(inversion.attribution));
  });

  group('patterns landing in a later phase', () {
    // Each is dispatched explicitly rather than through a `default:` arm, so
    // the sealed switch keeps its exhaustiveness guarantee — adding a ninth
    // pattern must fail to compile here rather than silently fall through.
    const unbuilt = <ToolConfig>[
      TreeConfig(
        id: 'tree',
        name: 'Tree',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: [],
        rootPrompt: 'p',
        modes: [TreeMode(id: 'why', label: 'Why', childPrompt: 'Why?')],
      ),
      GraphConfig(
        id: 'graph',
        name: 'Graph',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        variant: GraphVariant.circle,
        seeds: [],
      ),
      LoopConfig(
        id: 'loop',
        name: 'Loop',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.decisionMaking,
        tags: [],
        related: [],
        phases: [LoopPhase(slotId: 'p', name: 'Observe', prompt: 'p')],
      ),
      LadderConfig(
        id: 'ladder',
        name: 'Ladder',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        fixedRungs: [RungSpec(slotId: 'r', name: 'Events', prompt: 'p')],
      ),
      LensConfig(
        id: 'lens',
        name: 'Lens',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.decisionMaking,
        tags: [],
        related: [],
        lenses: [LensCard(slotId: 'l', name: 'Risks', prompt: 'p')],
      ),
    ];

    for (final tool in unbuilt) {
      testWidgets('${tool.name} says it is not built yet', (tester) async {
        await pumpSession(tester, tool);
        expect(find.text('This tool is not built yet.'), findsOneWidget);
      });
    }
  });
}
