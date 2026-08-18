import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("unsafe SVG icon renders a safe fallback", (tester) async {
    await tester.pumpTestApp(
      child: const Icones.value(
        IconValue.svg('<svg><script>alert("x")</script></svg>'),
      ),
    );

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });

  group("AdaptiveLeadingLayout via EntryNode", () {
    late ElementDefinition testBlueprint;

    setUp(() {
      testBlueprint = ElementDefinition(
        rootType: ResolvedTypeRef(
          id: const QualifiedTypeId(namespace: "test", name: "test_blueprint"),
          revision: 1,
        ),
        name: "Test Blueprint",
        description: "A test elementDefinition",
        icon: const IconValue.iconify("star"),
        color: Colors.green,
      );
    });

    group("visibility", () {
      testWidgets("shows icon and text when there is enough space", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 300,
              height: 50,
              child: Material(
                child: EntryNode(
                  entry: PageEntry.definition(
                    definition: EntryDefinition(
                      id: "test-entry",
                      name: "Test Entry",
                      elementDefinition: testBlueprint,
                      placement: const EntryPlacement(
                        x: 0,
                        y: 0,
                        width: 6,
                        height: 1,
                      ),
                      data: RecordValue(const {}),
                      inwardEdges: const [],
                      outwardEdges: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Icones), findsOneWidget);
        expect(find.text("Test Entry"), findsOneWidget);
      });

      testWidgets("shows only icon in compact mode", (tester) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                child: EntryNode(
                  entry: PageEntry.definition(
                    definition: EntryDefinition(
                      id: "test-entry",
                      name: "Test Entry",
                      elementDefinition: testBlueprint,
                      placement: const EntryPlacement(
                        x: 0,
                        y: 0,
                        width: 1,
                        height: 1,
                      ),
                      data: RecordValue(const {}),
                      inwardEdges: const [],
                      outwardEdges: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Icones), findsOneWidget);
      });

      testWidgets("shows suffix icon for reference entries with enough space", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 300,
              height: 50,
              child: Material(
                child: EntryNode(
                  entry: PageEntry.reference(
                    id: "ref-entry",
                    name: "Reference Entry",
                    elementDefinition: testBlueprint,
                    pageId: "other-page",
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Icones), findsOneWidget);
        expect(find.text("Reference Entry"), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });
    });

    group("positioning", () {
      testWidgets("icon is horizontally centered in compact mode", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Material(
                color: Colors.green,
                child: EntryNode(
                  entry: PageEntry.definition(
                    definition: EntryDefinition(
                      id: "test-entry",
                      name: "Test Entry",
                      elementDefinition: testBlueprint,
                      placement: const EntryPlacement(
                        x: 0,
                        y: 0,
                        width: 1,
                        height: 1,
                      ),
                      data: RecordValue(const {}),
                      inwardEdges: const [],
                      outwardEdges: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final iconFinder = find.byType(Icones);
        expect(iconFinder, findsOneWidget);

        final iconBox = tester.renderObject(iconFinder) as RenderBox;
        final iconOffset = iconBox.localToGlobal(Offset.zero);
        final iconCenter = iconOffset.dx + iconBox.size.width / 2;

        final materialFinder = find.byType(Material).first;
        final materialBox = tester.renderObject(materialFinder) as RenderBox;
        final materialOffset = materialBox.localToGlobal(Offset.zero);
        final materialCenter = materialOffset.dx + materialBox.size.width / 2;

        expect(iconCenter, closeTo(materialCenter, 5.0));
      });

      testWidgets("children are vertically centered", (tester) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 300,
              height: 80,
              child: Material(
                color: Colors.green,
                child: EntryNode(
                  entry: PageEntry.definition(
                    definition: EntryDefinition(
                      id: "test-entry",
                      name: "Test Entry",
                      elementDefinition: testBlueprint,
                      placement: const EntryPlacement(
                        x: 0,
                        y: 0,
                        width: 6,
                        height: 1,
                      ),
                      data: RecordValue(const {}),
                      inwardEdges: const [],
                      outwardEdges: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final iconFinder = find.byType(Icones);
        expect(iconFinder, findsOneWidget);

        final iconBox = tester.renderObject(iconFinder) as RenderBox;
        final iconOffset = iconBox.localToGlobal(Offset.zero);
        final iconVerticalCenter = iconOffset.dy + iconBox.size.height / 2;

        final materialFinder = find.byType(Material).first;
        final materialBox = tester.renderObject(materialFinder) as RenderBox;
        final materialOffset = materialBox.localToGlobal(Offset.zero);
        final materialVerticalCenter =
            materialOffset.dy + materialBox.size.height / 2;

        expect(iconVerticalCenter, closeTo(materialVerticalCenter, 5.0));
      });
    });

    group("text ellipsis", () {
      testWidgets("shows ellipsis for long text when constrained", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 150,
              height: 50,
              child: Material(
                child: EntryNode(
                  entry: PageEntry.definition(
                    definition: EntryDefinition(
                      id: "test-entry",
                      name:
                          "This is a very long entry name that should be truncated",
                      elementDefinition: testBlueprint,
                      placement: const EntryPlacement(
                        x: 0,
                        y: 0,
                        width: 3,
                        height: 1,
                      ),
                      data: RecordValue(const {}),
                      inwardEdges: const [],
                      outwardEdges: const [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Icones), findsOneWidget);
        final textFinder = find.textContaining("This is a very long");
        expect(textFinder, findsOneWidget);
      });
    });

    group("error entries", () {
      testWidgets("NonexistentEntryNode uses adaptive layout", (tester) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 300,
              height: 50,
              child: Material(
                child: EntryNode(
                  entry: const PageEntry.nonexistent(id: "missing"),
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text("Non-existent entry"), findsOneWidget);
      });

      testWidgets("missing definition entry uses adaptive layout", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: SizedBox(
              width: 300,
              height: 50,
              child: Material(
                child: EntryNode(
                  entry: PageEntry.missingElementDefinition(
                    id: "no-elementDefinition",
                    name: "Entry Without Element Definition",
                    placement: EntryPlacement(x: 0, y: 0, width: 6, height: 1),
                    inwardLinks: [],
                    outwardLinks: [],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text("Entry Without Element Definition"), findsOneWidget);
      });
    });

    group("layout updates", () {
      testWidgets("updates layout when width changes", (tester) async {
        final widthNotifier = ValueNotifier<double>(300);

        await tester.pumpTestApp(
          child: GraphDrag(
            draggingInsideGraph: ValueNotifier(false),
            child: ValueListenableBuilder<double>(
              valueListenable: widthNotifier,
              builder: (context, width, _) {
                return SizedBox(
                  width: width,
                  height: 50,
                  child: Material(
                    color: Colors.green,
                    child: EntryNode(
                      entry: PageEntry.definition(
                        definition: EntryDefinition(
                          id: "test-entry",
                          name: "Test Entry",
                          elementDefinition: testBlueprint,
                          placement: const EntryPlacement(
                            x: 0,
                            y: 0,
                            width: 6,
                            height: 1,
                          ),
                          data: RecordValue(const {}),
                          inwardEdges: const [],
                          outwardEdges: const [],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text("Test Entry"), findsOneWidget);

        widthNotifier.value = 40;
        await tester.pumpAndSettle();

        expect(find.byType(Icones), findsOneWidget);
      });
    });
  });
}
