import 'package:flutter_test/flutter_test.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/session.dart';

import 'fake_session_store.dart';

Session buildSession({
  String id = 's1',
  String title = 'A session',
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: id,
    toolId: 'inversion',
    title: title,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    slots: const {},
  );
}

void main() {
  test('load reads everything from the store', () async {
    final repository = SessionRepository(
      FakeSessionStore([buildSession(id: 'a'), buildSession(id: 'b')]),
    );

    await repository.load();

    expect(repository.sessions, hasLength(2));
  });

  test('load notifies listeners', () async {
    final repository = SessionRepository(FakeSessionStore());
    var notified = 0;
    repository.addListener(() => notified++);

    await repository.load();

    expect(notified, 1);
  });

  test('byId finds a loaded session', () async {
    final repository = SessionRepository(
      FakeSessionStore([buildSession(id: 'a')]),
    );
    await repository.load();

    expect(repository.byId('a')?.id, 'a');
  });

  test('byId returns null for an unknown id', () async {
    final repository = SessionRepository(FakeSessionStore());
    await repository.load();

    expect(repository.byId('nope'), isNull);
  });

  test('save adds a new session and notifies', () async {
    final repository = SessionRepository(FakeSessionStore());
    await repository.load();
    var notified = 0;
    repository.addListener(() => notified++);

    await repository.save(buildSession());

    expect(repository.sessions, hasLength(1));
    expect(notified, 1);
  });

  test(
    'save replaces an existing session rather than duplicating it',
    () async {
      final repository = SessionRepository(FakeSessionStore());
      await repository.save(buildSession(title: 'First'));

      await repository.save(buildSession(title: 'Second'));

      expect(repository.sessions, hasLength(1));
      expect(repository.sessions.single.title, 'Second');
    },
  );

  test('save keeps the list newest-edited first', () async {
    final repository = SessionRepository(FakeSessionStore());

    await repository.save(
      buildSession(id: 'old', updatedAt: DateTime(2026)),
    );
    await repository.save(
      buildSession(id: 'new', updatedAt: DateTime(2026, 8, 9)),
    );

    expect(repository.sessions.map((s) => s.id), ['new', 'old']);
  });

  test('save writes through to the store', () async {
    final store = FakeSessionStore();
    final repository = SessionRepository(store);

    await repository.save(buildSession());

    expect(await store.loadAll(), hasLength(1));
  });

  test('delete removes the session and notifies', () async {
    final repository = SessionRepository(
      FakeSessionStore([buildSession(id: 'a')]),
    );
    await repository.load();
    var notified = 0;
    repository.addListener(() => notified++);

    await repository.delete('a');

    expect(repository.sessions, isEmpty);
    expect(notified, 1);
  });

  test('delete leaves other sessions alone', () async {
    final repository = SessionRepository(
      FakeSessionStore([buildSession(id: 'a'), buildSession(id: 'b')]),
    );
    await repository.load();

    await repository.delete('a');

    expect(repository.sessions.single.id, 'b');
  });

  test('sessions is unmodifiable', () async {
    // Callers get a snapshot, not a handle on internal state.
    final repository = SessionRepository(FakeSessionStore());
    await repository.load();

    expect(
      () => repository.sessions.add(buildSession()),
      throwsUnsupportedError,
    );
  });

  test('an edit made while a save is in flight is not lost', () async {
    // The phone bug this reproduces: every keystroke saves, and each save
    // computes the next value from `sessions`. While the write was awaited
    // first, that list stayed stale, so characters typed during the write
    // were built on the old value and dropped — "Deployment" persisted as
    // "Deployme". Needs a store with latency; an instant one cannot race.
    final store = FakeSessionStore(const [], const Duration(milliseconds: 20));
    final repository = SessionRepository(store);
    await repository.load();

    final now = DateTime(2026, 8, 9, 12);
    Session build(String title) => Session(
      id: 's1',
      toolId: 't',
      title: title,
      createdAt: now,
      updatedAt: now.add(Duration(milliseconds: title.length)),
      slots: const {},
    );

    // Fire a save and, without awaiting it, read back what the next edit
    // would build on — exactly what a second keystroke does.
    final inFlight = repository.save(build('Deploy'));
    expect(repository.byId('s1')?.title, 'Deploy');

    final second = repository.save(build('Deployment'));
    await Future.wait([inFlight, second]);

    expect(repository.byId('s1')?.title, 'Deployment');
    expect((await store.loadAll()).single.title, 'Deployment');
  });
}
