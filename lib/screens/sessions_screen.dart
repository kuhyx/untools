/// Saved sessions, most recently edited first.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/session_screen.dart';

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
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final tool = toolById(session.toolId);
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(session.title),
                // A tool can be retired while its sessions live on, so the
                // name is resolved defensively rather than assumed present.
                subtitle: Text(tool?.name ?? 'Unknown tool'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete session',
                  onPressed: () => repository.delete(session.id),
                ),
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
              ),
            );
          },
        );
      },
    );
  }
}
