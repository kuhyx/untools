/// The storage contract both platform backends implement.
///
/// Kept in its own library (rather than in `session_store.dart`, which is a
/// conditional export) so tests and the repository can name the type without
/// dragging in a platform implementation.
library;

import 'package:untools/model/session.dart';

/// Local, per-device persistence for [Session]s.
///
/// Implementations are a JSON file on Android and IndexedDB on web. Both are
/// last-write-wins over the whole record; there is no merge, because there is
/// no second writer.
abstract interface class SessionStore {
  /// Every stored session, newest first.
  ///
  /// Records that fail to decode are skipped rather than thrown, so one
  /// corrupt entry cannot make the whole list unreadable.
  Future<List<Session>> loadAll();

  /// Inserts or replaces [session] by id.
  Future<void> save(Session session);

  /// Removes the session with [id]. A missing id is not an error.
  Future<void> delete(String id);
}
