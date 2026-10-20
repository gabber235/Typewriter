import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("a page shows its workspace beside its Book's outline", (
    tester,
  ) async {
    await _pump(tester, _page);

    final rail = tester.widget<AuthoredResourceNavigator>(
      find.byType(AuthoredResourceNavigator),
    );
    expect(rail.resource, _book);
    expect(rail.routedResource, _page);
    final main = tester.widget<AuthoredResourceInspection>(
      find.byType(AuthoredResourceInspection),
    );
    expect(main.role, skir.PresentationRole.workspace);
    expect(_container(tester).read(showsSideInspectorProvider(_scope)), isTrue);
  });

  testWidgets(
    "a Book without a workspace shows its inspector in the main area",
    (tester) async {
      await _pump(tester, _book);

      final main = tester.widget<AuthoredResourceInspection>(
        find.byType(AuthoredResourceInspection),
      );
      expect(main.role, skir.PresentationRole.inspector);
      expect(
        tester
            .widget<AuthoredResourceNavigator>(
              find.byType(AuthoredResourceNavigator),
            )
            .resource,
        _book,
      );
      expect(find.text("New page"), findsOneWidget);
      expect(
        _container(tester).read(showsSideInspectorProvider(_scope)),
        isFalse,
      );
    },
  );

  testWidgets("a section has no rail and offers to create its members", (
    tester,
  ) async {
    await _pump(tester, fixtureLibraryId);

    expect(find.byType(AuthoredResourceNavigator), findsNothing);
    expect(find.text("New book"), findsOneWidget);
  });
}

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:route"),
  realmId: skir.recordId("realm:route"),
);
final _book = skir.ResourceId(value: "book:route");
final _page = skir.ResourceId(value: "page:route");

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ResourceSurface)));

Future<void> _pump(WidgetTester tester, skir.ResourceId resource) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final document = fixtureAuthoringDocument(
    realm: true,
    books: [
      Book(bookId: _book, title: "Route", icon: "mdi:book", color: Colors.blue),
    ],
    pages: [Page(pageId: _page, bookId: _book, name: "Intro")],
  );
  await tester.pumpTestApp(
    overrides: [
      organizationIdProvider.overrideWith((_) => _scope.organizationId),
      realmIdProvider.overrideWith((_) => _scope.realmId),
      routedResourceIdProvider.overrideWithValue(resource),
      ...authoringFixtureOverrides(scope: _scope, document: document),
    ],
    child: Scaffold(
      body: ResourceSurface(scope: _scope, resource: resource),
    ),
  );
}
