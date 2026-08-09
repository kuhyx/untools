/// In-memory view over the [SessionStore], with change notifications.
library;

import 'package:flutter/foundation.dart';
import 'package:untools/data/session_store_api.dart';
import 'package:untools/model/session.dart';

/// Holds the loaded sessions and writes changes through to the store.
///
/// A [ChangeNotifier] rather than a stream: the whole list is small, always
/// read together, and every screen wants the same snapshot.
class SessionRepository extends ChangeNotifier {
  /// Creates a repository over [store].
  SessionRepository(this._store);

  final SessionStore _store;
  List<Session> _sessions = const [];

  /// The loaded sessions, most recently edited first.
  List<Session> get sessions => List.unmodifiable(_sessions);

  /// Reads every session from the store.
  Future<void> load() async {
    _sessions = await _store.loadAll();
    notifyListeners();
  }

  /// Returns the session with [id], or null when there is none.
  Session? byId(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Inserts or replaces [session], keeping the list newest-first.
  Future<void> save(Session session) async {
    await _store.save(session);
    final next = [
      session,
      for (final existing in _sessions)
        if (existing.id != session.id) existing,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _sessions = next;
    notifyListeners();
  }

  /// Removes the session with [id].
  Future<void> delete(String id) async {
    await _store.delete(id);
    _sessions = [
      for (final existing in _sessions)
        if (existing.id != id) existing,
    ];
    notifyListeners();
  }
}
