/// The "where do I start?" router — the app's primary entry point.
library;

import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/tool_detail_screen.dart';
import 'package:untools/tools/guide.dart';
import 'package:untools/ui/theme.dart';

/// Lists symptoms of being stuck, each opening the tool that addresses it.
class GuideScreen extends StatelessWidget {
  /// Creates the guide screen.
  const GuideScreen({required this.repository, super.key});

  /// The session store, passed on to the tool detail screen.
  final SessionRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Where are you stuck?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
          child: Text(
            'Pick whichever sounds most like your situation. Each one opens '
            'a method built for exactly that shape of stuck.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final entry in guideQuestions)
          if (toolById(entry.toolId) case final tool?)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(entry.question),
                subtitle: Text('Use ${tool.name}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ToolDetailScreen(
                      tool: tool,
                      repository: repository,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
