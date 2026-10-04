import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages(
    "graph page stays within a narrow Widgetbook canvas",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const FakeApp(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 550,
              height: 720,
              child: PageWorkspaceStory(timeline: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Graph), findsOneWidget);
      expect(find.byType(AuthoredResourceEditor), findsOneWidget);
      expect(find.text("Reward"), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
