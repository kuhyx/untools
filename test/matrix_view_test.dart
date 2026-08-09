import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/patterns/matrix/matrix_view.dart';
import 'package:untools/tools/decision/eisenhower_matrix.dart';

Session buildSession({Map<String, Object?> slots = const {}}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: eisenhowerMatrix.id,
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

/// Pumps the matrix and keeps the latest edit, so a test can assert on the
/// session the widget produced.
Future<Session Function()> pumpMatrix(
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
          builder: (context, setState) => MatrixView(
            session: current,
            config: eisenhowerMatrix,
            onChanged: (updated) => setState(() => current = updated),
          ),
        ),
      ),
    ),
  );
  return () => current;
}

void main() {
  testWidgets('shows every quadrant with its prescribed action', (
    tester,
  ) async {
    await pumpMatrix(tester);

    expect(find.text('Do'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Delegate'), findsOneWidget);
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Handle it now.'), findsOneWidget);
  });

  testWidgets('marks empty quadrants', (tester) async {
    await pumpMatrix(tester);
    expect(find.text('Empty'), findsNWidgets(4));
  });

  testWidgets('names both axes', (tester) async {
    await pumpMatrix(tester);
    expect(find.textContaining('Importance'), findsOneWidget);
  });

  testWidgets('adding an item puts it in the first quadrant', (tester) async {
    final session = await pumpMatrix(tester);

    await tester.enterText(find.byType(TextField), 'Fix the outage');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(session().records('do').single['label'], 'Fix the outage');
  });

  testWidgets('adding via the button works too', (tester) async {
    final session = await pumpMatrix(tester);

    await tester.enterText(find.byType(TextField), 'Write the postmortem');
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();

    expect(session().records('do'), hasLength(1));
  });

  testWidgets('refuses to add an empty item', (tester) async {
    final session = await pumpMatrix(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();

    expect(session().records('do'), isEmpty);
  });

  testWidgets('an item can be moved between quadrants by keyboard alone', (
    tester,
  ) async {
    // The design system requires pointer-free operability, and a drag has no
    // keyboard analogue — so this menu is the load-bearing path, not a
    // convenience alternative to dragging.
    final session = await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Reply to that email'},
        ],
      },
    );

    await tester.tap(find.byTooltip('Move to quadrant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delegate').last);
    await tester.pumpAndSettle();

    expect(session().records('do'), isEmpty);
    expect(
      session().records('delegate').single['label'],
      'Reply to that '
      'email',
    );
  });

  testWidgets('the move menu does not offer the quadrant it is already in', (
    tester,
  ) async {
    await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Item'},
        ],
      },
    );

    await tester.tap(find.byTooltip('Move to quadrant'));
    await tester.pumpAndSettle();

    // 'Do' appears once as the quadrant heading, never as a menu entry.
    expect(find.text('Do'), findsOneWidget);
  });

  testWidgets('an item can be removed', (tester) async {
    final session = await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Item'},
        ],
      },
    );

    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();

    expect(session().records('do'), isEmpty);
  });

  testWidgets('an item can be dragged between quadrants', (tester) async {
    final session = await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Draggable item'},
        ],
      },
    );

    // Driven as an explicit gesture that ends *on* the target rather than
    // `tester.drag` with a precomputed offset. The offset form assumes the
    // target has not moved during the drag, which is false here: lifting the
    // item shrinks its source quadrant and everything below shifts up. That
    // made the drop land in open space on a CI runner (whose font metrics
    // differ from this machine's) while passing locally — a 5-line coverage
    // gap that took a red build to notice.
    final item = find.text('Draggable item');
    final gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('Delegate')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(session().records('delegate'), hasLength(1));
    expect(session().records('do'), isEmpty);
  });

  testWidgets('dropping an item back where it started changes nothing', (
    tester,
  ) async {
    final session = await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Item'},
        ],
      },
    );

    // Dropped back onto its own quadrant: _move must no-op rather than
    // duplicate the item or blank the slot.
    final item = find.text('Item');
    final gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('Do')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(session().records('do'), hasLength(1));
  });

  testWidgets('a quadrant highlights while an item hovers over it', (
    tester,
  ) async {
    // The drop target needs to be visibly distinct mid-drag, or a drag reads
    // as having done nothing.
    await pumpMatrix(
      tester,
      slots: {
        'do': [
          {'id': '1', 'label': 'Hovering item'},
        ],
      },
    );

    final item = find.text('Hovering item');
    final gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('Delegate')));
    await tester.pump();

    final highlighted = tester
        .widgetList<Card>(find.byType(Card))
        .where((card) => card.color != null);
    expect(highlighted, isNotEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('is usable at 1024x600 without overflowing', (tester) async {
    await pumpMatrix(tester, size: const Size(1024, 600));
    expect(tester.takeException(), isNull);
  });
}
