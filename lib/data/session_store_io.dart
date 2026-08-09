/// The `dart:io` session store: one JSON file holding every session.
///
/// A single file rather than a database: sessions are small, few, and always
/// read as a whole list, so a table engine would be cost without benefit.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:untools/data/session_codec.dart';
import 'package:untools/data/session_store_api.dart';
import 'package:untools/model/session.dart';

/// Opens the store in the real per-platform application-support directory.
// coverage:ignore-start
// Resolves a platform directory through path_provider, so it cannot run under
// test; [openSessionStoreIn] holds all the logic and is covered.
Future<SessionStore> openSessionStore() async {
  final dir = await getApplicationSupportDirectory();
  return openSessionStoreIn(dir.path);
}
// coverage:ignore-end

/// Opens the store rooted at [dirPath].
///
/// Split out from [openSessionStore] so tests drive the real read/write paths
/// against a temporary directory instead of mocking the file system.
Future<SessionStore> openSessionStoreIn(String dirPath) async {
  return FileSessionStore(File(p.join(dirPath, 'sessions.json')));
}

/// A [SessionStore] backed by one JSON file.
class FileSessionStore implements SessionStore {
  /// Creates a store over [file]. The file need not exist yet.
  FileSessionStore(this.file);

  /// Where the sessions are written.
  final File file;

  @override
  Future<List<Session>> loadAll() async {
    if (!file.existsSync()) return [];
    return _decodeAll(await file.readAsString());
  }

  @override
  Future<void> save(Session session) async {
    final sessions = await loadAll()
      ..removeWhere((existing) => existing.id == session.id);
    await _writeAll([session, ...sessions]);
  }

  @override
  Future<void> delete(String id) async {
    final sessions = await loadAll()
      ..removeWhere((existing) => existing.id == id);
    await _writeAll(sessions);
  }

  Future<void> _writeAll(List<Session> sessions) async {
    await file.parent.create(recursive: true);
    final payload = [for (final s in sessions) encodeSession(s)];
    // Write-then-rename: a crash mid-write leaves the previous good file in
    // place rather than a truncated one.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(payload), flush: true);
    await temp.rename(file.path);
  }
}

List<Session> _decodeAll(String raw) {
  if (raw.trim().isEmpty) return [];
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return [];
  }
  return decodeSessionList(decoded);
}
