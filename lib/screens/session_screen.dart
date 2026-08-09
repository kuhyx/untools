/// Dispatches a session to the pattern widget its tool calls for.
///
/// This and `session_markdown.dart` are the only two places that switch over
/// the sealed [ToolConfig]. Because the type is sealed and there is no
/// `default:` arm, adding a ninth pattern fails to compile here until it is
/// handled — which is the point.
library;

import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/export/session_markdown.dart';
import 'package:untools/export/share_target.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/patterns/graph/graph_view.dart';
import 'package:untools/patterns/grid/grid_view.dart';
import 'package:untools/patterns/ladder/ladder_view.dart';
import 'package:untools/patterns/lens/lens_view.dart';
import 'package:untools/patterns/loop/loop_view.dart';
import 'package:untools/patterns/matrix/matrix_view.dart';
import 'package:untools/patterns/tree/tree_view.dart';
import 'package:untools/patterns/wizard/wizard_view.dart';
import 'package:untools/ui/theme.dart';

/// Hosts one session: the pattern widget, plus save and export.
class SessionScreen extends StatelessWidget {
  /// Creates the session screen.
  const SessionScreen({
    required this.sessionId,
    required this.tool,
    required this.repository,
    super.key,
    this.share = shareMarkdown,
  });

  /// Which session is open.
  final String sessionId;

  /// The tool it is a session of.
  final ToolConfig tool;

  /// The session store.
  final SessionRepository repository;

  /// How exported Markdown leaves the app.
  ///
  /// Injected so tests can assert that the button renders the *right*
  /// document; the platform share sheet itself is unreachable on the test
  /// host and is excluded from coverage in its own file.
  final Future<void> Function(String markdown, {required String filename})
  share;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final session = repository.byId(sessionId);
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tool.name)),
            body: const Center(child: Text('This session was deleted.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(session.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Export as Markdown',
                onPressed: () => share(
                  sessionToMarkdown(session, tool),
                  filename: '${tool.id}.md',
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _body(session),
          ),
        );
      },
    );
  }

  Widget _body(Session session) {
    void save(Session updated) => repository.save(updated);

    switch (tool) {
      case final WizardConfig config:
        return WizardView(session: session, config: config, onChanged: save);
      case final MatrixConfig config:
        return MatrixView(session: session, config: config, onChanged: save);
      case final ScoredGridConfig config:
        return ScoredGridView(
          session: session,
          config: config,
          onChanged: save,
        );
      case final LadderConfig config:
        return LadderView(session: session, config: config, onChanged: save);
      case final LensConfig config:
        return LensView(session: session, config: config, onChanged: save);
      case final TreeConfig config:
        return TreeView(session: session, config: config, onChanged: save);
      case final GraphConfig config:
        return GraphView(session: session, config: config, onChanged: save);
      case final LoopConfig config:
        return LoopView(session: session, config: config, onChanged: save);
    }
  }
}
