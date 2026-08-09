/// Platform entry point for the local session store.
///
/// Conditional export because `dart:io` cannot even be *imported* into a web
/// compile, and this app's desktop build **is** the web build. Android gets a
/// JSON file under the application-support directory; web and desktop get
/// IndexedDB.
///
/// Deliberately local-only: there is no network layer, no account and no sync.
/// A session is a five-minute thinking exercise, and the way it leaves the
/// device is the Markdown export.
library;

export 'package:untools/data/session_store_io.dart'
    if (dart.library.js_interop) 'package:untools/data/session_store_web.dart';
