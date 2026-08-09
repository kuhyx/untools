/// Converts a [Session] to and from plain JSON.
///
/// Pure Dart with no Flutter or platform imports, so it is exhaustively
/// unit-testable — which matters, because this is the layer where a mistake
/// silently eats a user's saved work.
library;

import 'package:untools/model/session.dart';
import 'package:untools/model/session_migrations.dart';

/// Thrown when stored JSON cannot be read as a session.
class SessionDecodeException implements Exception {
  /// Creates a decode exception.
  const SessionDecodeException(this.message);

  /// What was wrong.
  final String message;

  @override
  String toString() => 'SessionDecodeException: $message';
}

/// Serialises [session] to a JSON-compatible map.
Map<String, Object?> encodeSession(Session session) {
  return {
    'id': session.id,
    'toolId': session.toolId,
    'title': session.title,
    'createdAt': session.createdAt.toUtc().toIso8601String(),
    'updatedAt': session.updatedAt.toUtc().toIso8601String(),
    'schemaVersion': session.schemaVersion,
    'slots': session.slots,
  };
}

/// Reads a session from [json], applying any pending migrations.
///
/// Unknown keys inside `slots` are preserved verbatim rather than filtered
/// against the running build's config, so a session written by a newer build
/// round-trips through an older one without losing data.
///
/// Throws [SessionDecodeException] when a required field is missing or of the
/// wrong type — a corrupt record is skipped by the repository rather than
/// taking the whole store down with it.
Session decodeSession(Map<String, Object?> json) {
  final id = _requireString(json, 'id');
  final toolId = _requireString(json, 'toolId');
  final createdAt = _requireTime(json, 'createdAt');
  final updatedAt = _requireTime(json, 'updatedAt');
  final rawVersion = json['schemaVersion'];
  final rawSlots = json['slots'];

  final session = Session(
    id: id,
    toolId: toolId,
    title: json['title'] is String ? json['title']! as String : '',
    createdAt: createdAt,
    updatedAt: updatedAt,
    schemaVersion: rawVersion is int ? rawVersion : kSessionSchemaVersion,
    slots: rawSlots is Map<String, Object?> ? Map.of(rawSlots) : const {},
  );
  return migrateSession(session);
}

/// Decodes a stored JSON array, skipping records that cannot be read.
///
/// Shared by both storage backends: the on-disk and IndexedDB payloads have
/// the same shape, and tolerating one bad record — rather than failing the
/// whole load — is the behaviour both want. Sorted newest-edited first.
List<Session> decodeSessionList(Object? decoded) {
  if (decoded is! List) return [];
  final sessions = <Session>[];
  for (final entry in decoded) {
    if (entry is! Map<String, Object?>) continue;
    try {
      sessions.add(decodeSession(entry));
    } on SessionDecodeException {
      continue;
    }
  }
  sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sessions;
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw SessionDecodeException('missing or invalid "$key"');
  }
  return value;
}

DateTime _requireTime(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw SessionDecodeException('missing or invalid "$key"');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw SessionDecodeException('unparseable timestamp in "$key"');
  }
  return parsed.toLocal();
}
