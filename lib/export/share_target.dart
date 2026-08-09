/// Platform entry point for getting exported Markdown off the device.
///
/// Android opens the share sheet; web triggers a file download. Conditional
/// export for the same reason the store is: `dart:io` cannot be imported into
/// a web compile, and the desktop build is the web build.
library;

export 'package:untools/export/share_target_io.dart'
    if (dart.library.js_interop) 'package:untools/export/share_target_web.dart';
