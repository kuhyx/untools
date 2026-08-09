import 'package:flutter_test/flutter_test.dart';
import 'package:untools/data/session_codec.dart';
import 'package:untools/model/session.dart';

Session buildSession({
  String id = 's1',
  String toolId = 'inversion',
  Map<String, Object?> slots = const {},
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: id,
    toolId: toolId,
    title: 'A session',
    createdAt: now,
    updatedAt: updatedAt ?? now,
    slots: slots,
  );
}

void main() {
  group('round trip', () {
    test('preserves every field', () {
      final original = buildSession(slots: {'worst': 'ship it untested'});

      final restored = decodeSession(encodeSession(original));

      expect(restored.id, original.id);
      expect(restored.toolId, original.toolId);
      expect(restored.title, original.title);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.text('worst'), 'ship it untested');
    });

    test('keeps slots this build does not recognise', () {
      // A session written by a newer build must survive a round trip through
      // an older one rather than silently losing the answers it cannot show.
      final fromNewerBuild = buildSession(
        slots: {'worst': 'known', 'pattern-from-the-future': 'keep me'},
      );

      final restored = decodeSession(encodeSession(fromNewerBuild));

      expect(restored.slots['pattern-from-the-future'], 'keep me');
    });

    test('preserves nested record structures', () {
      final original = buildSession(
        slots: {
          'options': [
            {
              'id': 'a',
              'name': 'A',
              'scores': <String, Object?>{'f': 3},
            },
          ],
        },
      );

      final restored = decodeSession(encodeSession(original));

      expect(restored.records('options').single['name'], 'A');
    });
  });

  group('decodeSession rejects', () {
    Map<String, Object?> validJson() => encodeSession(buildSession());

    test('a missing id', () {
      expect(
        () => decodeSession(validJson()..remove('id')),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('an empty id', () {
      expect(
        () => decodeSession(validJson()..['id'] = ''),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('a non-string id', () {
      expect(
        () => decodeSession(validJson()..['id'] = 7),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('a missing toolId', () {
      expect(
        () => decodeSession(validJson()..remove('toolId')),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('a non-string timestamp', () {
      expect(
        () => decodeSession(validJson()..['createdAt'] = 12345),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('an unparseable timestamp', () {
      expect(
        () => decodeSession(validJson()..['updatedAt'] = 'last tuesday'),
        throwsA(isA<SessionDecodeException>()),
      );
    });

    test('and reports what was wrong', () {
      expect(
        const SessionDecodeException('missing "id"').toString(),
        contains('missing "id"'),
      );
    });
  });

  group('decodeSession defaults', () {
    test('a missing title to empty', () {
      final json = encodeSession(buildSession())..remove('title');
      expect(decodeSession(json).title, '');
    });

    test('a non-string title to empty', () {
      final json = encodeSession(buildSession())..['title'] = 42;
      expect(decodeSession(json).title, '');
    });

    test('a missing schemaVersion to the current one', () {
      final json = encodeSession(buildSession())..remove('schemaVersion');
      expect(decodeSession(json).schemaVersion, kSessionSchemaVersion);
    });

    test('missing slots to empty', () {
      final json = encodeSession(buildSession())..remove('slots');
      expect(decodeSession(json).slots, isEmpty);
    });

    test('non-map slots to empty', () {
      final json = encodeSession(buildSession())..['slots'] = 'nope';
      expect(decodeSession(json).slots, isEmpty);
    });
  });

  group('decodeSessionList', () {
    test('skips records that cannot be decoded', () {
      // One corrupt entry must not make the whole store unreadable.
      final list = [
        encodeSession(buildSession(id: 'good')),
        {'id': 'broken'},
      ];

      final sessions = decodeSessionList(list);

      expect(sessions.map((s) => s.id), ['good']);
    });

    test('skips entries that are not maps', () {
      expect(decodeSessionList(['nonsense', 42]), isEmpty);
    });

    test('is empty when the payload is not a list', () {
      expect(decodeSessionList('not a list'), isEmpty);
      expect(decodeSessionList(null), isEmpty);
    });

    test('sorts newest edited first', () {
      final list = [
        encodeSession(
          buildSession(id: 'older', updatedAt: DateTime(2026)),
        ),
        encodeSession(
          buildSession(id: 'newer', updatedAt: DateTime(2026, 8, 9)),
        ),
      ];

      expect(
        decodeSessionList(list).map((s) => s.id),
        ['newer', 'older'],
      );
    });
  });
}
