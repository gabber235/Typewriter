import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final class AuthoringSearchStoryFixtures {
  AuthoringSearchStoryFixtures({
    required String elementType,
    required skir.PageKindRef pageKind,
  }) {
    mainQuest = _payload(
      id: _resourceId("book", "main_quest"),
      type: referenceResourceTypes.book,
      kind: AuthoringSearchResultKind.book,
      label: "Main Quest",
    );
    seasonalEvents = _payload(
      id: _resourceId("book", "seasonal_events"),
      type: referenceResourceTypes.book,
      kind: AuthoringSearchResultKind.book,
      label: "Seasonal Events",
    );
    villageArrival = _page(
      id: "village_arrival",
      name: "Village Arrival",
      kind: pageKind,
      bookId: mainQuest.id,
      chapter: "quest.intro",
    );
    meetTheMayor = _page(
      id: "meet_the_mayor",
      name: "Meet the Mayor",
      kind: pageKind,
      bookId: mainQuest.id,
      chapter: "quest.intro.dialogue",
    );
    winterFestival = _page(
      id: "winter_festival",
      name: "Winter Festival",
      kind: pageKind,
      bookId: seasonalEvents.id,
      chapter: "winter.opening",
    );
    mayorGreeting = _element(
      id: "mayor_greeting",
      name: "Mayor Greeting",
      elementType: elementType,
      page: meetTheMayor,
      text: "The mayor lowers his voice. The old bridge is no longer safe after sunset.",
      highlight: "old bridge",
    );
    welcomeBundle = _element(
      id: "welcome_bundle",
      name: "Give Welcome Bundle",
      elementType: elementType,
      page: villageArrival,
      text: "Give the player a map, bread, and a compass.",
      highlight: "compass",
    );
    festivalAnnouncement = _element(
      id: "festival_announcement",
      name: "Festival Announcement",
      elementType: elementType,
      page: winterFestival,
      text: "Invite every player to the winter market at sunset.",
      highlight: "winter market",
    );
  }

  final organizationId = recordId("organization:widgetbook");
  final realmId = recordId("realm_instance:authoring_demo");

  final mainQuestTag = _payload(
    id: _resourceId("tag", "main_quest"),
    type: referenceResourceTypes.tag,
    kind: AuthoringSearchResultKind.tag,
    label: "Main Quest",
  );
  final storyTag = _payload(
    id: _resourceId("tag", "story"),
    type: referenceResourceTypes.tag,
    kind: AuthoringSearchResultKind.tag,
    label: "Story",
  );
  final eventTag = _payload(
    id: _resourceId("tag", "event"),
    type: referenceResourceTypes.tag,
    kind: AuthoringSearchResultKind.tag,
    label: "Event",
  );

  late final AuthoringSearchResultPayload mainQuest;
  late final AuthoringSearchResultPayload seasonalEvents;
  late final AuthoringSearchResultPayload villageArrival;
  late final AuthoringSearchResultPayload meetTheMayor;
  late final AuthoringSearchResultPayload winterFestival;
  late final AuthoringSearchResultPayload mayorGreeting;
  late final AuthoringSearchResultPayload welcomeBundle;
  late final AuthoringSearchResultPayload festivalAnnouncement;

  List<QuerySelectorDefinition> get selectors => [
    KeyValueSelectorDefinition(
      id: "book",
      key: "book:",
      value: const QuerySelectorValue.enumValue([
        "Main Quest",
        "Seasonal Events",
      ]),
    ),
    KeyValueSelectorDefinition(
      id: "page",
      key: "page:",
      value: QuerySelectorValue.enumValue([
        "Village Arrival",
        "Meet the Mayor",
        "Winter Festival",
      ]),
    ),
    KeyValueSelectorDefinition(
      id: "tag",
      key: "tag:",
      value: QuerySelectorValue.enumValue(["Main Quest", "Story", "Event"]),
    ),
    KeyValueSelectorDefinition(
      id: "type",
      key: "type:",
      value: const QuerySelectorValue.enumValue(["Sequence Entry"]),
    ),
  ];

  List<SearchCommand> get commands =>
      openAuthoringCommands(organizationId, realmId);

  List<SearchNode> get nodes => [
    _node(
      "book:main_quest",
      authoringBookSearchResultType,
      mainQuest,
      "Main Quest",
    ),
    _node(
      "page:meet_the_mayor",
      authoringPageSearchResultType,
      meetTheMayor,
      "Meet the Mayor",
      "quest.intro.dialogue / Main Quest",
    ),
    _node(
      "element:mayor_greeting",
      authoringElementSearchResultType,
      mayorGreeting,
      "Mayor Greeting",
      "Meet the Mayor",
    ),
    _node(
      "element:welcome_bundle",
      authoringElementSearchResultType,
      welcomeBundle,
      "Give Welcome Bundle",
      "Village Arrival",
    ),
    _node(
      "tag:main_quest",
      authoringTagSearchResultType,
      mainQuestTag,
      "Main Quest",
    ),
    _node(
      "book:seasonal_events",
      authoringBookSearchResultType,
      seasonalEvents,
      "Seasonal Events",
    ),
    _node(
      "page:winter_festival",
      authoringPageSearchResultType,
      winterFestival,
      "Winter Festival",
      "winter.opening / Seasonal Events",
    ),
    _node(
      "element:festival_announcement",
      authoringElementSearchResultType,
      festivalAnnouncement,
      "Festival Announcement",
      "Winter Festival",
    ),
    _node("tag:event", authoringTagSearchResultType, eventTag, "Event"),
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
          authoringBookSearchResultType => openAuthoringBookCommandId,
          authoringTagSearchResultType => openAuthoringTagCommandId,
          authoringPageSearchResultType => openAuthoringPageCommandId,
          authoringElementSearchResultType => openAuthoringElementCommandId,
          _ => null,
        },
        dependencies: const [],
      ),
      selectionMode: SearchSelectionMode.single,
      commands: commands,
    ),
    initialQuery: initialQuery,
  );
}

AuthoringSearchResultPayload _page({
  required String id,
  required String name,
  required skir.PageKindRef kind,
  required skir.ResourceId bookId,
  required String chapter,
}) => _payload(
  id: _resourceId("page", id),
  owner: bookId,
  type: referenceResourceTypes.page,
  kind: AuthoringSearchResultKind.page,
  label: name,
  context: {"book": ReferenceValue(bookId)},
  content: {
    "kind": RecordValue({
      "id": StringValue(kind.id.value),
      "revision": IntegerValue(BigInt.from(kind.revision)),
    }),
  },
);

AuthoringSearchResultPayload _element({
  required String id,
  required String name,
  required String elementType,
  required AuthoringSearchResultPayload page,
  required String text,
  required String highlight,
}) {
  return _payload(
    id: _resourceId("element", id),
    owner: page.id,
    type: ResolvedTypeRef(id: DeclaredTypeId(elementType), revision: 1),
    kind: AuthoringSearchResultKind.element,
    label: name,
    context: {"book": ReferenceValue(page.owner!)},
    matchText: text,
    highlight: highlight,
  );
}

AuthoringSearchResultPayload _payload({
  required skir.ResourceId id,
  required ResolvedTypeRef type,
  required AuthoringSearchResultKind kind,
  required String label,
  skir.ResourceId? owner,
  Map<String, DataValue> content = const {},
  Map<String, DataValue> context = const {},
  String? matchText,
  String? highlight,
}) {
  final catalog = TypeCatalog([
    TypeDefinition(
      id: type,
      kind: NominalTypeKind.concrete,
      representation: const RecordType(fields: {}),
    ),
  ]);
  final contentEnvelope = TypedValueEnvelope(
    rootType: type,
    rootValue: RecordValue(content),
  );
  final highlightStart = matchText == null || highlight == null
      ? null
      : matchText.indexOf(highlight);
  final body =
      matchText == null ||
          highlight == null ||
          highlightStart == null ||
          highlightStart < 0
      ? TextElement(label.asStringLiteral)
      : RichTextElement(
          runs: [
            PresentationTextRun(text: "$label. ".asStringLiteral),
            PresentationTextRun(
              text: matchText.substring(0, highlightStart).asStringLiteral,
            ),
            PresentationTextRun(
              text: highlight.asStringLiteral,
              style: PresentationTextStyle(fontWeight: 700.asFloatLiteral),
            ),
            PresentationTextRun(
              text: matchText
                  .substring(highlightStart + highlight.length)
                  .asStringLiteral,
            ),
          ],
          paragraph: const TextParagraph(
            maxLines: 2,
            overflow: PresentationTextOverflow.ellipsis,
          ),
        );
  return AuthoringSearchResultPayload(
    subject: (
      content: contentEnvelope,
      descriptor: contentEnvelope,
      identityEnvelope: contentEnvelope,
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
        root: PresentationNode(id: "story.search.${kind.name}", element: body),
      ),
      presentation: PresentationId(namespace: "widgetbook", name: kind.name),
    ),
    kind: kind,
  );
}

SearchNode _node(
  String id,
  SearchResultType type,
  Object payload,
  String title, [
  String? subtitle,
]) => SearchNode.result(
  result: SearchResult(
    id: id,
    type: type,
    payload: payload,
    title: title,
    subtitle: subtitle,
  ),
);

skir.ResourceId _resourceId(String kind, String id) =>
    skir.ResourceId(value: "$kind:$id");
