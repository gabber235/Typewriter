import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_catalog.dart";

final class AuthoringSearchStoryFixtures {
  AuthoringSearchStoryFixtures() : catalog = authoringSearchStoryCatalog() {
    final book = _hit(
      kind: "book",
      id: "book:main_quest",
      label: "Main Quest",
      summary: "The primary story book",
    );
    final tag = _hit(
      kind: "tag",
      id: "tag:main_quest",
      label: "Main Quest",
      summary: "Applied to the main quest resources",
    );
    final page = _hit(
      kind: "page",
      id: "page:meet_the_mayor",
      label: "Meet the Mayor",
      summary: "quest.intro.dialogue in Main Quest",
    );
    final element = _hit(
      kind: "element",
      id: "element:mayor_greeting",
      label: "Mayor Greeting",
      summary: "The old bridge is no longer safe after sunset",
    );
    final hits = [book, tag, page, element];
    document = AuthoringDocument(
      catalog: catalog,
      entries: {
        for (final hit in hits)
          hit.resource: skir.AuthoringResource(
            id: hit.resource,
            definition: hit.definition,
            content: hit.subject.content,
          ),
      },
      links: const [],
    );
    issues = ResourceIssues.evaluate(document: document);
    mainQuest = _payload(book);
    mainQuestTag = _payload(tag);
    meetTheMayor = _payload(page);
    mayorGreeting = _payload(element);
  }

  final CheckedEditorCatalog catalog;
  late final AuthoringDocument document;
  late final ResourceIssues issues;
  final organizationId = skir.recordId("organization:widgetbook");
  final realmId = skir.recordId("realm_instance:authoring_demo");

  late final AuthoringSearchResultPayload mainQuest;
  late final AuthoringSearchResultPayload mainQuestTag;
  late final AuthoringSearchResultPayload meetTheMayor;
  late final AuthoringSearchResultPayload mayorGreeting;

  List<QuerySelectorDefinition> get selectors => [
    KeyValueSelectorDefinition(
      id: "type",
      key: "type:",
      value: const QuerySelectorValue.enumValue([
        "Book",
        "Tag",
        "Page",
        "Element",
      ]),
    ),
  ];

  List<SearchCommand> get commands =>
      openAuthoringCommands(organizationId, realmId);

  List<SearchNode> get nodes => [
    _node("book", mainQuest),
    _node("tag", mainQuestTag),
    _node("page", meetTheMayor),
    _node("element", mayorGreeting),
  ];

  SearchSource source({
    Duration searchDelay = const Duration(milliseconds: 180),
  }) => MockSearchSource(
    sourceSelectors: selectors,
    nodes: nodes,
    searchDelay: searchDelay,
  ).cached();

  SearchSession<void> session({
    Duration searchDelay = const Duration(milliseconds: 180),
    String initialQuery = "",
  }) => SearchSession(
    source: source(searchDelay: searchDelay),
    interaction: SearchInteraction(
      activation: SearchActivation.command(
        resolve: (result) => switch (result.type) {
          authoringResourceSearchResultType => openAuthoringResourceCommandId,
          _ => null,
        },
        dependencies: const [],
      ),
      selectionMode: SearchSelectionMode.single,
      commands: commands,
    ),
    initialQuery: initialQuery,
  );

  skir.AuthoringSearchHit _hit({
    required String kind,
    required String id,
    required String label,
    required String summary,
  }) {
    final definition = authoringSearchStoryDefinitions[kind]!;
    final resource = skir.ResourceId(value: id);
    final resourceDefinition = skir.ResourceDefinitionId(
      value: "widgetbook.$kind",
    );
    final content = skir.AuthoringRecord(
      configuration: skir.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      ),
      fields: [
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue(label),
        ),
        skir.FieldValue(
          name: "summary",
          value: skir.DataValue.wrapStringValue(summary),
        ),
      ],
    );
    return skir.AuthoringSearchHit(
      resource: resource,
      definition: resourceDefinition,
      subject: skir.PresentationSubject(
        resource: resource,
        definition: resourceDefinition,
        content: content,
      ),
      context: skir.PortableValue(
        actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        payload: skir.DataValue.wrapStringValue(kind),
      ),
    );
  }

  AuthoringSearchResultPayload _payload(skir.AuthoringSearchHit hit) =>
      AuthoringSearchResultPayload(
        hit: hit,
        document: document,
        issues: issues,
      );
}

SearchNode _node(String id, AuthoringSearchResultPayload payload) =>
    SearchNode.result(
      result: SearchResult(
        id: id,
        type: authoringResourceSearchResultType,
        payload: payload,
        title: payload.title,
      ),
    );
