/// Feedback framer — say what happened, not what they are.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Situation, behaviour, impact — then ask before concluding.
///
/// This implements the Center for Creative Leadership's feedback method.
/// **SBI™ and Situation-Behavior-Impact™ are their trademarks, so the feature
/// is named generically here** and the method is credited to them.
///
/// The structure works by making judgement hard to smuggle in: "you were
/// unprofessional" is a verdict, and there is nowhere in these three fields to
/// put it. Describing the observable thing and its effect leaves the other
/// person somewhere to stand.
const feedbackFramer = WizardConfig(
  id: 'feedback-framer',
  name: 'Feedback framer',
  blurb:
      'You need to tell someone something awkward. Describe when, what you '
      'observed, and what it caused — and leave the verdict out.',
  attribution: 'Center for Creative Leadership (SBI™ is their trademark)',
  primary: ToolCategory.communication,
  tags: ['feedback', 'conversation', 'quick'],
  related: ['ladder-of-inference', 'minto-pyramid'],
  steps: [
    WizardStep(
      slotId: 'situation',
      title: 'Situation',
      prompt: 'When and where? Anchor it to one specific occasion.',
      helper: 'Not "in meetings" — "in yesterday\'s planning review".',
      multiline: false,
    ),
    WizardStep(
      slotId: 'behavior',
      title: 'Behaviour',
      prompt: 'What did you actually see or hear?',
      helper:
          'Something a camera would have caught. If it needs the word '
          '"seemed" or "clearly", it is an interpretation, not a behaviour.',
    ),
    WizardStep(
      slotId: 'impact',
      title: 'Impact',
      prompt: 'What effect did it have — on you, the team, the work?',
      helper:
          'Speak for yourself. "I lost the thread" is checkable; '
          '"everyone was frustrated" invites an argument about everyone.',
    ),
    WizardStep(
      slotId: 'intent',
      title: 'Then ask',
      prompt: 'What will you ask to find out how they saw it?',
      helper:
          'Optional but load-bearing: you know the impact, not the '
          'reason. Skipping this turns a conversation into a verdict.',
    ),
  ],
);
