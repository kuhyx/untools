import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';

/// Covers the spec types whose tools land in a later phase.
///
/// These are `const` value classes with no logic, so the assertions are thin
/// by design — the point is that the shapes the later patterns will be built
/// against are exercised and cannot silently rot in the meantime.
///
/// **Deliberately `final`, not `const`, at every call site here.** A `const`
/// expression is folded at compile time and its constructor never executes, so
/// whether the constructor line registers as covered depends on how the VM
/// canonicalises constants — it counted on this machine and did not on a CI
/// runner, which is a five-line coverage gap that looks like a real one. The
/// production configs in `lib/tools/` stay `const` on purpose (that is what
/// keeps them out of the coverage denominator); only the tests construct at
/// runtime. Do not "tidy" these back to `const`.
void main() {
  test('SeedNode carries a fixed template node', () {
    final node = SeedNode(
      slotId: 'methods',
      label: 'Methods',
      prompt: 'What about how the work is done?',
    );

    expect(node.slotId, 'methods');
    expect(node.label, 'Methods');
    expect(node.prompt, isNotNull);
    expect(node.fixed, isTrue);
  });

  test('SeedNode can be marked deletable', () {
    final node = SeedNode(slotId: 'extra', label: 'Extra', fixed: false);
    expect(node.fixed, isFalse);
  });

  test('GrowSpec describes both directions of a growable ladder', () {
    final spec = GrowSpec(
      seedPrompt: 'State the problem',
      upLabel: 'Why?',
      upPrompt: 'A broader framing',
      downLabel: 'How?',
      downPrompt: 'A more concrete framing',
    );

    expect(spec.seedPrompt, 'State the problem');
    expect(spec.upLabel, 'Why?');
    expect(spec.upPrompt, 'A broader framing');
    expect(spec.downLabel, 'How?');
    expect(spec.downPrompt, 'A more concrete framing');
  });

  test('a classifier routes an answer to a lens', () {
    final classifier = ClassifierSpec(
      questions: [
        ClassifierQuestion(
          prompt: 'Do you know what caused this?',
          answers: [
            ClassifierAnswer(label: 'Yes, clearly', lensSlotId: 'clear'),
            ClassifierAnswer(label: 'No idea', lensSlotId: 'chaotic'),
          ],
        ),
      ],
    );

    final question = classifier.questions.single;
    expect(question.prompt, 'Do you know what caused this?');
    expect(question.answers.first.label, 'Yes, clearly');
    expect(question.answers.first.lensSlotId, 'clear');
    expect(question.answers.last.lensSlotId, 'chaotic');
  });

  test('a lens card may carry an accent colour', () {
    // Stored as an int so the model layer stays free of Flutter imports.
    final card = LensCard(
      slotId: 'risk',
      name: 'Risks',
      prompt: 'What could go wrong?',
      swatch: 0xFFE2585F,
    );

    expect(card.swatch, 0xFFE2585F);
  });

  test('a tree mode relabels the add-child action', () {
    final mode = TreeMode(
      id: 'why',
      label: 'Problem tree',
      childPrompt: 'Why is this happening?',
    );

    expect(mode.id, 'why');
    expect(mode.label, 'Problem tree');
    expect(mode.childPrompt, 'Why is this happening?');
  });

  test('a loop phase names a step of the cycle', () {
    final phase = LoopPhase(
      slotId: 'observe',
      name: 'Observe',
      prompt: 'What is actually happening?',
    );

    expect(phase.slotId, 'observe');
    expect(phase.name, 'Observe');
    expect(phase.prompt, isNotEmpty);
  });

  test('a rung names a level and the question that interrogates it', () {
    final rung = RungSpec(
      slotId: 'assumptions',
      name: 'Assumptions',
      prompt: 'What am I taking for granted?',
    );

    expect(rung.name, 'Assumptions');
    expect(rung.prompt, isNotEmpty);
  });

  test('an axis names both ends', () {
    final axis = AxisSpec(
      label: 'Urgency',
      lowLabel: 'Not urgent',
      highLabel: 'Urgent',
    );

    expect(axis.label, 'Urgency');
    expect(axis.lowLabel, 'Not urgent');
    expect(axis.highLabel, 'Urgent');
  });
}
