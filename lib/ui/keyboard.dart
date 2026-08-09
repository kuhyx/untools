/// Keyboard affordances shared by every screen.
///
/// The design system treats pointer-free operability as a hard requirement,
/// not an accessibility extra: every action must be reachable and activatable
/// with the keyboard alone, focus must be visible, and Enter/Escape must do
/// the obvious thing. The drag-based patterns are the ones that break this by
/// default, so they get an explicit keyboard path built alongside the drag
/// rather than bolted on afterwards.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] so Escape invokes [onCancel] and Enter invokes [onSubmit].
///
/// Both are optional; an unset intent falls through to the enclosing scope
/// rather than being swallowed.
class SubmitCancelShortcuts extends StatelessWidget {
  /// Creates the shortcut wrapper.
  const SubmitCancelShortcuts({
    required this.child,
    super.key,
    this.onSubmit,
    this.onCancel,
  });

  /// The subtree these shortcuts apply to.
  final Widget child;

  /// Invoked on Enter.
  final VoidCallback? onSubmit;

  /// Invoked on Escape.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): ?onSubmit,
        const SingleActivator(LogicalKeyboardKey.escape): ?onCancel,
      },
      child: child,
    );
  }
}

/// The focus ring drawn around a focused, non-text control.
///
/// Platform defaults are wrong on this palette — a black ring vanishes against
/// the dark surface — so the accent colour is set explicitly.
BoxDecoration focusRing(BuildContext context, {required bool focused}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: focused ? scheme.primary : Colors.transparent,
      width: 2,
    ),
  );
}
