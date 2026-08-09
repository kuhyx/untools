/// Web/desktop export: download the Markdown as a file.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Downloads [markdown] as [filename].
///
/// A Blob URL plus a synthetic anchor click is the portable way to save a
/// generated file from the browser; it needs no server round-trip, which
/// matters because this app has no server.
// coverage:ignore-start
// Requires a real DOM; unreachable on the VM test host.
Future<void> shareMarkdown(String markdown, {required String filename}) async {
  final blob = web.Blob(
    [markdown.toJS].toJS,
    web.BlobPropertyBag(type: 'text/markdown'),
  );
  final url = web.URL.createObjectURL(blob);
  web.document.body!.appendChild(
    web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..click(),
  );
  web.URL.revokeObjectURL(url);
}

// coverage:ignore-end
