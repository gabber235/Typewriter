import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "support/editor_utils.dart";

void main() {
  testWidgets(
    "reuses definitions for drafts and replaces them with documents",
    (tester) async {
      final source = TestEditorSource(
        rootType: const StringType(),
        value: const StringValue("Before"),
      );
      addTearDown(source.dispose);
      await tester.pumpTestApp(
        child: Material(child: EditorSurface(source: source)),
      );

      expect(find.text("Before"), findsOneWidget);
      final initialRegistry = tester
          .widget<PresentationSurface>(find.byType(PresentationSurface))
          .scope
          .registry;

      source.update(DataPath.root, const StringValue("After"));
      await tester.pump();

      expect(find.text("After"), findsOneWidget);
      expect(find.text("Before"), findsNothing);
      final updatedRegistry = tester
          .widget<PresentationSurface>(find.byType(PresentationSurface))
          .scope
          .registry;
      expect(updatedRegistry, same(initialRegistry));

      source.refreshDocument(
        source.document.copyWith(
          confirmedValue: const StringValue("Remote"),
          revision: 1,
        ),
      );
      await tester.pump();

      expect(find.text("Remote"), findsOneWidget);
      final refreshedRegistry = tester
          .widget<PresentationSurface>(find.byType(PresentationSurface))
          .scope
          .registry;
      expect(refreshedRegistry, isNot(same(updatedRegistry)));
    },
  );
}
