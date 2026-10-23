import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  testWidgets("a grid lays out every member as a card", (tester) async {
    await _pump(tester, fixtureLibraryId, skir.PresentationRole.workspace);

    expect(find.byType(GridView), findsOneWidget);
    expect(_chrome("Atlas"), findsOneWidget);
    expect(_chrome("Zebra"), findsOneWidget);
    expect(
      tester.widget<ResourceItemChrome>(_chrome("Atlas")).density,
      ResourceItemDensity.card,
    );
  });

  testWidgets("a list lays out the members of the root navigator as rows", (
    tester,
  ) async {
    await _pump(tester, fixtureRealmRootId, skir.PresentationRole.navigator);

    final rows = find.byType(ResourceItemChrome);
    expect(rows, findsNWidgets(2));
    expect(
      tester.widgetList<ResourceItemChrome>(rows).map((row) => row.density),
      everyElement(ResourceItemDensity.row),
    );
  });

  testWidgets("a tree groups members by their hierarchy path", (tester) async {
    await _pump(tester, _book, skir.PresentationRole.navigator);

    // Group headers render the declared group node bound to each group.
    expect(find.text("act1"), findsOneWidget);
    expect(find.text("intro"), findsOneWidget);
    expect(find.text("New page"), findsNWidgets(2));
    // Members at every depth, ordered by the declared order key.
    expect(_chrome("Opening"), findsOneWidget);
    expect(_chrome("Scene"), findsOneWidget);
    expect(_chrome("Loose"), findsOneWidget);
    expect(
      tester.getTopLeft(_chrome("Scene")).dy,
      greaterThan(tester.getTopLeft(find.text("intro")).dy),
    );
    expect(
      tester.getTopLeft(_chrome("Scene")).dx,
      greaterThan(tester.getTopLeft(_chrome("Opening")).dx),
    );

    await tester.tap(find.byTooltip("Collapse act1"));
    await tester.pumpAndSettle();

    expect(find.text("intro"), findsNothing);
    expect(_chrome("Opening"), findsNothing);
    expect(_chrome("Scene"), findsNothing);
    expect(_chrome("Loose"), findsOneWidget);

    await tester.tap(find.byTooltip("Expand act1"));
    await tester.pumpAndSettle();
    expect(_chrome("Scene"), findsOneWidget);
  });

  testWidgets("a member dropped onto a group header moves into that group", (
    tester,
  ) async {
    final container = await _pumpEditable(tester);
    await _drag(tester, _chrome("Loose"), find.text("intro"));
    expect(_chapter(container, _loose), "act1.intro");
  });

  testWidgets(
    "a dragged group header carries its members below the target group",
    (tester) async {
      final container = await _pumpEditable(tester);
      await _drag(tester, find.text("intro"), find.text("act2"));
      expect(_chapter(container, _scene), "act2.intro");
      expect(_chapter(container, _opening), "act1");

      await _drag(tester, find.text("act2"), find.text("intro"));
      expect(_chapter(container, _scene), "act2.intro");
    },
  );

  testWidgets("the routed member carries the routed interaction state", (
    tester,
  ) async {
    await _pump(tester, _book, skir.PresentationRole.navigator, routed: _scene);

    PresentationInteraction interaction(String label) =>
        PresentationInteractionScope.of(tester.element(_chrome(label)));
    expect(interaction("Scene").routed, isTrue);
    expect(interaction("Opening").routed, isFalse);
    expect(interaction("Loose").routed, isFalse);
  });
}

final _book = skir.ResourceId(value: "book:a");
final _opening = skir.ResourceId(value: "page:a");
final _scene = skir.ResourceId(value: "page:b");
final _loose = skir.ResourceId(value: "page:c");
final _later = skir.ResourceId(value: "page:d");

Finder _chrome(String label) => find.byWidgetPredicate(
  (widget) => widget is ResourceItemChrome && widget.appearance.label == label,
);

String? _chapter(ProviderContainer container, skir.ResourceId page) {
  final scope = container.read(selectedAuthoringScopeProvider)!;
  return container
      .read(realmEditingProvider(scope))
      .document
      .textAt(page, editorRootPath.field("chapter"));
}

Future<void> _drag(WidgetTester tester, Finder source, Finder target) async {
  final gesture = await tester.startGesture(tester.getCenter(source.first));
  await gesture.moveBy(const Offset(30, 0));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target.first));
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// The Atlas chapter tree, editable through the realm workspace.
Future<ProviderContainer> _pumpEditable(WidgetTester tester) async {
  await tester.pumpTestApp(
    overrides: [
      realmInteractionProvider.overrideWithValue(
        const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      ...authoringFixtureOverrides(
        document: _document(
          extra: [
            Page(pageId: _later, bookId: _book, name: "Later", chapter: "act2"),
          ],
        ),
      ),
    ],
    child: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: HookConsumer(
          builder: (context, ref, _) {
            final scope = ref.watch(selectedAuthoringScopeProvider)!;
            final workspace = ref.watch(realmEditingProvider(scope));
            useListenable(workspace);
            final binding = useMemoized(
              () => workspace.attach(
                _book,
                policy: EditorCommitPolicy.applyResource,
              ),
              [workspace],
            );
            useEffect(() => binding.detach, [binding]);
            return AuthoredResourceEditor(
              resource: _book,
              document: workspace.document,
              edit: binding,
              role: skir.PresentationRole.navigator,
              budget: skir.EvaluationBudget(
                maxSteps: 1000,
                maxCollectionItems: 100,
              ),
              fillAvailableSpace: true,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.container();
}

AuthoringDocument _document({
  List<Page> extra = const [],
}) => fixtureAuthoringDocument(
  realm: true,
  books: [
    Book(bookId: _book, title: "Atlas", icon: "mdi:book", color: Colors.blue),
    Book(
      bookId: skir.ResourceId(value: "book:z"),
      title: "Zebra",
      icon: "mdi:book",
      color: Colors.blue,
    ),
  ],
  pages: [
    Page(pageId: _loose, bookId: _book, name: "Loose"),
    Page(pageId: _scene, bookId: _book, name: "Scene", chapter: "act1.intro"),
    Page(pageId: _opening, bookId: _book, name: "Opening", chapter: "act1"),
    ...extra,
  ],
);

Future<void> _pump(
  WidgetTester tester,
  skir.ResourceId resource,
  skir.PresentationRole role, {
  skir.ResourceId? routed,
}) async {
  final document = _document();
  await tester.pumpTestApp(
    overrides: authoringFixtureOverrides(document: document),
    child: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: AuthoredResourceEditor(
          resource: resource,
          document: document,
          role: role,
          routedResource: routed,
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 100,
          ),
          fillAvailableSpace: true,
        ),
      ),
    ),
  );
}
