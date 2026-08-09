import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:untools/data/session_store_io.dart';
import 'package:untools/model/session.dart';

Session buildSession({
  String id = 's1',
  String title = 'A session',
  Map<String, Object?> slots = const {},
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: id,
    toolId: 'inversion',
    title: title,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    slots: slots,
  );
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('untools_store'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('loads an empty list when nothing has been saved', () async {
    final store = await openSessionStoreIn(dir.path);
    expect(await store.loadAll(), isEmpty);
  });

  test('saves and reads a session back', () async {
    final store = await openSessionStoreIn(dir.path);

    await store.save(buildSession(slots: {'worst': 'ship it untested'}));

    final loaded = await store.loadAll();
    expect(loaded.single.text('worst'), 'ship it untested');
  });

  test(
    'replaces an existing session by id rather than duplicating it',
    () async {
      final store = await openSessionStoreIn(dir.path);
      await store.save(buildSession(title: 'First'));

      await store.save(buildSession(title: 'Second'));

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Second');
    },
  );

  test('keeps other sessions when one is replaced', () async {
    final store = await openSessionStoreIn(dir.path);
    await store.save(buildSession(id: 'a'));
    await store.save(buildSession(id: 'b'));

    await store.save(buildSession(id: 'a', title: 'Edited'));

    final loaded = await store.loadAll();
    expect(loaded.map((s) => s.id).toSet(), {'a', 'b'});
  });

  test('deletes by id', () async {
    final store = await openSessionStoreIn(dir.path);
    await store.save(buildSession(id: 'a'));
    await store.save(buildSession(id: 'b'));

    await store.delete('a');

    expect((await store.loadAll()).single.id, 'b');
  });

  test('deleting an unknown id is not an error', () async {
    final store = await openSessionStoreIn(dir.path);
    await store.save(buildSession(id: 'a'));

    await store.delete('never-existed');

    expect(await store.loadAll(), hasLength(1));
  });

  test('survives a corrupt file rather than throwing', () async {
    // The store is the last thing that should take the app down: a truncated
    // or hand-edited file reads as "no sessions", not as a crash on launch.
    File(p.join(dir.path, 'sessions.json')).writeAsStringSync('{not json');
    final store = await openSessionStoreIn(dir.path);

    expect(await store.loadAll(), isEmpty);
  });

  test('treats an empty file as no sessions', () async {
    File(p.join(dir.path, 'sessions.json')).writeAsStringSync('   ');
    final store = await openSessionStoreIn(dir.path);

    expect(await store.loadAll(), isEmpty);
  });

  test('creates the directory when it does not exist yet', () async {
    final nested = p.join(dir.path, 'deeper', 'still');
    final store = await openSessionStoreIn(nested);

    await store.save(buildSession());

    expect(await store.loadAll(), hasLength(1));
  });

  test('returns sessions newest-edited first', () async {
    final store = await openSessionStoreIn(dir.path);
    await store.save(
      buildSession(id: 'older', updatedAt: DateTime(2026)),
    );
    await store.save(
      buildSession(id: 'newer', updatedAt: DateTime(2026, 8, 9)),
    );

    expect((await store.loadAll()).map((s) => s.id), ['newer', 'older']);
  });
}
