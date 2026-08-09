import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/loop/loop_model.dart';

LoopConfig configFor({required bool growable}) => LoopConfig(
  id: 'loop',
  name: 'Loop',
  blurb: 'b',
  attribution: 'a',
  primary: ToolCategory.systemsThinking,
  tags: const [],
  related: const [],
  growable: growable,
  phases: const [
    LoopPhase(slotId: 'phase-1', name: 'One', prompt: 'p1'),
    LoopPhase(slotId: 'phase-2', name: 'Two', prompt: 'p2'),
  ],
);

Session sessionWith(Map<String, Object?> slots) {
  final now = DateTime(2026, 8, 9, 12);
  return Session(
    id: 's1',
    toolId: 'loop',
    title: 't',
    createdAt: now,
    updatedAt: now,
    slots: slots,
  );
}

void main() {
  group('phasesFor', () {
    test('uses the config phases for a fresh session', () {
      final phases = phasesFor(
        configFor(growable: true),
        sessionWith(const {}),
      );

      expect(phases.map((p) => p.name), ['One', 'Two']);
    });

    test('uses the stored phases once a growable loop has been edited', () {
      final session = sessionWith({
        kLoopPhasesSlot: phasesToRecords(const [
          LoopPhase(slotId: 'phase-1', name: 'Mine', prompt: 'p'),
        ]),
      });

      expect(
        phasesFor(configFor(growable: true), session).map((p) => p.name),
        ['Mine'],
      );
    });

    test('ignores stored phases on a fixed loop', () {
      // A fixed method is not customisable, and a session that somehow carries
      // phases must not be able to rewrite OODA.
      final session = sessionWith({
        kLoopPhasesSlot: phasesToRecords(const [
          LoopPhase(slotId: 'x', name: 'Smuggled', prompt: 'p'),
        ]),
      });

      expect(
        phasesFor(configFor(growable: false), session).map((p) => p.name),
        ['One', 'Two'],
      );
    });

    test('falls back to the config when the stored list is empty', () {
      final session = sessionWith(const {kLoopPhasesSlot: <Object?>[]});

      expect(phasesFor(configFor(growable: true), session), hasLength(2));
    });
  });

  group('phase records', () {
    test('round-trip', () {
      const phases = [
        LoopPhase(slotId: 'a', name: 'A', prompt: 'pa'),
        LoopPhase(slotId: 'b', name: 'B', prompt: 'pb'),
      ];

      final restored = phasesFromRecords(phasesToRecords(phases));

      expect(restored.map((p) => p.slotId), ['a', 'b']);
      expect(restored.map((p) => p.name), ['A', 'B']);
      expect(restored.first.prompt, 'pa');
    });

    test('defaults missing and wrong-typed fields', () {
      final restored = phasesFromRecords(const [
        {},
        {'slotId': 7, 'name': false, 'prompt': null},
      ]);

      expect(restored, hasLength(2));
      for (final phase in restored) {
        expect(phase.slotId, '');
        expect(phase.name, '');
        expect(phase.prompt, '');
      }
    });

    test('reads an empty list as empty', () {
      expect(phasesFromRecords(const []), isEmpty);
    });
  });

  group('iterationOf', () {
    test('starts at pass 1', () {
      expect(iterationOf(sessionWith(const {})), 1);
    });

    test('reads a stored pass', () {
      expect(iterationOf(sessionWith(const {kLoopIterationSlot: 4})), 4);
    });

    test('treats a wrong-typed or nonsensical value as the first pass', () {
      // Rendering "Pass 0" or throwing would both be worse than starting over.
      expect(iterationOf(sessionWith(const {kLoopIterationSlot: 'two'})), 1);
      expect(iterationOf(sessionWith(const {kLoopIterationSlot: 0})), 1);
      expect(iterationOf(sessionWith(const {kLoopIterationSlot: -3})), 1);
    });
  });

  group('nextPhaseSlotId', () {
    test('does not collide with an existing id', () {
      const phases = [
        LoopPhase(slotId: 'phase-1', name: 'A', prompt: 'p'),
        LoopPhase(slotId: 'phase-2', name: 'B', prompt: 'p'),
      ];

      expect(nextPhaseSlotId(phases), 'phase-3');
    });

    test('skips past a gap left by a removed phase', () {
      // Removing phase-2 and adding one must not hand out phase-3 twice.
      const phases = [
        LoopPhase(slotId: 'phase-1', name: 'A', prompt: 'p'),
        LoopPhase(slotId: 'phase-3', name: 'C', prompt: 'p'),
      ];

      expect(nextPhaseSlotId(phases), 'phase-4');
    });

    test('works from an empty list', () {
      expect(nextPhaseSlotId(const []), 'phase-1');
    });

    test('never reuses an id, however the list is shaped', () {
      const phases = [
        LoopPhase(slotId: 'phase-1', name: 'A', prompt: 'p'),
        LoopPhase(slotId: 'phase-2', name: 'B', prompt: 'p'),
        LoopPhase(slotId: 'phase-4', name: 'D', prompt: 'p'),
      ];

      final next = nextPhaseSlotId(phases);

      expect(phases.map((p) => p.slotId), isNot(contains(next)));
    });
  });
}
