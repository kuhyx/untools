/// Browse the whole catalogue, grouped by category.
library;

import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/tool_detail_screen.dart';
import 'package:untools/ui/theme.dart';

/// Lists every registered tool under its category heading.
class ToolIndexScreen extends StatelessWidget {
  /// Creates the index screen.
  const ToolIndexScreen({required this.repository, super.key});

  /// The session store, passed on to the tool detail screen.
  final SessionRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final category in ToolCategory.values)
          if (toolsInCategory(category) case final tools
              when tools.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Text(category.label, style: theme.textTheme.titleMedium),
            ),
            for (final tool in tools)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(tool.name),
                  subtitle: Text(
                    tool.blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      ],
    );
  }
}
