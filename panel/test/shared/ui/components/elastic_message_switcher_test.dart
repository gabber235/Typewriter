import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  group("ElasticMessageSwitcher", () {
    testWidgets("switches messages with the message transition", (
      tester,
    ) async {
      const firstKey = ValueKey("first");
      const secondKey = ValueKey("second");
      final showSecond = ValueNotifier(false);

      await tester.pumpTestApp(
        child: AnimatedBuilder(
          animation: showSecond,
          builder: (context, _) {
            return ElasticMessageSwitcher(
              child: Text(
                showSecond.value ? "Second" : "First",
                key: showSecond.value ? secondKey : firstKey,
              ),
            );
          },
        ),
      );

      expect(find.byKey(firstKey), findsOneWidget);
      final animatedSize = tester.widget<AnimatedSize>(
        find.descendant(
          of: find.byType(ElasticMessageSwitcher),
          matching: find.byType(AnimatedSize),
        ),
      );
      expect(animatedSize.clipBehavior, Clip.hardEdge);

      showSecond.value = true;
      await tester.pump();

      expect(find.byKey(firstKey), findsOneWidget);
      expect(find.byKey(secondKey), findsOneWidget);
      expect(find.byType(ElasticMessageTransition), findsNWidgets(2));

      await tester.pump(const Duration(milliseconds: 421));

      expect(find.byKey(firstKey), findsNothing);
      expect(find.byKey(secondKey), findsOneWidget);
    });

    testWidgets("animates message removal", (tester) async {
      const messageKey = ValueKey("message");
      final visible = ValueNotifier(true);

      await tester.pumpTestApp(
        child: AnimatedBuilder(
          animation: visible,
          builder: (context, _) {
            return ElasticMessageSwitcher(
              child: visible.value
                  ? const Text("Message", key: messageKey)
                  : null,
            );
          },
        ),
      );

      visible.value = false;
      await tester.pump();

      expect(find.byKey(messageKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 181));

      expect(find.byKey(messageKey), findsNothing);
    });
  });
}
