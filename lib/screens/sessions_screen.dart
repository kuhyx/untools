/// Saved sessions, most recently edited first.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/session_screen.dart';
import 'package:untools/ui/text_tile.dart';

/// Lists every saved session and reopens one on tap.
class SessionsScreen extends StatelessWidget {
  /// Creates the sessions screen.
  const SessionsScreen({required this.repository, super.key});

  /// The session store.
  final SessionRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final sessions = repository.sessions;
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Nothing saved yet. Start a tool and it will show up here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return FitGrid(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: sessions.length,
          columns: 2,
          minSquare: 0.6,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final tool = toolById(session.toolId);
            // A tool can be retired while its sessions live on, so the
            // name is resolved defensively rather than assumed present.
            final toolName = tool?.name ?? 'Unknown tool';
            return TextTile(
              title: session.title,
              caption: toolName,
              onTap: tool == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SessionScreen(
                          sessionId: session.id,
                          tool: tool,
                          repository: repository,
                        ),
                      ),
                    ),
              onLongPress: () => showDetailSheet(
                context,
                title: session.title,
                body: toolName,
                actions: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete session'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await repository.delete(session.id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
