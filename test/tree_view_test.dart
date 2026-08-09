import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/tree/tree_model.dart';
import 'package:untools/patterns/tree/tree_view.dart';
import 'package:untools/tools/decision/second_order_thinking.dart';
import 'package:untools/tools/problem/issue_trees.dart';

Future<Session Function()> pumpTree(
  WidgetTester tester,
  TreeConfig config, {
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
          builder: (context, setState) => TreeView(
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

List<TreeNode> nodesOf(Session session) =>
    nodesFromRecords(session.records(kTreeNodesSlot));

void main() {
  testWidgets('starts with a single root prompted by the tool', (tester) async {
    await pumpTree(tester, issueTrees);

    expect(
      find.text('State the problem you are breaking down.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('typing in the root stores it', (tester) async {
    final session = await pumpTree(tester, issueTrees);

    await tester.enterText(find.byType(TextField), 'Sign-ups are falling');
    await tester.pumpAndSettle();

    expect(nodesOf(session()).single.label, 'Sign-ups are falling');
  });

  testWidgets('adding a child grows the tree', (tester) async {
    final session = await pumpTree(tester, issueTrees);

    await tester.tap(find.text('Why does this happen?').first);
    await tester.pumpAndSettle();

    expect(nodesOf(session()), hasLength(2));
    expect(nodesOf(session()).last.parentId, 'root');
  });

  testWidgets('a child is indented one level', (tester) async {
    // Indentation is the whole visual language of this pattern.
    await pumpTree(
      tester,
      issueTrees,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'c', 'label': 'Child', 'parentId': 'root'},
        ],
      },
    );

    final rootX = tester.getTopLeft(find.text('Root')).dx;
    final childX = tester.getTopLeft(find.text('Child')).dx;
    expect(childX, greaterThan(rootX));
  });

  testWidgets('a branch can be removed', (tester) async {
    final session = await pumpTree(
      tester,
      issueTrees,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'c', 'label': 'Child', 'parentId': 'root'},
        ],
      },
    );

    await tester.tap(find.byTooltip('Remove this branch'));
    await tester.pumpAndSettle();

    expect(nodesOf(session()), hasLength(1));
  });

  testWidgets('the root cannot be removed', (tester) async {
    await pumpTree(tester, issueTrees);
    expect(find.byTooltip('Remove this branch'), findsNothing);
  });

  testWidgets('switching mode relabels the add action', (tester) async {
    // One tree, two directions: why maps causes, how maps solutions.
    final session = await pumpTree(tester, issueTrees);

    await tester.tap(find.text('Solutions (how?)'));
    await tester.pumpAndSettle();

    expect(session().text(kTreeModeSlot), 'how');
    expect(find.text('How might we fix this?'), findsWidgets);
  });

  testWidgets('a single-mode tool shows no mode switcher', (tester) async {
    await pumpTree(tester, secondOrderThinking);

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('And then what?'), findsWidgets);
  });

  testWidgets('the MECE check appears only on a node with children', (
    tester,
  ) async {
    // Marking a childless node "collectively exhaustive" would be meaningless.
    await pumpTree(
      tester,
      issueTrees,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'c', 'label': 'Child', 'parentId': 'root'},
        ],
      },
    );

    expect(
      find.byTooltip('Mark as covering every case, without overlap'),
      findsOneWidget,
    );
  });

  testWidgets('the MECE check toggles and persists', (tester) async {
    final session = await pumpTree(
      tester,
      issueTrees,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'c', 'label': 'Child', 'parentId': 'root'},
        ],
      },
    );

    await tester.tap(
      find.byTooltip('Mark as covering every case, without overlap'),
    );
    await tester.pumpAndSettle();

    expect(nodesOf(session()).first.mece, isTrue);
    expect(
      find.byTooltip('Marked as covering every case, without overlap'),
      findsOneWidget,
    );
  });

  testWidgets('a tool without the MECE check never offers it', (tester) async {
    await pumpTree(
      tester,
      secondOrderThinking,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'c', 'label': 'Child', 'parentId': 'root'},
        ],
      },
    );

    expect(
      find.byTooltip('Mark as covering every case, without overlap'),
      findsNothing,
    );
  });

  testWidgets('is usable at 1024x600 without overflowing', (tester) async {
    await pumpTree(
      tester,
      issueTrees,
      slots: {
        kTreeNodesSlot: [
          {'id': 'root', 'label': 'Root'},
          {'id': 'a', 'label': 'A', 'parentId': 'root'},
          {'id': 'a1', 'label': 'A1', 'parentId': 'a'},
        ],
      },
      size: const Size(1024, 600),
    );

    expect(tester.takeException(), isNull);
  });
}
