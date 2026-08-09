/// The web session store: sessions in IndexedDB.
///
/// This is also the *desktop* store — the Linux desktop app is this web build
/// running in a Chrome `--app` window. That has a consequence worth stating
/// plainly: sessions live in the browser profile, so wiping that profile wipes
/// them, and the Markdown export is the only backup.
library;

import 'package:idb_shim/idb_browser.dart';
import 'package:untools/data/session_codec.dart';
import 'package:untools/data/session_store_api.dart';
import 'package:untools/model/session.dart';

/// Database name. Fixed: IndexedDB is keyed by origin *and* name, so changing
/// either silently presents an empty app rather than an error.
const String kSessionDbName = 'untools';

/// Object store holding one record per session, keyed by session id.
const String kSessionStoreName = 'sessions';

/// Opens the IndexedDB-backed store.
// coverage:ignore-start
// Reaches for the browser IndexedDB factory, which does not exist on the VM
// test host; [openSessionStoreWith] holds the logic and is covered via the
// in-memory idb factory.
Future<SessionStore> openSessionStore() =>
    openSessionStoreWith(idbFactoryBrowser);
// coverage:ignore-end

/// Opens the store on [factory].
///
/// Split out so tests drive the real read/write paths against `idb_shim`'s
/// in-memory factory instead of a browser.
Future<SessionStore> openSessionStoreWith(IdbFactory factory) async {
  final db = await factory.open(
    kSessionDbName,
    version: 1,
    onUpgradeNeeded: (event) {
      event.database.createObjectStore(kSessionStoreName);
    },
  );
  return IndexedDbSessionStore(db);
}

/// A [SessionStore] backed by an IndexedDB object store.
class IndexedDbSessionStore implements SessionStore {
  /// Creates a store over an open [database].
  IndexedDbSessionStore(this.database);

  /// The open IndexedDB database.
  final Database database;

  @override
  Future<List<Session>> loadAll() async {
    final txn = database.transaction(kSessionStoreName, idbModeReadOnly);
    final records = await txn.objectStore(kSessionStoreName).getAll();
    await txn.completed;
    return decodeSessionList(
      // getAll returns the stored values; normalise each to a JSON map so the
      // shared decoder sees exactly what the file backend gives it.
      [
        for (final record in records)
          if (record is Map) Map<String, Object?>.from(record),
      ],
    );
  }

  @override
  Future<void> save(Session session) async {
    final txn = database.transaction(kSessionStoreName, idbModeReadWrite);
    await txn
        .objectStore(kSessionStoreName)
        .put(encodeSession(session), session.id);
    await txn.completed;
  }

  @override
  Future<void> delete(String id) async {
    final txn = database.transaction(kSessionStoreName, idbModeReadWrite);
    await txn.objectStore(kSessionStoreName).delete(id);
    await txn.completed;
  }
}
