/// Upgrades sessions written under an older schema version.
///
/// This table is expected to stay empty. Answers are keyed by stable slot id
/// rather than by position, so the ordinary kinds of config change — adding a
/// wizard step, reordering rungs, renaming a prompt — are all non-breaking and
/// need no migration. It exists for the rare case that a slot's *value shape*
/// has to change (say a plain string becoming a list of records), which slot
/// ids alone cannot absorb.
library;

import 'package:untools/model/session.dart';

/// Migrations keyed by the version they upgrade *from*.
///
/// Applied in ascending order until the session reaches
/// [kSessionSchemaVersion].
const Map<int, Session Function(Session)> sessionMigrations = {};

/// Brings [session] up to [kSessionSchemaVersion] using [migrations].
///
/// [migrations] is injectable so the walk itself can be tested while the real
/// table is still empty — this code has to work the first time it is ever
/// needed, which is precisely when a user's saved data is on the line, so
/// "untested until we need it" is not good enough.
///
/// A session from a *newer* build is returned untouched: its unknown slots are
/// already preserved by the codec, and guessing at a downgrade would be more
/// destructive than showing the parts this build understands. A gap in the
/// chain also stops the walk rather than skipping a step.
Session migrateSession(
  Session session, {
  Map<int, Session Function(Session)> migrations = sessionMigrations,
}) {
  var current = session;
  while (current.schemaVersion < kSessionSchemaVersion) {
    final step = migrations[current.schemaVersion];
    if (step == null) break;
    current = step(current);
  }
  return current;
}
