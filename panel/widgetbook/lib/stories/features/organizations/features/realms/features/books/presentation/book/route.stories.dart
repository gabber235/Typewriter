import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: BookPage)
Widget bookPageUseCase(BuildContext context) {
  final pagesState = context.knobs.displayState(
    label: "Pages State",
    initialOption: DisplayState.manyItems,
  );
  final connectionState = context.knobs.realmConnectionState();

  return AuthoringFixtureApp(
    state: pagesState,
    scenario: pagesState,
    createDocument: () => fixtureAuthoringDocument(
      books: [_storyBook],
      pages: (pagesState.generateReady(generateRandomPage) ?? const <Page>[])
          .map((page) => page.copyWith(bookId: _storyBook.bookId)),
    ),
    overrides: [
      realmInteractionProvider.overrideWith(
        (ref) => RealmInteractionState(connectionState: connectionState),
      ),

      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...canonicalServicesProviderOverrides(state: DisplayState.manyItems),
      ...realmProviderOverrides(),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: EmptyBookPage()),
  );
}

final _storyBook = Book(
  bookId: skir.ResourceId(value: "example-book-id"),
  title: "Example Book",
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);
