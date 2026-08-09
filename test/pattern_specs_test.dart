import 'package:flutter_test/flutter_test.dart';
import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

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

  test('a wizard step carries its prompt and any subfields', () {
    final step = WizardStep(
      slotId: 'worst',
      title: 'The worst version',
      prompt: 'Describe it.',
      subfields: [
        WizardStep(slotId: 'why', title: 'Why', prompt: 'Why that?'),
      ],
    );

    expect(step.title, 'The worst version');
    expect(step.subfields, hasLength(1));
  });

  test('a quadrant names itself and what to do about it', () {
    final quadrant = QuadrantSpec(
      corner: QuadrantCorner.topRight,
      slotId: 'do',
      name: 'Do',
      action: 'Handle it now.',
    );

    expect(quadrant.corner, QuadrantCorner.topRight);
    expect(quadrant.name, 'Do');
    expect(quadrant.action, isNotEmpty);
  });

  group('every ToolConfig variant', () {
    // Constructed at RUNTIME, one per variant, for the same reason as the spec
    // types above: the catalogue in `lib/tools/` is entirely `const`, so these
    // constructors are compile-time folded and never execute. Whether that
    // counts as covered depends on how the VM canonicalises constants — it did
    // on a dev machine and did not on a CI runner, which is a nine-line
    // coverage gap that looks like a real one. Do not "tidy" these to `const`.
    const id = 'x';
    const name = 'X';
    const blurb = 'b';
    const attribution = 'From somewhere';
    const primary = ToolCategory.problemSolving;
    const tags = <String>[];
    const related = <String>[];

    test('wizard', () {
      final config = WizardConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        steps: const [WizardStep(slotId: 's', title: 'S', prompt: 'p')],
      );

      expect(config.steps, hasLength(1));
    });

    test('matrix', () {
      final config = MatrixConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        xAxis: const AxisSpec(label: 'X', lowLabel: 'lo', highLabel: 'hi'),
        yAxis: const AxisSpec(label: 'Y', lowLabel: 'lo', highLabel: 'hi'),
        quadrants: const [
          QuadrantSpec(
            corner: QuadrantCorner.topLeft,
            slotId: 'q',
            name: 'Q',
            action: 'a',
          ),
        ],
      );

      expect(config.quadrants, hasLength(1));
    });

    test('tree', () {
      final config = TreeConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        rootPrompt: 'p',
        modes: const [TreeMode(id: 'why', label: 'Why', childPrompt: 'c')],
      );

      expect(config.modes, hasLength(1));
      expect(config.meceCheck, isFalse);
    });

    test('graph', () {
      final config = GraphConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        variant: GraphVariant.free,
        seeds: const [SeedNode(slotId: 's', label: 'S')],
      );

      expect(config.variant, GraphVariant.free);
      expect(config.seeds, hasLength(1));
    });

    test('loop', () {
      final config = LoopConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        phases: const [LoopPhase(slotId: 'p', name: 'P', prompt: 'p')],
      );

      expect(config.phases, hasLength(1));
      expect(config.growable, isFalse);
    });

    test('ladder', () {
      final config = LadderConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        fixedRungs: const [RungSpec(slotId: 'r', name: 'R', prompt: 'p')],
      );

      expect(config.fixedRungs, hasLength(1));
      expect(config.grow, isNull);
    });

    test('lens', () {
      final config = LensConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        lenses: const [LensCard(slotId: 'l', name: 'L', prompt: 'p')],
      );

      expect(config.lenses, hasLength(1));
      expect(config.classifier, isNull);
    });

    test('scored grid', () {
      final config = ScoredGridConfig(
        id: id,
        name: name,
        blurb: blurb,
        attribution: attribution,
        primary: primary,
        tags: tags,
        related: related,
        mode: GridMode.weightedScore,
        rowNoun: 'Option',
        columnNoun: 'Factor',
      );

      expect(config.mode, GridMode.weightedScore);
      expect(config.rowNoun, 'Option');
    });
  });
}
