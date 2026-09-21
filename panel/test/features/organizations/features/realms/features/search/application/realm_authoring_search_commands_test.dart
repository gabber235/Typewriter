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
    final bookId = _resourceId("main");
    final book = _payload(
      id: bookId,
      type: referenceResourceTypes.book,
      kind: AuthoringSearchResultKind.book,
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
    expect(effect.bookId, bookId);
  });

  test("element command cannot emit a page or book effect", () async {
    final bookId = _resourceId("main");
    final pageId = _resourceId("intro");
    final elementId = _resourceId("greeting");
    const entryType = ResolvedTypeRef(
      id: TypeId.qualified(namespace: "test", name: "Entry"),
      revision: 1,
    );
    final element = _payload(
      id: elementId,
      owner: pageId,
      type: entryType,
      kind: AuthoringSearchResultKind.element,
      context: {"book": ReferenceValue(bookId)},
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
    expect(effect.bookId, bookId);
    expect(effect.pageId, pageId);
    expect(
      effect.elementIdentifier,
      EntryIdentifier(elementId.id, pageId: pageId.id),
    );
  });
}

final _organization = _id("organization", "org");
final _realm = _id("realm", "realm");

skir.RecordId _id(String table, String id) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(id));

skir.ResourceId _resourceId(String id) => skir.ResourceId(value: id);

SearchResult _result(SearchResultType type, Object payload) =>
    SearchResult(id: type.id, type: type, payload: payload);

SearchCommandTarget _target(SearchResult result) => SearchCommandTarget(
  primary: result,
  selection: [result],
  query: SearchQueryContext.empty,
);

AuthoringSearchResultPayload _payload({
  required skir.ResourceId id,
  required ResolvedTypeRef type,
  required AuthoringSearchResultKind kind,
  skir.ResourceId? owner,
  Map<String, DataValue> context = const {},
}) {
  final catalog = TypeCatalog([
    TypeDefinition(
      id: type,
      kind: NominalTypeKind.concrete,
      representation: const RecordType(fields: {}),
    ),
  ]);
  final envelope = TypedValueEnvelope(
    rootType: type,
    rootValue: RecordValue({}),
  );
  return AuthoringSearchResultPayload(
    subject: (
      content: envelope,
      descriptor: envelope,
      identityEnvelope: envelope,
      identity: (id: id, owner: owner),
    ),
    context: TypedValueEnvelope(
      rootType: type,
      rootValue: RecordValue(context),
    ),
    presentation: (
      model: PresentationModel(
        catalog: catalog,
        inputs: const {},
        root: PresentationNode(
          id: "test.search.result",
          element: TextElement("Result".asStringLiteral),
        ),
      ),
      presentation: const PresentationId(namespace: "test", name: "result"),
    ),
    kind: kind,
  );
}
