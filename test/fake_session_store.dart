import 'package:untools/data/session_store_api.dart';
import 'package:untools/model/session.dart';

/// An in-memory [SessionStore] for tests.
///
/// A fake rather than a mock: the screens only care that a save round-trips,
/// and asserting on real behaviour reads better than asserting on call counts.
class FakeSessionStore implements SessionStore {
  /// Creates a store, optionally pre-populated.
  ///
  /// [saveDelay] models the latency of a real write. It defaults to zero, but
  /// a test that types several characters in a row needs it: an instant store
  /// hides lost-update races that a phone reproduces every time.
  FakeSessionStore([
    List<Session> initial = const [],
    this.saveDelay = Duration.zero,
  ]) : _sessions = [...initial];

  final List<Session> _sessions;

  /// How long a write takes to complete.
  final Duration saveDelay;

  /// Set to have the next write throw, to exercise failure handling.
  Object? failure;

  @override
  Future<List<Session>> loadAll() async {
    return [..._sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> save(Session session) async {
    if (saveDelay > Duration.zero) await Future<void>.delayed(saveDelay);
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
