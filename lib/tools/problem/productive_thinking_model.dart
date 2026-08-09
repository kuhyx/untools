/// Productive thinking model — six steps from mess to plan.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Tim Hurson's six-step process, from *Think Better*.
///
/// The step people skip is the third: turning the problem into a question. It
/// feels like a formality and it is where most of the value sits, because
/// "how might we shorten the queue" and "how might we make waiting pleasant"
/// generate entirely different sets of answers to the same complaint.
///
/// Step two uses Hurson's DRIVE checklist as subfields, so success is defined
/// before ideas arrive rather than negotiated afterwards to fit whichever one
/// people liked.
const productiveThinkingModel = WizardConfig(
  id: 'productive-thinking-model',
  name: 'Productive thinking model',
  blurb:
      'A messy problem and no obvious way in. Six steps: understand it, '
      'define success, ask the right question, generate answers, choose one, '
      'and turn it into actions.',
  attribution: 'Devised by Tim Hurson, in Think Better',
  primary: ToolCategory.problemSolving,
  tags: ['creative', 'process', 'thorough'],
  related: ['first-principles', 'inversion', 'decision-matrix'],
  steps: [
    WizardStep(
      slotId: 'whats-going-on',
      title: "1. What's going on?",
      prompt:
          'Describe the situation, who it affects and what you already '
          'know. Include what bothers you about it even if you cannot yet say '
          'why.',
    ),
    WizardStep(
      slotId: 'success',
      title: "2. What's success?",
      prompt:
          'Define what a good outcome looks like, before you have any '
          'ideas to be attached to.',
      helper: "Hurson's DRIVE checklist — fill each below.",
      subfields: [
        WizardStep(
          slotId: 'drive-do',
          title: 'Do',
          prompt: 'What must the solution actually do?',
          multiline: false,
        ),
        WizardStep(
          slotId: 'drive-restrictions',
          title: 'Restrictions',
          prompt: 'What must it not do? Hard limits.',
          multiline: false,
        ),
        WizardStep(
          slotId: 'drive-investment',
          title: 'Investment',
          prompt: 'What are you willing to spend — money, time, attention?',
          multiline: false,
        ),
        WizardStep(
          slotId: 'drive-values',
          title: 'Values',
          prompt: 'What matters here beyond the result itself?',
          multiline: false,
        ),
        WizardStep(
          slotId: 'drive-essential',
          title: 'Essential outcomes',
          prompt: 'What has to be true afterwards for this to have worked?',
          multiline: false,
        ),
      ],
    ),
    WizardStep(
      slotId: 'question',
      title: "3. What's the question?",
      prompt:
          'Write several "how might we…?" questions, then pick the one '
          'worth answering.',
      helper:
          'The step that feels like a formality and is not: different '
          'framings of the same complaint produce entirely different answers.',
    ),
    WizardStep(
      slotId: 'answers',
      title: '4. Generate answers',
      prompt:
          'Answer your question as many ways as you can. No judging yet — '
          'quantity now, quality later.',
    ),
    WizardStep(
      slotId: 'forge',
      title: '5. Forge the solution',
      prompt:
          'Evaluate the candidates against the DRIVE criteria above. '
          'Combine partial answers where they complement each other.',
      helper: 'A decision matrix is the right tool if the shortlist is close.',
    ),
    WizardStep(
      slotId: 'resources',
      title: '6. Align resources',
      prompt:
          'Who does what, by when, and what do they need? An unassigned '
          'solution is still a wish.',
    ),
  ],
);
