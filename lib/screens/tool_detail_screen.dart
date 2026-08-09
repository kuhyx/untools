/// What a tool is, who devised it, and the button that starts a session.
library;

import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/session.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/session_screen.dart';
import 'package:untools/ui/theme.dart';
import 'package:uuid/uuid.dart';

/// Shows one tool's description, attribution and related tools.
class ToolDetailScreen extends StatelessWidget {
  /// Creates the detail screen.
  const ToolDetailScreen({
    required this.tool,
    required this.repository,
    super.key,
  });

  /// The tool being described.
  final ToolConfig tool;

  /// The session store.
  final SessionRepository repository;

  Future<void> _start(BuildContext context) async {
    final now = DateTime.now();
    final session = Session(
      id: const Uuid().v4(),
      toolId: tool.id,
      title: tool.name,
      createdAt: now,
      updatedAt: now,
      slots: const {},
    );
    await repository.save(session);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(
          sessionId: session.id,
          tool: tool,
          repository: repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final related = relatedTools(tool);
    return Scaffold(
      appBar: AppBar(title: Text(tool.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
            child: Text(tool.blurb, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          // No "Devised by" prefix: not every attribution is a person's name.
          // "Devised by Systems-thinking canon, in the Donella Meadows
          // lineage" reads as broken English, and it did on the phone. Each
          // attribution is written as a complete credit line instead.
          Text(
            tool.attribution,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => _start(context),
            child: const Text('Start a session'),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Try next', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final other in related)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(other.name),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ToolDetailScreen(
                        tool: other,
                        repository: repository,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
