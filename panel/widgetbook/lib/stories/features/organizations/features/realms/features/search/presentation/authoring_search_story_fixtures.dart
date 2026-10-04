import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_catalog.dart";

final class AuthoringSearchStoryFixtures {
  AuthoringSearchStoryFixtures() : catalog = authoringSearchStoryCatalog() {
    mainQuest = _payload(
      kind: "book",
      id: "book:main_quest",
      label: "Main Quest",
      summary: "The primary story book",
    );
    mainQuestTag = _payload(
      kind: "tag",
      id: "tag:main_quest",
      label: "Main Quest",
      summary: "Applied to the main quest resources",
    );
    meetTheMayor = _payload(
      kind: "page",
      id: "page:meet_the_mayor",
      label: "Meet the Mayor",
      summary: "quest.intro.dialogue in Main Quest",
    );
    mayorGreeting = _payload(
      kind: "element",
      id: "element:mayor_greeting",
      label: "Mayor Greeting",
      summary: "The old bridge is no longer safe after sunset",
    );
  }

  final CheckedEditorCatalog catalog;
  final organizationId = recordId("organization:widgetbook");
  final realmId = recordId("realm_instance:authoring_demo");

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

  AuthoringSearchResultPayload _payload({
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
    return AuthoringSearchResultPayload(
      hit: skir.AuthoringSearchHit(
        resource: resource,
        definition: resourceDefinition,
        subject: skir.PresentationSubject(
          resource: resource,
          definition: resourceDefinition,
          content: content,
          descriptor: skir.DataValue.wrapStringValue(label),
        ),
        context: skir.PortableValue(
          actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          payload: skir.DataValue.wrapStringValue(kind),
        ),
      ),
      catalog: catalog,
    );
  }
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
