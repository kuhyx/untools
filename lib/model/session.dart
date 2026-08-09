/// A user's filled-in worksheet for one tool.
library;

/// The current session schema version.
///
/// Bumped only for a genuinely breaking change to how slots are *shaped*.
/// Reordering steps, renaming a prompt or adding a field are all non-breaking,
/// because answers are keyed by stable slot id rather than by position.
const int kSessionSchemaVersion = 1;

/// One worked-through instance of a tool.
///
/// [slots] maps a stable slot id (from the tool's config) to that slot's
/// answer. Values are JSON-compatible: a `String` for a text answer, a
/// `List<Map<String, Object?>>` for nested structures like tree nodes or grid
/// rows, each element carrying its own id.
class Session {
  /// Creates a session.
  const Session({
    required this.id,
    required this.toolId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.slots,
    this.schemaVersion = kSessionSchemaVersion,
  });

  /// Unique id (uuid v4).
  final String id;

  /// Which tool this is a session of — a [ToolConfig.id].
  final String toolId;

  /// User-supplied name, so a list of sessions is scannable.
  final String title;

  /// When the session was started.
  final DateTime createdAt;

  /// When it was last edited.
  final DateTime updatedAt;

  /// Schema version this session's slots were written under.
  final int schemaVersion;

  /// Answers, keyed by stable slot id.
  ///
  /// Keys the running build does not recognise are **kept**, not dropped, so a
  /// session written by a newer build survives a round-trip through an older
  /// one instead of silently losing the answers it could not display.
  final Map<String, Object?> slots;

  /// Reads a text answer, defaulting to empty when the slot is unset.
  String text(String slotId) {
    final value = slots[slotId];
    return value is String ? value : '';
  }

  /// Reads a list-of-records answer, defaulting to empty when the slot is
  /// unset.
  ///
  /// Used by every structure-holding pattern (tree nodes, graph nodes and
  /// edges, grid rows, quadrant items).
  List<Map<String, Object?>> records(String slotId) {
    final value = slots[slotId];
    if (value is! List) return const [];
    return [
      for (final element in value)
        if (element is Map<String, Object?>) element,
    ];
  }

  /// Returns a copy with [slotId] set to [value] and [updatedAt] refreshed.
  Session withSlot(String slotId, Object? value, {DateTime? now}) {
    return copyWith(
      slots: {...slots, slotId: value},
      updatedAt: now ?? DateTime.now(),
    );
  }

  /// Returns a copy with the given fields replaced.
  Session copyWith({
    String? title,
    DateTime? updatedAt,
    Map<String, Object?>? slots,
  }) {
    return Session(
      id: id,
      toolId: toolId,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion,
      slots: slots ?? this.slots,
    );
  }
}
