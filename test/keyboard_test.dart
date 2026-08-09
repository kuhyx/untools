import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untools/ui/keyboard.dart';

/// The design system treats pointer-free operability as a hard requirement,
/// so these helpers are load-bearing rather than polish and get real tests
/// instead of a coverage exemption.
void main() {
  group('SubmitCancelShortcuts', () {
    testWidgets('Enter invokes onSubmit', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SubmitCancelShortcuts(
            onSubmit: () => submitted++,
            child: const Focus(autofocus: true, child: SizedBox()),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(submitted, 1);
    });

    testWidgets('Escape invokes onCancel', (tester) async {
      var cancelled = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SubmitCancelShortcuts(
            onCancel: () => cancelled++,
            child: const Focus(autofocus: true, child: SizedBox()),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(cancelled, 1);
    });

    testWidgets('an unset intent is not swallowed', (tester) async {
      // Binding only one of the two must leave the other key free to reach an
      // enclosing scope, rather than being absorbed silently.
      var outerEscapes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  outerEscapes++,
            },
            child: SubmitCancelShortcuts(
              onSubmit: () {},
              child: const Focus(autofocus: true, child: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(outerEscapes, 1);
    });
  });

  group('focusRing', () {
    testWidgets('is drawn in the accent colour when focused', (tester) async {
      // The platform default is a black ring, which is invisible against the
      // dark surface — hence setting it explicitly.
      late BoxDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFB8862E)),
          ),
          home: Builder(
            builder: (context) {
              decoration = focusRing(context, focused: true);
              return const SizedBox();
            },
          ),
        ),
      );

      final border = decoration.border! as Border;
      expect(border.top.color, const Color(0xFFB8862E));
      expect(border.top.width, 2);
    });

    testWidgets('is transparent when unfocused, not absent', (tester) async {
      // A transparent border of the same width keeps the layout from shifting
      // as focus moves, which is otherwise a visible jitter down the ring.
      late BoxDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              decoration = focusRing(context, focused: false);
              return const SizedBox();
            },
          ),
        ),
      );

      final border = decoration.border! as Border;
      expect(border.top.color, Colors.transparent);
      expect(border.top.width, 2);
    });
  });
}
