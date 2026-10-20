import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/tag_inheritance_presentation.stories.dart";

void main() {
  for (final book in [true, false]) {
    testWidgets(
      "compiled inheritance story opens the ${book ? 'Book' : 'Tag'} inspector",
      (tester) async {
        final root = skir.ResourceId(value: "tag:root");
        final first = skir.ResourceId(value: "tag:first");
        final second = skir.ResourceId(value: "tag:second");
        Tag tag(
          skir.ResourceId id,
          String name,
          List<skir.ResourceId> parents,
        ) => Tag(
          tagId: id,
          name: name,
          color: Colors.blue,
          parentIds: parents,
          placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
        );
        await tester.pumpWidget(
          tagInheritanceStory(
            book: book,
            roots: [root],
            tags: [
              tag(root, "Quest", [first, second]),
              tag(first, "Story", []),
              tag(second, "Region", []),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AuthoredResourceInspection), findsOneWidget);
        final section = find.byKey(
          ValueKey(book ? "effective-tags" : "inheritance"),
        );
        expect(section, findsOneWidget);
        final disclosure = find.descendant(
          of: section,
          matching: find.byTooltip("Expand"),
        );
        expect(disclosure, findsOneWidget);
        await tester.ensureVisible(disclosure);
        await tester.tap(disclosure);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: section, matching: find.text("Story")),
          findsOneWidget,
        );
        expect(
          find.descendant(of: section, matching: find.text("Region")),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
