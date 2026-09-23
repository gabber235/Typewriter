import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_result_items.stories.dart";
import "package:widgetbook_workspace/stories/shared/search/presentation/primary_search.stories.dart";

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages(
    "primary search story opens without a live Realm connection",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        primarySearchButtonStory(searchDelay: Duration.zero),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimarySearchButton));
      await tester.pumpAndSettle();

      expect(find.byType(AuthoringSearchResultItem), findsWidgets);
      expect(find.textContaining("NATS"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgetsWithNetworkImages(
    "authoring result gallery renders every result kind",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(authoringSearchResultGalleryStory());
      await tester.pumpAndSettle();

      expect(find.byType(AuthoringSearchResultItem), findsNWidgets(4));
      expect(find.text("Main Quest"), findsWidgets);
      expect(find.text("Meet the Mayor"), findsOneWidget);
      expect(
        find.textContaining("old bridge", findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
