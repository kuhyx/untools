import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/app.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/session.dart';

import 'fake_session_store.dart';

/// The two landscape sizes the design system requires to be usable.
///
/// Phone-portrait test sizes exercise neither, so both are named explicitly.
const _laptop = Size(1366, 768);
const _small = Size(1024, 600);

Future<SessionRepository> pumpApp(
  WidgetTester tester, {
  List<Session> sessions = const [],
  Size size = _laptop,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = SessionRepository(FakeSessionStore(sessions));
  await repository.load();
  await tester.pumpWidget(UntoolsApp(repository: repository));
  await tester.pumpAndSettle();
  return repository;
}

Session buildSession({
  String id = 's1',
  String toolId = 'inversion',
  String title = 'A session',
}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: id,
    toolId: toolId,
    title: title,
    createdAt: now,
    updatedAt: now,
    slots: const {},
  );
}

void main() {
  testWidgets('opens on the guide, not an alphabetical tool list', (
    tester,
  ) async {
    // A catalogue only helps someone who already knows which tool they want.
    await pumpApp(tester);

    expect(find.text('Where are you stuck?'), findsOneWidget);
  });

  testWidgets('guide lists a symptom rather than a method name', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('I can only picture this going well.'), findsOneWidget);
  });

  testWidgets('tapping a guide entry opens that tool', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('I can only picture this going well.'));
    await tester.pumpAndSettle();

    expect(find.text('Start a session'), findsOneWidget);
    expect(find.textContaining('Jacobi'), findsOneWidget);
  });

  testWidgets('the tool index groups tools by category', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('All tools'));
    await tester.pumpAndSettle();

    expect(find.text('Problem solving'), findsOneWidget);
    expect(find.text('Decision making'), findsOneWidget);
  });

  testWidgets('tapping a tool in the index opens it', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('All tools'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inversion'));
    await tester.pumpAndSettle();

    expect(find.text('Start a session'), findsOneWidget);
  });

  testWidgets('the sessions tab explains itself when empty', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('the sessions tab lists saved work', (tester) async {
    await pumpApp(tester, sessions: [buildSession(title: 'Launch retro')]);

    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();

    expect(find.text('Launch retro'), findsOneWidget);
    expect(find.text('Inversion'), findsOneWidget);
  });

  testWidgets('a session whose tool no longer exists still lists', (
    tester,
  ) async {
    // A tool can be retired while its sessions live on.
    await pumpApp(tester, sessions: [buildSession(toolId: 'retired-tool')]);

    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();

    expect(find.text('Unknown tool'), findsOneWidget);
  });

  testWidgets('deleting a session removes it from the list', (tester) async {
    await pumpApp(tester, sessions: [buildSession(title: 'Launch retro')]);
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete session'));
    await tester.pumpAndSettle();

    expect(find.text('Launch retro'), findsNothing);
  });

  testWidgets('starting a session opens it and saves it', (tester) async {
    final repository = await pumpApp(tester);
    await tester.tap(find.text('I can only picture this going well.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start a session'));
    await tester.pumpAndSettle();

    expect(repository.sessions, hasLength(1));
    expect(find.text('Describe the worst version'), findsOneWidget);
  });

  testWidgets('reopening a saved session shows the answers back', (
    tester,
  ) async {
    // The whole point of saving: a session is something you come back to.
    await pumpApp(tester);
    await tester.tap(find.text('I can only picture this going well.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start a session'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ship untested');
    await tester.pumpAndSettle();
    // Back twice: out of the session, then out of the tool detail screen.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inversion').first);
    await tester.pumpAndSettle();

    expect(find.text('Ship untested'), findsOneWidget);
  });

  testWidgets('a related tool can be opened from the detail screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(
      find.text(
        'I have several good options and cannot '
        'choose.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try next'), findsOneWidget);
    await tester.tap(find.text('Eisenhower matrix'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Covey'), findsOneWidget);
  });

  testWidgets('remains usable at 1024x600 without overflowing', (
    tester,
  ) async {
    // The short-landscape target: content scrolls rather than clipping.
    await pumpApp(tester, size: _small);

    await tester.tap(find.text('All tools'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
