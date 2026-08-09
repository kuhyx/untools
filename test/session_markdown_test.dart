import 'package:flutter_test/flutter_test.dart';
import 'package:untools/export/session_markdown.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/tools/decision/decision_matrix.dart';
import 'package:untools/tools/decision/eisenhower_matrix.dart';
import 'package:untools/tools/problem/inversion.dart';

Session sessionFor(
  ToolConfig tool, {
  Map<String, Object?> slots = const {},
  String title = 'My session',
}) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: tool.id,
    title: title,
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

final _exportedAt = DateTime.utc(2026, 8, 9);

void main() {
  group('every export', () {
    test('credits the original author', () {
      // The attribution line is the reason this file has one switch rather
      // than a toMarkdown() per pattern: it cannot be forgotten on a new one.
      final markdown = sessionToMarkdown(
        sessionFor(inversion),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, contains(inversion.attribution));
    });

    test('uses the session title as the heading', () {
      final markdown = sessionToMarkdown(
        sessionFor(inversion, title: 'Launch retro'),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, startsWith('# Launch retro'));
    });

    test('falls back to the tool name when the title is empty', () {
      final markdown = sessionToMarkdown(
        sessionFor(inversion, title: ''),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, startsWith('# Inversion'));
    });

    test('stamps the export date', () {
      final markdown = sessionToMarkdown(
        sessionFor(inversion),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, contains('Exported 2026-08-09 · untools'));
    });

    test('defaults the stamp to now when none is given', () {
      final markdown = sessionToMarkdown(sessionFor(inversion), inversion);
      expect(markdown, contains('· untools'));
    });
  });

  group('wizard', () {
    test('writes each step as a heading with its answer', () {
      final markdown = sessionToMarkdown(
        sessionFor(inversion, slots: {'worst': 'Ship with no tests'}),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, contains('## Describe the worst version'));
      expect(markdown, contains('Ship with no tests'));
    });

    test('marks unanswered steps rather than leaving a blank', () {
      final markdown = sessionToMarkdown(
        sessionFor(inversion),
        inversion,
        now: _exportedAt,
      );

      expect(markdown, contains('_(not answered)_'));
    });

    test('writes subfields under their parent step', () {
      const tool = WizardConfig(
        id: 'sub',
        name: 'Sub',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: [],
        steps: [
          WizardStep(
            slotId: 'parent',
            title: 'Parent',
            prompt: 'p',
            subfields: [
              WizardStep(slotId: 'child', title: 'Child', prompt: 'c'),
            ],
          ),
        ],
      );

      final markdown = sessionToMarkdown(
        sessionFor(tool, slots: {'child': 'nested answer'}),
        tool,
        now: _exportedAt,
      );

      expect(markdown, contains('### Child'));
      expect(markdown, contains('nested answer'));
    });
  });

  group('matrix', () {
    test('writes each quadrant with its prescribed action', () {
      final markdown = sessionToMarkdown(
        sessionFor(
          eisenhowerMatrix,
          slots: {
            'do': [
              {'id': '1', 'label': 'Fix the outage'},
            ],
          },
        ),
        eisenhowerMatrix,
        now: _exportedAt,
      );

      expect(markdown, contains('## Do'));
      expect(markdown, contains('- Fix the outage'));
      expect(markdown, contains('_Handle it now._'));
    });

    test('marks an empty quadrant', () {
      final markdown = sessionToMarkdown(
        sessionFor(eisenhowerMatrix),
        eisenhowerMatrix,
        now: _exportedAt,
      );

      expect(markdown, contains('_(nothing here)_'));
    });
  });

  group('scored grid', () {
    Session gridSession({required int scoreB}) => sessionFor(
      decisionMatrix,
      slots: {
        'factors': [
          {'id': 'f1', 'name': 'Cost', 'weight': 2},
        ],
        'options': [
          {
            'id': 'a',
            'name': 'Option A',
            'scores': <String, Object?>{'f1': 1},
          },
          {
            'id': 'b',
            'name': 'Option B',
            'scores': <String, Object?>{'f1': scoreB},
          },
        ],
      },
    );

    test('renders a table with the weights in the header', () {
      final markdown = sessionToMarkdown(
        gridSession(scoreB: 5),
        decisionMatrix,
        now: _exportedAt,
      );

      expect(markdown, contains('| Option |'));
      expect(markdown, contains('Cost (x2)'));
    });

    test('bolds the winning row', () {
      final markdown = sessionToMarkdown(
        gridSession(scoreB: 5),
        decisionMatrix,
        now: _exportedAt,
      );

      expect(markdown, contains('| **Option B** | 5 | **10** |'));
      expect(markdown, contains('| Option A | 1 | 2 |'));
    });

    test('says so instead of inventing a winner on a tie', () {
      final markdown = sessionToMarkdown(
        gridSession(scoreB: 1),
        decisionMatrix,
        now: _exportedAt,
      );

      expect(markdown, contains('No clear winner'));
      expect(markdown, isNot(contains('**Option')));
    });

    test('defaults a missing weight to 1', () {
      final session = sessionFor(
        decisionMatrix,
        slots: {
          'factors': [
            {'id': 'f1', 'name': 'Cost'},
          ],
          'options': [
            {
              'id': 'a',
              'name': 'A',
              'scores': <String, Object?>{'f1': 3},
            },
          ],
        },
      );

      final markdown = sessionToMarkdown(
        session,
        decisionMatrix,
        now: _exportedAt,
      );

      // A single option is trivially the winner, so it is bolded.
      expect(markdown, contains('Cost (x1)'));
      expect(markdown, contains('| **A** | 3 | **3** |'));
    });

    test('lists the columns for a combination grid', () {
      const combo = ScoredGridConfig(
        id: 'combo',
        name: 'Combo',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: [],
        mode: GridMode.combination,
        rowNoun: 'Value',
        columnNoun: 'Attribute',
      );

      final markdown = sessionToMarkdown(
        sessionFor(
          combo,
          slots: {
            'factors': [
              {'id': 'f1', 'name': 'Timing'},
            ],
          },
        ),
        combo,
        now: _exportedAt,
      );

      expect(markdown, contains('## Attribute values'));
      expect(markdown, contains('- **Timing**'));
    });
  });

  group('patterns landing in later phases', () {
    test('ladder writes each fixed rung', () {
      const ladder = LadderConfig(
        id: 'ladder',
        name: 'Ladder',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        fixedRungs: [
          RungSpec(slotId: 'r1', name: 'Events', prompt: 'p'),
        ],
      );

      final markdown = sessionToMarkdown(
        sessionFor(ladder, slots: {'r1': 'the outage'}),
        ladder,
        now: _exportedAt,
      );

      expect(markdown, contains('## Events'));
      expect(markdown, contains('the outage'));
    });

    test('a growable ladder exports its rungs broadest first', () {
      const growable = LadderConfig(
        id: 'growable',
        name: 'Growable',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: [],
        grow: GrowSpec(
          seedPrompt: 's',
          upLabel: 'Why?',
          upPrompt: 'u',
          downLabel: 'How?',
          downPrompt: 'd',
        ),
      );

      final markdown = sessionToMarkdown(
        sessionFor(
          growable,
          slots: {
            'rungs': [
              {'id': '1', 'label': 'Get soup out of the can'},
              {'id': 'seed', 'label': 'Design a better can opener'},
            ],
          },
        ),
        growable,
        now: _exportedAt,
      );

      expect(markdown, contains('## Rungs, broadest first'));
      expect(markdown, contains('- Get soup out of the can'));
      expect(markdown, contains('- Design a better can opener'));
    });

    test('a fixed ladder exports no rung list', () {
      const fixed = LadderConfig(
        id: 'fixed',
        name: 'Fixed',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        fixedRungs: [RungSpec(slotId: 'r1', name: 'Events', prompt: 'p')],
      );

      final markdown = sessionToMarkdown(
        sessionFor(fixed),
        fixed,
        now: _exportedAt,
      );

      expect(markdown, isNot(contains('Rungs, broadest first')));
    });

    test('lens writes each perspective', () {
      const lens = LensConfig(
        id: 'lens',
        name: 'Lens',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.decisionMaking,
        tags: [],
        related: [],
        lenses: [
          LensCard(slotId: 'risk', name: 'Risks', prompt: 'p'),
        ],
      );

      final markdown = sessionToMarkdown(
        sessionFor(lens, slots: {'risk': 'it could fail'}),
        lens,
        now: _exportedAt,
      );

      expect(markdown, contains('## Risks'));
      expect(markdown, contains('it could fail'));
    });

    test('loop numbers the phases and closes the cycle', () {
      const loop = LoopConfig(
        id: 'loop',
        name: 'Loop',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.decisionMaking,
        tags: [],
        related: [],
        phases: [
          LoopPhase(slotId: 'p1', name: 'Observe', prompt: 'p'),
          LoopPhase(slotId: 'p2', name: 'Act', prompt: 'p'),
        ],
      );

      final markdown = sessionToMarkdown(
        sessionFor(loop, slots: {'p1': 'watched'}),
        loop,
        now: _exportedAt,
      );

      expect(markdown, contains('1. **Observe** — watched'));
      expect(markdown, contains('2. **Act** — _(not answered)_'));
      expect(markdown, contains('…and back to Observe.'));
    });

    test('tree indents children by depth', () {
      const tree = TreeConfig(
        id: 'tree',
        name: 'Tree',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.problemSolving,
        tags: [],
        related: [],
        rootPrompt: 'p',
        modes: [TreeMode(id: 'why', label: 'Why', childPrompt: 'Why?')],
      );

      final markdown = sessionToMarkdown(
        sessionFor(
          tree,
          slots: {
            // Depth is derived from parentId, never stored: a saved depth can
            // disagree with the real structure once a node is reparented.
            'nodes': <Map<String, Object?>>[
              {'id': '1', 'label': 'Root', 'parentId': null},
              {'id': '2', 'label': 'Cause', 'parentId': '1'},
            ],
          },
        ),
        tree,
        now: _exportedAt,
      );

      expect(markdown, contains('- Root'));
      expect(markdown, contains('  - Cause'));
    });

    test('graph writes nodes then labelled links', () {
      const graph = GraphConfig(
        id: 'graph',
        name: 'Graph',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        variant: GraphVariant.circle,
        seeds: [],
      );

      final markdown = sessionToMarkdown(
        sessionFor(
          graph,
          slots: {
            'nodes': [
              {'id': 'a', 'label': 'Bugs'},
              {'id': 'b', 'label': 'Rework'},
            ],
            'edges': [
              {'from': 'a', 'to': 'b', 'sign': '+'},
            ],
          },
        ),
        graph,
        now: _exportedAt,
      );

      expect(markdown, contains('- Bugs'));
      expect(markdown, contains('- Bugs --(+)--> Rework'));
    });

    test('graph tolerates an edge pointing at a missing node', () {
      const graph = GraphConfig(
        id: 'graph2',
        name: 'Graph',
        blurb: 'b',
        attribution: 'a',
        primary: ToolCategory.systemsThinking,
        tags: [],
        related: [],
        variant: GraphVariant.free,
        seeds: [],
      );

      final markdown = sessionToMarkdown(
        sessionFor(
          graph,
          slots: {
            'nodes': [
              {'id': 'a', 'label': 'Bugs'},
            ],
            'edges': [
              {'from': 'a', 'to': 'gone', 'label': 'causes'},
            ],
          },
        ),
        graph,
        now: _exportedAt,
      );

      expect(markdown, contains('- Bugs --(causes)--> ?'));
    });
  });
}
