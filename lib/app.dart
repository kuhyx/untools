/// The app shell: theme, and the tab structure the screens live in.
library;

import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/screens/guide_screen.dart';
import 'package:untools/screens/sessions_screen.dart';
import 'package:untools/screens/tool_index_screen.dart';
import 'package:untools/ui/theme.dart';

/// Root widget.
class UntoolsApp extends StatelessWidget {
  /// Creates the app over [repository].
  const UntoolsApp({required this.repository, super.key});

  /// The session store, injected so tests can supply a fake.
  final SessionRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'untools',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: HomeShell(repository: repository),
    );
  }
}

/// The three top-level destinations.
///
/// The guide comes first deliberately: an alphabetical list of 25 frameworks
/// only helps someone who already knows which one they want, and someone in
/// the middle of a problem usually does not.
class HomeShell extends StatefulWidget {
  /// Creates the shell.
  const HomeShell({required this.repository, super.key});

  /// The session store.
  final SessionRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      GuideScreen(repository: widget.repository),
      ToolIndexScreen(repository: widget.repository),
      SessionsScreen(repository: widget.repository),
    ];
    return Scaffold(
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            label: 'Where to start',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'All tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Sessions',
          ),
        ],
      ),
    );
  }
}
