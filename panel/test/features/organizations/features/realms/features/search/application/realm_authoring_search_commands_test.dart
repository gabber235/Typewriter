import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("publishes the Realm authoring selectors", () {
    expect(authoringSearchSelectors.map((selector) => selector.id), [
      "book",
      "page",
      "tag",
      "type",
    ]);
  });

  test("book command retains scope and typed payload", () async {
    final book = skir.AuthoringSearchBook(
      id: _id("book", "main"),
      title: "Main",
      icon: "mdi:book",
      color: skir.Color(argb: 0),
      tags: const [],
    );

    final searchResult = _result(authoringBookSearchResultType, book);
    final command = openAuthoringCommands(
      _organization,
      _realm,
    ).singleWhere((command) => command.id == openAuthoringBookCommandId);
    final result = await command.execute(
      const SearchCommandExecutionContext(
        prompts: UnsupportedSearchPromptHost(),
      ),
      _target(searchResult),
    );
    final effect = (result as SearchCommandResultCompleted).hostEffects.single;

    expect(effect, isA<OpenAuthoringBookEffect>());
    expect((effect as OpenAuthoringBookEffect).organizationId, _organization);
    expect(effect.realmId, _realm);
    expect(effect.bookId, book.id);
  });

  test("element command cannot emit a page or book effect", () async {
    final page = skir.AuthoringSearchPage(
      id: _id("page", "intro"),
      name: "Intro",
      kind: skir.PageKindRef(id: skir.PageKindId(value: "static"), revision: 1),
      book: skir.AuthoringSearchBookContext(
        id: _id("book", "main"),
        title: "Main",
      ),
      chapter: "quest.intro",
    );
    final element = skir.AuthoringSearchElement(
      id: _id("element", "greeting"),
      name: "Greeting",
      elementType: "typewriter:dialogue",
      placement: skir.ElementPlacement.createGraph(
        x: 0,
        y: 0,
        width: 2,
        height: 1,
      ),
      page: page,
      match: null,
    );

    final searchResult = _result(authoringElementSearchResultType, element);
    final command = openAuthoringCommands(
      _organization,
      _realm,
    ).singleWhere((command) => command.id == openAuthoringElementCommandId);
    final result = await command.execute(
      const SearchCommandExecutionContext(
        prompts: UnsupportedSearchPromptHost(),
      ),
      _target(searchResult),
    );
    final effect = (result as SearchCommandResultCompleted).hostEffects.single;

    expect(effect, isA<OpenAuthoringElementEffect>());
    expect(
      (effect as OpenAuthoringElementEffect).organizationId,
      _organization,
    );
    expect(effect.realmId, _realm);
    expect(effect.bookId, page.book.id);
    expect(effect.pageId, page.id);
    expect(
      effect.elementIdentifier,
      EntryIdentifier(element.id.id, pageId: page.id.id),
    );
  });
}

final _organization = _id("organization", "org");
final _realm = _id("realm", "realm");

skir.RecordId _id(String table, String id) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(id));

SearchResult _result(SearchResultType type, Object payload) =>
    SearchResult(id: type.id, type: type, payload: payload);

SearchCommandTarget _target(SearchResult result) => SearchCommandTarget(
  primary: result,
  selection: [result],
  query: SearchQueryContext.empty,
);
