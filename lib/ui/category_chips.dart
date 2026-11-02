/// The category filter shared by the screens that fit a list to one page.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:untools/model/tool_config.dart';

/// A wrapping row of chips, one per [ToolCategory], exactly one selected.
class CategoryChips extends StatelessWidget {
  /// Creates the chip row.
  const CategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The category currently shown.
  final ToolCategory selected;

  /// Called when the user picks a different category.
  final ValueChanged<ToolCategory> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final category in ToolCategory.values)
          ChoiceChip(
            label: Text(category.label),
            selected: category == selected,
            onSelected: (_) => onSelected(category),
          ),
      ],
    ),
  );
}
