import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "package:widgetbook_workspace/stories/authoring/search/presentation/compiled_search_fixture.dart";

import "support/network_images.dart";

void main() {
  for (final kind in ["book", "page", "element"]) {
    testWidgetsWithNetworkImages(
      "compiled $kind result renders its real SDK recipe",
      (tester) async {
        final fixture = CompiledSearchFixture();
        await _pump(tester, fixture.document, fixture.ids[kind]!);
        expect(find.byType(SearchResultCard), findsOneWidget);
        expect(
          find.text(fixture.labels[kind]!),
          findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data ?? text.textSpan?.toPlainText())
              .join(" | "),
        );
        expect(find.text("Main Quest"), findsOneWidget);
        if (kind == "book") {
          expect(find.text("Quest tag"), findsOneWidget);
        } else {
          expect(find.text("Village"), findsOneWidget);
          // The host chrome names the kind from the type display.
          expect(_kind(tester), kind == "page" ? "Dialogue page" : "Speaker");
        }
        if (kind == "element") {
          expect(find.text("Meet the Mayor"), findsOneWidget);
        }
        expect(find.textContaining("could not be checked"), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgetsWithNetworkImages(
    "compiled location details fit narrow rows at enlarged text",
    (tester) async {
      final fixture = CompiledSearchFixture();
      for (final kind in ["page", "element"]) {
        await _pump(
          tester,
          fixture.document,
          fixture.ids[kind]!,
          width: 300,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgetsWithNetworkImages(
    "compiled element follows local related rename and caller origin",
    (tester) async {
      final fixture = CompiledSearchFixture();
      await _pump(tester, fixture.document, fixture.ids["element"]!);
      expect(find.text("Main Quest"), findsOneWidget);
      final edit = AuthoringEdit.fromDocument(fixture.document)
        ..set(
          skir.ValueLocation(
            resource: fixture.ids["book"]!,
            path: _path("title"),
          ),
          skir.DataValue.wrapStringValue("Renamed quest"),
        );
      await _pump(
        tester,
        edit.toDocument(revision: 1),
        fixture.ids["element"]!,
      );
      expect(find.text("Renamed quest"), findsOneWidget);
      expect(find.text("Main Quest"), findsNothing);
      await _pump(
        tester,
        fixture.document,
        fixture.ids["element"]!,
        origin: fixture.ids["page"],
      );
      expect(_kind(tester), "Speaker");
      expect(find.text("Main Quest"), findsNothing);
      expect(find.text("Village"), findsNothing);
      expect(find.text("Meet the Mayor"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgetsWithNetworkImages(
    "compiled book exposes missing tag data in its clipped chip row",
    (tester) async {
      final fixture = CompiledSearchFixture();
      final document = fixture.document.copyWith(
        entries: {...fixture.document.entries}..remove(fixture.ids["tag"]),
      );
      await _pump(tester, document, fixture.ids["book"]!, width: 240);
      expect(find.text("Unavailable tag"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

String _kind(WidgetTester tester) =>
    tester.widget<SearchResultSuffix>(find.byType(SearchResultSuffix)).label;

Future<void> _pump(
  WidgetTester tester,
  AuthoringDocument document,
  skir.ResourceId resource, {
  skir.ResourceId? origin,
  double width = 360,
  double textScale = 1,
}) async {
  final configuration = document.resource(resource)!.configuration;
  final selection = document.catalog.selectPresentation(
    configuration,
    skir.PresentationRole.resourceSearchResult,
  );
  expect(selection, isA<SelectedEditorPresentation>());
  await tester.pumpWidget(
    FakeApp(
      child: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: AuthoredResourceSearchResult(
              document: document,
              issues: ResourceIssues.evaluate(document: document),
              hostContext: HostContext(activeResource: origin),
              resource: resource,
              role: skir.PresentationRole.resourceSearchResult,
              density: SearchResultDensity.card,
              fallbackLabel: "Missing recipe",
              row: SearchResultRowContext(
                result: SearchResult(
                  id: resource.value,
                  type: authoringResourceSearchResultType,
                  payload: resource,
                ),
                selected: false,
                focused: false,
                loading: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

skir.ValuePath _path(String field) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]);
