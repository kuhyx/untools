import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/graph/graph_model.dart';
import 'package:untools/patterns/graph/graph_view.dart';
import 'package:untools/patterns/graph/layout.dart';
import 'package:untools/tools/communication/concept_map.dart';
import 'package:untools/tools/decision/conflict_resolution_diagram.dart';
import 'package:untools/tools/systems/connection_circles.dart';
import 'package:untools/tools/systems/ishikawa_diagram.dart';

Session sessionFor(GraphConfig tool, {Map<String, Object?> slots = const {}}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: tool.id,
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

/// Pumps the view and keeps the latest session the widget handed back, so a
/// test can assert on what would have been persisted.
Future<ValueNotifier<Session>> pumpGraph(
  WidgetTester tester,
  GraphConfig tool, {
  Map<String, Object?> slots = const {},
  Size size = const Size(1366, 768),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final current = ValueNotifier(sessionFor(tool, slots: slots));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<Session>(
          valueListenable: current,
          builder: (context, session, _) => GraphView(
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

Map<String, Object?> graphSlots({
  required List<GraphNode> nodes,
  List<GraphEdge> edges = const [],
}) => {
  kGraphNodesSlot: nodesToRecords(nodes),
  kGraphEdgesSlot: edgesToRecords(edges),
};

void main() {
  group('seeding', () {
    testWidgets('shows the template nodes the first time it opens', (
      tester,
    ) async {
      await pumpGraph(tester, conflictResolutionDiagram);

      expect(find.text('Shared objective'), findsWidgets);
      expect(find.text('Proposal B'), findsWidgets);
    });

    testWidgets('shows stored nodes rather than the template', (tester) async {
      await pumpGraph(
        tester,
        conflictResolutionDiagram,
        slots: graphSlots(
          nodes: const [GraphNode(id: 'objective', label: 'Ship on time')],
        ),
      );

      expect(find.text('Ship on time'), findsWidgets);
    });

    testWidgets('starts empty for a free-form graph', (tester) async {
      await pumpGraph(tester, conceptMap);

      expect(find.text('Add two elements to start linking them.'), findsOne);
    });
  });

  group('editing elements', () {
    testWidgets('adding an element writes it to the session', (tester) async {
      final current = await pumpGraph(tester, conceptMap);

      await tester.tap(find.text('Add element'));
      await tester.pumpAndSettle();

      expect(current.value.records(kGraphNodesSlot), hasLength(1));
    });

    testWidgets('typing a label writes it to the session', (tester) async {
      final current = await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [GraphNode(id: 'a', label: '')],
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Caching');
      await tester.pumpAndSettle();

      expect(
        current.value.records(kGraphNodesSlot).first['label'],
        'Caching',
      );
    });

    testWidgets('removing an element drops it from the session', (
      tester,
    ) async {
      final current = await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [GraphNode(id: 'a', label: 'Gone')],
        ),
      );

      await tester.tap(find.byTooltip('Remove element'));
      await tester.pumpAndSettle();

      expect(current.value.records(kGraphNodesSlot), isEmpty);
    });

    testWidgets('a fixed template node cannot be removed', (tester) async {
      // The cloud's five slots are the method; a sixth or a missing one would
      // make the diagram mean something else.
      await pumpGraph(tester, conflictResolutionDiagram);

      expect(find.byTooltip('Remove element'), findsNothing);
      expect(find.text('Add element'), findsNothing);
    });

    testWidgets('the fishbone rib set is fixed too', (tester) async {
      await pumpGraph(tester, ishikawaDiagram);

      expect(find.text('Add element'), findsNothing);
      expect(find.text('Measurement'), findsWidgets);
    });

    testWidgets('a seeded node shows its prompt', (tester) async {
      await pumpGraph(tester, ishikawaDiagram);

      // Asserted on the decoration rather than by finding the rendered text:
      // the seventh rib is far enough down the list that only its field is
      // built, and the prompt is what carries the method's discipline — a rib
      // with no question next to it is just a heading.
      final prompts = [
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField, skipOffstage: false),
        ))
          field.decoration?.helperText,
      ];

      expect(
        prompts,
        containsAll([
          'The problem as observed, not its suspected cause.',
          'What is measured, how, and what that makes people do.',
        ]),
      );
    });
  });

  group('links', () {
    testWidgets('says so when there are no links yet', (tester) async {
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
        ),
      );

      expect(find.text('No links yet.'), findsOne);
    });

    testWidgets('adding a link is keyboard-reachable, not a drag', (
      tester,
    ) async {
      // The composer is the whole reason nodes are not draggable: two
      // dropdowns and a button are operable without a pointer.
      final current = await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Caching'),
            GraphNode(id: 'b', label: 'Latency'),
          ],
        ),
      );

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'From'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caching').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'To'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Latency').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Relationship'),
        'reduces',
      );
      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();

      final edges = current.value.records(kGraphEdgesSlot);
      expect(edges, hasLength(1));
      expect(edges.first['label'], 'reduces');
    });

    testWidgets('the add button is disabled until both ends are chosen', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('reads a link back as a sentence', (tester) async {
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Caching'),
            GraphNode(id: 'b', label: 'Latency'),
          ],
          edges: const [
            GraphEdge(from: 'a', to: 'b', label: 'reduces'),
          ],
        ),
      );

      expect(find.text('Caching reduces Latency'), findsOne);
    });

    testWidgets('names the polarity when a link has no written label', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Bugs'),
            GraphNode(id: 'b', label: 'Rework'),
          ],
          edges: const [
            GraphEdge(from: 'a', to: 'b', sign: EdgeSign.positive),
          ],
        ),
      );

      expect(find.text('Bugs increases Rework'), findsOne);
    });

    testWidgets('reads a negative link as "decreases"', (tester) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Hiring'),
            GraphNode(id: 'b', label: 'Backlog'),
          ],
          edges: const [
            GraphEdge(from: 'a', to: 'b', sign: EdgeSign.negative),
          ],
        ),
      );

      expect(find.text('Hiring decreases Backlog'), findsOne);
    });

    testWidgets('reads an unsigned, unlabelled link as "affects"', (
      tester,
    ) async {
      // Reachable by adding a link on a free-form map without typing a
      // relationship — the row must still read as a sentence.
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Caching'),
            GraphNode(id: 'b', label: 'Latency'),
          ],
          edges: const [GraphEdge(from: 'a', to: 'b')],
        ),
      );

      expect(find.text('Caching affects Latency'), findsOne);
    });

    testWidgets('choosing "Decreases" stores a negative link', (tester) async {
      final current = await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Hiring'),
            GraphNode(id: 'b', label: 'Backlog'),
          ],
        ),
      );

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'From'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hiring').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'To'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backlog').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decreases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();

      expect(current.value.records(kGraphEdgesSlot).first['sign'], '-');
    });

    testWidgets(
      'keeps a link whose element was deleted, rather than hiding it',
      (tester) async {
        // Silently dropping the row would look like the link was lost.
        await pumpGraph(
          tester,
          conceptMap,
          slots: graphSlots(
            nodes: const [GraphNode(id: 'a', label: 'Caching')],
            edges: const [GraphEdge(from: 'a', to: 'gone', label: 'reduces')],
          ),
        );

        expect(find.text('Caching reduces a deleted element'), findsOne);
      },
    );

    testWidgets('removing a link drops it from the session', (tester) async {
      final current = await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
          edges: const [GraphEdge(from: 'a', to: 'b', label: 'x')],
        ),
      );

      await tester.tap(find.byTooltip('Remove link'));
      await tester.pumpAndSettle();

      expect(current.value.records(kGraphEdgesSlot), isEmpty);
    });

    testWidgets('an unnamed element is still selectable by name', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: ''),
            GraphNode(id: 'b', label: 'B'),
          ],
          edges: const [GraphEdge(from: 'a', to: 'b', label: 'x')],
        ),
      );

      expect(find.text('Unnamed element x B'), findsOne);
    });
  });

  group('feedback loops', () {
    testWidgets('signed graphs offer polarity instead of a free label', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
        ),
      );

      expect(find.text('Increases'), findsOne);
      expect(find.widgetWithText(TextField, 'Relationship'), findsNothing);
    });

    testWidgets('explains itself when nothing loops yet', (tester) async {
      await pumpGraph(tester, connectionCircles);

      expect(find.textContaining('No closed loops yet'), findsOne);
    });

    testWidgets('names a reinforcing loop', (tester) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Bugs'),
            GraphNode(id: 'b', label: 'Rework'),
          ],
          edges: const [
            GraphEdge(from: 'a', to: 'b', sign: EdgeSign.positive),
            GraphEdge(from: 'b', to: 'a', sign: EdgeSign.positive),
          ],
        ),
      );

      expect(find.text('Reinforcing: Bugs → Rework → Bugs'), findsOne);
    });

    testWidgets('names a balancing loop', (tester) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Backlog'),
            GraphNode(id: 'b', label: 'Hiring'),
          ],
          edges: const [
            GraphEdge(from: 'a', to: 'b', sign: EdgeSign.positive),
            GraphEdge(from: 'b', to: 'a', sign: EdgeSign.negative),
          ],
        ),
      );

      expect(find.text('Balancing: Backlog → Hiring → Backlog'), findsOne);
    });

    testWidgets('an unsigned graph shows no loop section at all', (
      tester,
    ) async {
      await pumpGraph(tester, conceptMap);

      expect(find.text('Feedback loops'), findsNothing);
    });
  });

  group('the drawn diagram', () {
    testWidgets('draws a chip per node', (tester) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Bugs'),
            GraphNode(id: 'b', label: 'Rework'),
          ],
        ),
      );

      // Once on the canvas and once in the editable list below it.
      expect(find.text('Bugs'), findsNWidgets(2));
    });

    testWidgets('repaints when a label changes', (tester) async {
      // shouldRepaint only runs when the framework is handed a new painter of
      // the same type, so it needs an actual edit to be exercised.
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
          edges: const [GraphEdge(from: 'a', to: 'b', label: 'x')],
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Renamed');
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsWidgets);
    });

    testWidgets('repaints when a link is added', (tester) async {
      final current = await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'A'),
            GraphNode(id: 'b', label: 'B'),
          ],
        ),
      );

      current.value = current.value.withSlot(
        kGraphEdgesSlot,
        edgesToRecords(const [GraphEdge(from: 'a', to: 'b', label: 'x')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('A x B'), findsOne);
    });

    testWidgets('draws a self-loop without collapsing to a point', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        connectionCircles,
        slots: graphSlots(
          nodes: const [GraphNode(id: 'a', label: 'Debt')],
          edges: const [
            GraphEdge(from: 'a', to: 'a', sign: EdgeSign.positive),
          ],
        ),
      );

      expect(find.text('Reinforcing: Debt → Debt'), findsOne);
    });

    testWidgets('reserves no canvas while the diagram is empty', (
      tester,
    ) async {
      // Found on a Pixel 6a: 320px of blank canvas is a third of a phone
      // screen, and it pushed "Add element" — the only thing there is to do on
      // an empty graph — below the fold. The desktop test sizes hid it.
      await pumpGraph(tester, conceptMap, size: const Size(1080, 2400));

      // Asserted on the reserved height, not on CustomPaint: Material uses
      // painters internally, so its presence says nothing about our canvas.
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == kCanvasHeight,
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(find.text('Add element'), findsOne);
    });

    testWidgets('shows the canvas once there is a node to draw', (
      tester,
    ) async {
      await pumpGraph(
        tester,
        conceptMap,
        slots: graphSlots(
          nodes: const [GraphNode(id: 'a', label: 'A')],
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == kCanvasHeight,
        ),
        findsOne,
      );
    });

    testWidgets('gives a node label more room than the disc it labels', (
      tester,
    ) async {
      // "Rework" rendered as "Rewor" on a Pixel 6a: the label was constrained
      // to the 68px disc. Asserted on the box the text is laid out in, not on
      // the glyphs' own width — a short word fits either way, so measuring the
      // rendered text would pass against the bug.
      await pumpGraph(
        tester,
        connectionCircles,
        size: const Size(1080, 2400),
        slots: graphSlots(
          nodes: const [
            GraphNode(id: 'a', label: 'Rework'),
            GraphNode(id: 'b', label: 'Bugs'),
          ],
        ),
      );

      final slot = tester.getSize(
        find
            .ancestor(
              of: find.text('Rework').first,
              matching: find.byType(Stack),
            )
            .first,
      );

      expect(slot.width, kNodeLabelWidth);
      expect(slot.width, greaterThan(kNodeRadius * 2));
    });

    testWidgets('is usable at 1024x600 without overflowing', (tester) async {
      await pumpGraph(
        tester,
        ishikawaDiagram,
        size: const Size(1024, 600),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
