import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("Open from search opens the hit in its realm", () async {
    final resource = skir.ResourceId(value: "book:main");
    final configuration = skir.TypeSelection.createComplete(
      definition: _book,
      arguments: const [],
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
    final document = AuthoringDocument(
      catalog: testCheckedCatalog(
        generation: skir.CatalogGeneration(value: "catalog:test"),
        types: [declaredRecord(_book)],
      ),
      entries: {
        resource: skir.AuthoringResource(id: resource, content: content),
      },
      links: const [],
    );
    final payload = AuthoringSearchResultPayload(
      hit: skir.AuthoringSearchHit(
        resource: resource,
        subject: skir.PresentationSubject(resource: resource, content: content),
        context: skir.PortableValue(
          actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          payload: skir.DataValue.wrapStringValue("library"),
        ),
      ),
      document: document,
      issues: ResourceIssues.evaluate(document: document),
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
    expect(
      effect.resource,
      AuthoringResourceIdentifier(
        organizationId: _organization,
        realmId: _realm,
        resourceId: resource,
      ),
    );
  });
}

final _organization = skir.recordId("organization:org");
final _realm = skir.recordId("realm:realm");
final _book = testTypeId("Book");
