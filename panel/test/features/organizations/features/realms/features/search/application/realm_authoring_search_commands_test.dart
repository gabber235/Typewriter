import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("resource command retains scope and canonical payload", () async {
    final resource = skir.ResourceId(value: "book:main");
    final definition = skir.ResourceDefinitionId(value: "typewriter.book");
    final configuration = skir.TypeSelection.createComplete(
      definition: _book,
      arguments: const [],
    );
    final payload = _payload(
      resource: resource,
      definition: definition,
      configuration: configuration,
      navigationHandler: "typewriter.book",
    );
    final searchResult = SearchResult(
      id: resource.value,
      type: authoringResourceSearchResultType,
      payload: payload,
    );
    final command = openAuthoringCommands(
      _organization,
      _realm,
    ).singleWhere((value) => value.id == openAuthoringResourceCommandId);

    final result = await command.execute(
      const SearchCommandExecutionContext(
        prompts: UnsupportedSearchPromptHost(),
      ),
      SearchCommandTarget(
        primary: searchResult,
        selection: [searchResult],
        query: SearchQueryContext.empty,
      ),
    );

    final effect =
        (result as SearchCommandResultCompleted).hostEffects.single
            as OpenAuthoringResourceEffect;
    expect(effect.organizationId, _organization);
    expect(effect.realmId, _realm);
    expect(effect.resourceId, resource);
    expect(effect.definition, definition);
    expect(effect.configuration, configuration);
    expect(effect.navigationHandler, "typewriter.book");
  });
}

final _organization = _recordId("organization", "org");
final _realm = _recordId("realm", "realm");
final _book = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Book"),
  revision: 1,
);

skir.RecordId _recordId(String table, String key) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(key));

AuthoringSearchResultPayload _payload({
  required skir.ResourceId resource,
  required skir.ResourceDefinitionId definition,
  required skir.TypeSelection configuration,
  required String navigationHandler,
}) {
  final catalog = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:test"),
      types: [
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: _book,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: const [],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: [
        skir.AuthoringResourceDefinition(
          id: definition,
          root: _book,
          navigationHandler: navigationHandler,
        ),
      ],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final content = skir.AuthoringRecord(
    configuration: configuration,
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue("Main Book"),
      ),
    ],
  );
  return AuthoringSearchResultPayload(
    hit: skir.AuthoringSearchHit(
      resource: resource,
      definition: definition,
      subject: skir.PresentationSubject(
        resource: resource,
        definition: definition,
        content: content,
        descriptor: skir.DataValue.wrapStringValue("Main Book"),
      ),
      context: skir.PortableValue(
        actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        payload: skir.DataValue.wrapStringValue("library"),
      ),
    ),
    catalog: catalog,
  );
}
