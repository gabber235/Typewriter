import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

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

  testWidgets("a narrow surface opens its rail from a menu in the heading", (
    tester,
  ) async {
    await _pump(tester, _page, size: const Size(420, 900));

    expect(find.byType(AuthoredResourceNavigator), findsNothing);
    expect(find.byTooltip("Open Route"), findsOneWidget);
    final menu = Focus.of(tester.element(find.byIcon(Icons.menu_open)))
      ..requestFocus();
    await tester.pump();
    expect(menu.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final rail = tester.widget<AuthoredResourceNavigator>(
      find.byType(AuthoredResourceNavigator),
    );
    expect(rail.resource, _book);
    expect(rail.routedResource, _page);
  });

  testWidgets("the creation shortcut works with focus in the surface body", (
    tester,
  ) async {
    await _pump(tester, _book);
    expect(_container(tester).read(_bookPages), hasLength(1));
    final body = find.byType(AuthoredResourceInspection);
    tester
        .widgetList<Focus>(
          find.descendant(of: body, matching: find.byType(Focus)),
        )
        .firstWhere((focus) => focus.focusNode?.canRequestFocus ?? false)
        .focusNode!
        .requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();

    expect(_container(tester).read(_bookPages), hasLength(2));
  });

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

/// The resources the routed Book owns.
final _bookPages = Provider(
  (ref) =>
      ref
          .watch(workingAuthoringDocumentProvider(_scope))
          .requireValue
          .relations
          .children[_book] ??
      const <skir.ResourceId>[],
);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ResourceSurface)));

Future<void> _pump(
  WidgetTester tester,
  skir.ResourceId resource, {
  Size size = const Size(1600, 1000),
}) async {
  tester.view.physicalSize = size;
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
