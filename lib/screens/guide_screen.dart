/// The "where do I start?" router — the app's primary entry point.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/tool_detail_screen.dart';
import 'package:untools/tools/guide.dart';
import 'package:untools/ui/category_chips.dart';
import 'package:untools/ui/text_tile.dart';

/// Lists symptoms of being stuck, each opening the tool that addresses it.
///
/// A chip picks the category of tool, so the questions shown are one page of
/// tiles rather than a 27-row scroll.
class GuideScreen extends StatefulWidget {
  /// Creates the guide screen.
  const GuideScreen({required this.repository, super.key});

  /// The session store, passed on to the tool detail screen.
  final SessionRepository repository;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  ToolCategory _category = ToolCategory.values.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = [
      for (final entry in guideQuestions)
        if (toolById(entry.toolId) case final tool?
            when tool.primary == _category)
          (question: entry.question, tool: tool),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            'Where are you stuck?',
            style: theme.textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kProseMaxWidth),
            child: Text(
              'Pick whichever sounds most like your situation. Each one opens '
              'a method built for exactly that shape of stuck.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CategoryChips(
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: FitGrid(
            key: ValueKey(_category),
            itemCount: entries.length,
            columns: 2,
            minSquare: 0.6,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return TextTile(
                title: entry.question,
                caption: 'Use ${entry.tool.name}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ToolDetailScreen(
                      tool: entry.tool,
                      repository: widget.repository,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
