/// A dense tappable tile and the sheet that holds what it leaves out.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A card with a title and an optional caption, sized by its grid cell.
///
/// Tap opens the item; long-press is where secondary detail and actions
/// live, so nothing is dropped by fitting the list on one screen.
class TextTile extends StatelessWidget {
  /// Creates a tile.
  const TextTile({
    required this.title,
    required this.onTap,
    this.caption,
    this.onLongPress,
    super.key,
  });

  /// Main label, wrapped over a few lines.
  final String title;

  /// One line under the title, e.g. the tool a session belongs to.
  final String? caption;

  /// Opens the item.
  final VoidCallback? onTap;

  /// Opens the detail sheet.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              if (caption case final caption?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [title], optional [body] text and [actions] in a bottom sheet.
Future<void> showDetailSheet(
  BuildContext context, {
  required String title,
  String? body,
  List<Widget> actions = const [],
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (body case final body?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
            ...actions,
          ],
        ),
      ),
    );
  },
);
