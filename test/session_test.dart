import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/session_migrations.dart';

Session buildSession({Map<String, Object?> slots = const {}}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: 'inversion',
    title: 'A session',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

void main() {
  group('text', () {
    test('reads a stored string', () {
      expect(buildSession(slots: {'a': 'answer'}).text('a'), 'answer');
    });

    test('is empty for an unset slot', () {
      expect(buildSession().text('missing'), '');
    });

    test('is empty when the slot holds something other than a string', () {
      // Slot shapes can change across builds; a wrong-typed value reads as
      // absent rather than crashing the screen that renders it.
      expect(buildSession(slots: {'a': 42}).text('a'), '');
    });
  });

  group('records', () {
    test('reads a stored list of maps', () {
      final session = buildSession(
        slots: {
          'items': [
            {'id': '1', 'label': 'one'},
          ],
        },
      );

      expect(session.records('items').single['label'], 'one');
    });

    test('is empty for an unset slot', () {
      expect(buildSession().records('missing'), isEmpty);
    });

    test('is empty when the slot is not a list', () {
      expect(buildSession(slots: {'items': 'nope'}).records('items'), isEmpty);
    });

    test('skips elements that are not maps', () {
      final session = buildSession(
        slots: {
          'items': [
            'junk',
            {'id': '1'},
          ],
        },
      );

      expect(session.records('items'), hasLength(1));
    });
  });

  group('withSlot', () {
    test('sets the value and leaves other slots alone', () {
      final updated = buildSession(
        slots: {'keep': 'me'},
      ).withSlot('new', 'value', now: DateTime(2026, 8, 10));

      expect(updated.text('keep'), 'me');
      expect(updated.text('new'), 'value');
    });

    test('refreshes updatedAt', () {
      final at = DateTime(2026, 8, 10, 9, 30);
      expect(buildSession().withSlot('a', 'b', now: at).updatedAt, at);
    });

    test('defaults the timestamp to now', () {
      final before = DateTime.now();
      final updated = buildSession().withSlot('a', 'b');
      expect(
        updated.updatedAt.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('does not mutate the original', () {
      final original = buildSession();
      original.withSlot('a', 'b');
      expect(original.slots, isEmpty);
    });
  });

  group('copyWith', () {
    test('replaces the title', () {
      expect(buildSession().copyWith(title: 'Renamed').title, 'Renamed');
    });

    test('keeps the id, toolId and createdAt', () {
      final original = buildSession();
      final copy = original.copyWith(title: 'Renamed');

      expect(copy.id, original.id);
      expect(copy.toolId, original.toolId);
      expect(copy.createdAt, original.createdAt);
    });

    test('keeps existing values when nothing is passed', () {
      final original = buildSession(slots: {'a': 'b'});
      final copy = original.copyWith();

      expect(copy.title, original.title);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.slots, original.slots);
    });
  });

  group('migrateSession', () {
    test('returns a current-version session untouched', () {
      final session = buildSession(slots: {'a': 'b'});
      expect(migrateSession(session).slots, session.slots);
    });

    test('has no migrations to apply yet', () {
      // Slot-id keying is what keeps this empty: ordinary config changes are
      // absorbed without a migration.
      expect(sessionMigrations, isEmpty);
    });

    test('leaves a session from a newer build alone', () {
      // Guessing at a downgrade would be more destructive than showing the
      // parts this build understands.
      final now = DateTime(2026, 8, 9);
      final future = Session(
        id: 's',
        toolId: 't',
        title: 'From the future',
        createdAt: now,
        updatedAt: now,
        schemaVersion: kSessionSchemaVersion + 5,
        slots: const {'unknown': 'kept'},
      );

      expect(migrateSession(future).slots['unknown'], 'kept');
    });
  });

  group('migrateSession walk', () {
    // Exercised with an injected table so the mechanism is proven now rather
    // than the first time real user data depends on it.
    Session old(int version) {
      final now = DateTime(2026, 8, 9);
      return Session(
        id: 's',
        toolId: 't',
        title: 'Old',
        createdAt: now,
        updatedAt: now,
        schemaVersion: version,
        slots: const {'steps': ''},
      );
    }

    test('applies a migration to reach the current version', () {
      final migrated = migrateSession(
        old(kSessionSchemaVersion - 1),
        migrations: {
          kSessionSchemaVersion - 1: (s) => Session(
            id: s.id,
            toolId: s.toolId,
            title: s.title,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
            slots: {...s.slots, 'steps': 'upgraded'},
          ),
        },
      );

      expect(migrated.text('steps'), 'upgraded');
      expect(migrated.schemaVersion, kSessionSchemaVersion);
    });

    test('applies each step in turn across several versions', () {
      Session bump(Session s, String mark) => Session(
        id: s.id,
        toolId: s.toolId,
        title: s.title,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        schemaVersion: s.schemaVersion + 1,
        slots: {...s.slots, 'steps': '${s.text('steps')}$mark'},
      );

      final migrated = migrateSession(
        old(kSessionSchemaVersion - 2),
        migrations: {
          kSessionSchemaVersion - 2: (s) => bump(s, 'a'),
          kSessionSchemaVersion - 1: (s) => bump(s, 'b'),
        },
      );

      expect(migrated.text('steps'), 'ab');
    });

    test('stops rather than skipping when a step is missing', () {
      // A hole in the chain means the upgrade path is unknown; running the
      // later step against an older shape would corrupt the data.
      final migrated = migrateSession(
        old(kSessionSchemaVersion - 2),
        migrations: {
          kSessionSchemaVersion - 1: (s) => throw StateError('skipped a step'),
        },
      );

      expect(migrated.schemaVersion, kSessionSchemaVersion - 2);
    });
  });
}
