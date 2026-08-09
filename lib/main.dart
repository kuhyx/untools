/// App entry point.
// coverage:ignore-file
// Bootstrap wiring only: opens the platform store and hands it to [UntoolsApp],
// which is what the widget tests exercise with a fake store.
library;

import 'package:flutter/material.dart';
import 'package:untools/app.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/data/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openSessionStore();
  final repository = SessionRepository(store);
  await repository.load();
  runApp(UntoolsApp(repository: repository));
}
