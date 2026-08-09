/// Android/desktop export: hand the Markdown to the system share sheet.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Shares [markdown] as a file named [filename].
///
/// Writes to a temp file first because the share sheet takes a file, and a
/// `.md` attachment is what the receiving app (notes, email, editor) can
/// actually open — pasting a long string into an intent extra is truncated by
/// some receivers.
// coverage:ignore-start
// Touches the real temp directory and the platform share intent, neither of
// which exists on the Linux test host.
Future<void> shareMarkdown(String markdown, {required String filename}) async {
  final file = File(p.join(Directory.systemTemp.path, filename));
  await file.writeAsString(markdown);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: markdown),
  );
}

// coverage:ignore-end
