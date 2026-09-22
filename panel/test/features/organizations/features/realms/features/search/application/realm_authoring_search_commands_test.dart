import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("resource command retains scope and typed payload", () async {
    final bookId = _resourceId("main");
    final book = _payload(
      id: bookId,
      type: referenceResourceTypes.book,
      definition: CoreResourceDefinitionIds.book,
    );

    final searchResult = _result(authoringResourceSearchResultType, book);
    final command = openAuthoringCommands(
      _organization,
      _realm,
    ).singleWhere((command) => command.id == openAuthoringResourceCommandId);
    final result = await command.execute(
      const SearchCommandExecutionContext(
        prompts: UnsupportedSearchPromptHost(),
      ),
      _target(searchResult),
    );
    final effect =
        (result as SearchCommandResultCompleted).hostEffects.single
            as OpenAuthoringResourceEffect;

    expect(effect.organizationId, _organization);
    expect(effect.realmId, _realm);
    expect(effect.resourceId, bookId);
    expect(effect.definition, CoreResourceDefinitionIds.book);
  });

  test("resource command classifies Entry identifiers safely", () async {
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
      definition: CoreResourceDefinitionIds.element,
      context: {"book": ReferenceValue(bookId)},
    );

    final searchResult = _result(authoringResourceSearchResultType, element);
    final command = openAuthoringCommands(
      _organization,
      _realm,
    ).singleWhere((command) => command.id == openAuthoringResourceCommandId);
    final result = await command.execute(
      const SearchCommandExecutionContext(
        prompts: UnsupportedSearchPromptHost(),
      ),
      _target(searchResult),
    );
    final effect =
        (result as SearchCommandResultCompleted).hostEffects.single
            as OpenAuthoringResourceEffect;

    expect(effect.organizationId, _organization);
    expect(effect.realmId, _realm);
    expect(effect.resourceId, elementId);
    expect(effect.definition, CoreResourceDefinitionIds.element);
    expect(effect.bookId, bookId);
    expect(effect.ownerId, pageId);
    expect(
      effect.nestedIdentifier,
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
  required ResourceDefinitionId definition,
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
    definition: definition,
    ownerPath: [?owner, if (context["book"] case ReferenceValue(:final id)) id],
  );
}
