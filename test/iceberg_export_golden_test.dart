import 'package:flutter_test/flutter_test.dart';
import 'package:untools/export/session_markdown.dart';
import 'package:untools/model/session.dart';
import 'package:untools/tools/systems/iceberg_model.dart';

/// An end-to-end look at what a filled-in session actually exports as.
///
/// The per-branch export tests assert fragments; this one renders one real
/// tool with real answers and pins the whole document, because the thing that
/// makes an export useful — that it reads as a coherent piece of writing
/// rather than a form dump — is not visible one `contains` at a time.
void main() {
  test('a completed Iceberg session exports as a readable document', () {
    final now = DateTime.utc(2026, 8, 9);
    final session = Session(
      id: 's',
      toolId: icebergModel.id,
      title: 'Recurring release bugs',
      createdAt: now,
      updatedAt: now,
      slots: const {
        'events': 'Third hotfix this month.',
        'patterns':
            'Always in the payment path, always the week after a release.',
        'structures':
            'No integration test covers payments, and release day is Friday.',
        'mental-models':
            'We treat shipping on schedule as the thing being measured.',
      },
    );

    final markdown = sessionToMarkdown(session, icebergModel, now: now);

    expect(markdown, '''
# Recurring release bugs

_Iceberg model — Systems-thinking canon, in the Donella Meadows lineage_

The same problem keeps coming back. Look under the incident for the pattern, the structure producing it, and the belief that keeps that structure in place.

## Events

Third hotfix this month.

## Patterns

Always in the payment path, always the week after a release.

## Structures

No integration test covers payments, and release day is Friday.

## Mental models

We treat shipping on schedule as the thing being measured.

---

Exported 2026-08-09 · untools
''');
  });
}
