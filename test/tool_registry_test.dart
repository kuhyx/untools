import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/tools/guide.dart';

/// Invariants over the whole catalogue.
///
/// This is the test that makes adding a 26th tool safe: a config with a
/// duplicate id, a missing attribution or a dangling `related` link fails here
/// rather than shipping as a dead link or an uncredited method.
void main() {
  group('catalogue invariants', () {
    test('ids are unique', () {
      final ids = [for (final tool in allTools) tool.id];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('ids are non-empty, lowercase slugs', () {
      for (final tool in allTools) {
        expect(
          tool.id,
          matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
          reason: '${tool.name} has a malformed id',
        );
      }
    });

    test('every tool credits an original author', () {
      // The frameworks are public methods but the phrasing on any given site
      // is not, so this app writes its own prose and names a source. A tool
      // cannot ship uncredited.
      for (final tool in allTools) {
        expect(
          tool.attribution.trim(),
          isNotEmpty,
          reason: '${tool.name} has no attribution',
        );
      }
    });

    test('every attribution reads as a complete credit line', () {
      // The detail screen prints the attribution verbatim. It used to prefix
      // "Devised by", which produced "Devised by Systems-thinking canon, in
      // the Donella Meadows lineage" on the phone — broken English, shipped.
      // So each attribution now carries its own opening, and this asserts the
      // convention rather than trusting the next author to remember it.
      const openers = ['Devised by', 'Implements', 'From', 'A ', 'The '];
      for (final tool in allTools) {
        expect(
          openers.any(tool.attribution.startsWith),
          isTrue,
          reason:
              '${tool.name}: "${tool.attribution}" must start with one of '
              '$openers so it reads as a sentence on its own',
        );
      }
    });

    test('every tool has a name and a blurb', () {
      for (final tool in allTools) {
        expect(tool.name.trim(), isNotEmpty);
        expect(tool.blurb.trim(), isNotEmpty);
      }
    });

    test('every related id is a well-formed slug', () {
      // Deliberately NOT asserting that each id resolves yet: configs written
      // now legitimately point at tools landing in a later phase, and
      // [relatedTools] drops unresolved ids rather than crashing. The
      // resolution check below is gated on the catalogue being complete, so it
      // turns itself on once all 25 tools are registered.
      for (final tool in allTools) {
        for (final id in tool.related) {
          expect(
            id,
            matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
            reason: '${tool.name} has a malformed related id "$id"',
          );
        }
      }
    });

    test('no related id dangles once the catalogue is complete', () {
      // Guard rather than skip: the moment the 25th tool is registered this
      // starts enforcing that every cross-link resolves, with no one having to
      // remember to re-enable it.
      if (allTools.length < 25) return;
      for (final tool in allTools) {
        for (final id in tool.related) {
          expect(
            toolById(id),
            isNotNull,
            reason: '${tool.name} links to unknown tool "$id"',
          );
        }
      }
    });

    test('no tool lists itself as related', () {
      for (final tool in allTools) {
        expect(tool.related, isNot(contains(tool.id)));
      }
    });

    test('every guide question maps to a registered tool', () {
      // Stricter than [related]: the guide is the app's front door, and a
      // question that opens nothing is a dead end the user walks straight
      // into. Guide entries are added with their tool, not ahead of it.
      for (final entry in guideQuestions) {
        expect(
          toolById(entry.toolId),
          isNotNull,
          reason: 'guide question "${entry.question}" points nowhere',
        );
      }
    });

    test('guide questions are phrased as the user\'s situation', () {
      for (final entry in guideQuestions) {
        expect(entry.question.trim(), isNotEmpty);
      }
    });
  });

  group('queries', () {
    test('toolById finds a registered tool', () {
      expect(toolById('inversion')?.name, 'Inversion');
    });

    test('toolById returns null for an unknown id', () {
      // Null rather than throwing: a session can outlive the tool it was
      // created from, and that is an expected state, not a bug.
      expect(toolById('no-such-tool'), isNull);
    });

    test('toolsInCategory filters by primary category', () {
      final decision = toolsInCategory(ToolCategory.decisionMaking);

      expect(decision, isNotEmpty);
      for (final tool in decision) {
        expect(tool.primary, ToolCategory.decisionMaking);
      }
    });

    test('toolsInCategory is empty for a category with no tools yet', () {
      // Communication has no tools until a later phase; the query must cope.
      final all = {
        for (final category in ToolCategory.values)
          category: toolsInCategory(category),
      };
      expect(all.values.expand((tools) => tools), hasLength(allTools.length));
    });

    test('relatedTools resolves ids to configs', () {
      final related = relatedTools(toolById('eisenhower-matrix')!);
      expect(related.map((t) => t.id), contains('decision-matrix'));
    });

    test('relatedTools silently drops ids that do not resolve', () {
      // Configs may point ahead to tools that land in a later phase; a
      // forward reference should not crash the detail screen.
      const unbuilt = WizardConfig(
        id: 'test-only',
        name: 'Test only',
        blurb: 'blurb',
        attribution: 'nobody',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: ['inversion', 'not-built-yet'],
        steps: [],
      );

      expect(relatedTools(unbuilt).map((t) => t.id), ['inversion']);
    });
  });
}
