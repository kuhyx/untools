import 'package:untools/data/session_store_api.dart';
import 'package:untools/model/session.dart';

/// An in-memory [SessionStore] for tests.
///
/// A fake rather than a mock: the screens only care that a save round-trips,
/// and asserting on real behaviour reads better than asserting on call counts.
class FakeSessionStore implements SessionStore {
  /// Creates a store, optionally pre-populated.
  FakeSessionStore([List<Session> initial = const []])
    : _sessions = [...initial];

  final List<Session> _sessions;

  /// Set to have the next write throw, to exercise failure handling.
  Object? failure;

  @override
  Future<List<Session>> loadAll() async {
    return [..._sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> save(Session session) async {
    if (failure case final error?) throw Exception(error);
    _sessions
      ..removeWhere((existing) => existing.id == session.id)
      ..add(session);
  }

  @override
  Future<void> delete(String id) async {
    _sessions.removeWhere((existing) => existing.id == id);
  }
}
