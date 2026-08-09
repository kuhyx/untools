/// Perspective lenses — look at one thing through six separate frames.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/tool_config.dart';

/// Six frames, visited one at a time.
///
/// This implements Edward de Bono's parallel-thinking method. **Six Thinking
/// Hats® is his registered trademark, so the feature is named generically
/// here** and the method is credited to him rather than presented as ours.
///
/// The mechanism is separation: a group arguing about a proposal has everyone
/// defending a position from all angles at once. Asking everyone to look
/// through the same frame at the same time produces more per frame and stops
/// the discussion being a contest.
const perspectiveLenses = LensConfig(
  id: 'perspective-lenses',
  name: 'Perspective lenses',
  blurb:
      'A decision keeps going round in circles. Look at it through one '
      'frame at a time — everyone on the same frame at once — instead of '
      'arguing every angle simultaneously.',
  attribution:
      "Edward de Bono's parallel-thinking method "
      '(Six Thinking Hats® is his trademark)',
  primary: ToolCategory.decisionMaking,
  tags: ['perspective', 'group', 'meeting'],
  related: ['inversion', 'second-order-thinking', 'decision-matrix'],
  lenses: [
    LensCard(
      slotId: 'process',
      name: 'Process',
      prompt:
          'What are we actually deciding, and how will we know when we '
          'are done? Set this before the others and return to it at the end.',
      swatch: 0xFF4A6FA5,
    ),
    LensCard(
      slotId: 'facts',
      name: 'Facts',
      prompt:
          'What do we know, and how do we know it? What is missing? No '
          'interpretation here — just the data and the gaps.',
      swatch: 0xFFECEAE9,
    ),
    LensCard(
      slotId: 'feelings',
      name: 'Feelings',
      prompt:
          'What is your gut saying? Stated without justification, which '
          'is the point: unexplained reactions often carry real information.',
      swatch: 0xFFE2585F,
    ),
    LensCard(
      slotId: 'benefits',
      name: 'Benefits',
      prompt:
          'What goes right? Be specific about who gains what, and argue '
          'for it even if you privately disagree.',
      swatch: 0xFFE0A63C,
    ),
    LensCard(
      slotId: 'risks',
      name: 'Risks',
      prompt:
          'What goes wrong? Where does this fail, and what would we wish '
          'we had asked?',
      swatch: 0xFF211D1B,
    ),
    LensCard(
      slotId: 'alternatives',
      name: 'Alternatives',
      prompt:
          'What else could we do? New options, not evaluations of the '
          'ones already on the table.',
      swatch: 0xFF8A9A3C,
    ),
  ],
);
