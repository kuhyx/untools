/// The loop pattern's stored state: which phases exist, and which pass you
/// are on.
///
/// Flutter-free, like every other pattern's logic file, so the branching here
/// is unit-testable without a pump.
///
/// A fixed loop (OODA) stores no phases at all — the config is the whole truth,
/// and materialising a copy into the session would mean a later correction to
/// the method never reached existing sessions. Only a growable loop writes its
/// phase list, and then only once the user has actually changed it.
library;

import 'package:untools/model/pattern_specs.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';

/// Stable key the user's phase list is stored under.
const String kLoopPhasesSlot = 'loop-phases';

/// Stable key the iteration counter is stored under.
const String kLoopIterationSlot = 'loop-iteration';

/// The phases to show for [config] in [session].
///
/// Falls back to the config's own phases whenever the session carries none,
/// which covers both a fresh session and a fixed loop that can never carry any.
List<LoopPhase> phasesFor(LoopConfig config, Session session) {
  if (!config.growable) return config.phases;
  final stored = phasesFromRecords(session.records(kLoopPhasesSlot));
  return stored.isEmpty ? config.phases : stored;
}

/// Rebuilds the phase list from stored records, tolerating missing keys.
List<LoopPhase> phasesFromRecords(List<Map<String, Object?>> records) => [
  for (final record in records)
    LoopPhase(
      slotId: _string(record['slotId']),
      name: _string(record['name']),
      prompt: _string(record['prompt']),
    ),
];

/// Serialises the phase list.
List<Map<String, Object?>> phasesToRecords(List<LoopPhase> phases) => [
  for (final phase in phases)
    {'slotId': phase.slotId, 'name': phase.name, 'prompt': phase.prompt},
];

/// Which pass round the cycle the session is on, counting from 1.
///
/// Reads defensively: a value that is missing, the wrong type, or below 1 is
/// treated as the first pass rather than rendering "Pass 0" or throwing.
int iterationOf(Session session) {
  final stored = session.slots[kLoopIterationSlot];
  if (stored is! int || stored < 1) return 1;
  return stored;
}

/// A slot id no existing phase is using.
///
/// Derived from a counter rather than the phase's name, because the name is
/// the one thing the user edits — keying on it would move every answer the
/// moment a stage was renamed.
String nextPhaseSlotId(List<LoopPhase> phases) {
  final taken = {for (final phase in phases) phase.slotId};
  var index = phases.length + 1;
  while (taken.contains('phase-$index')) {
    index++;
  }
  return 'phase-$index';
}

String _string(Object? value) => value is String ? value : '';
