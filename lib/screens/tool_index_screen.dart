/// Browse the whole catalogue, one category at a time.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/data/session_repository.dart';
import 'package:untools/model/tool_config.dart';
import 'package:untools/model/tool_registry.dart';
import 'package:untools/screens/tool_detail_screen.dart';
import 'package:untools/ui/category_chips.dart';
import 'package:untools/ui/text_tile.dart';

/// Shows the tools of the chosen category as a paged tile grid that always
/// fits one screen; the blurb sits behind a long-press.
class ToolIndexScreen extends StatefulWidget {
  /// Creates the index screen.
  const ToolIndexScreen({required this.repository, super.key});

  /// The session store, passed on to the tool detail screen.
  final SessionRepository repository;

  @override
  State<ToolIndexScreen> createState() => _ToolIndexScreenState();
}

class _ToolIndexScreenState extends State<ToolIndexScreen> {
  ToolCategory _category = ToolCategory.values.first;

  @override
  Widget build(BuildContext context) {
    final tools = toolsInCategory(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        CategoryChips(
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          // Keyed so a new category starts on its first page.
          child: FitGrid(
            key: ValueKey(_category),
            itemCount: tools.length,
            minSquare: 0.8,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return TextTile(
                title: tool.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ToolDetailScreen(
                      tool: tool,
                      repository: widget.repository,
                    ),
                  ),
                ),
                onLongPress: () => showDetailSheet(
                  context,
                  title: tool.name,
                  body: tool.blurb,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
