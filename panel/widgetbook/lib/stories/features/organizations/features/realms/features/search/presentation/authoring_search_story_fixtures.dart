import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final class AuthoringSearchStoryFixtures {
  AuthoringSearchStoryFixtures({
    required String elementType,
    required skir.PageKindRef pageKind,
  }) {
    mainQuest = skir.AuthoringSearchBook(
      id: _id("book", "main_quest"),
      title: "Main Quest",
      icon: "fa6-solid:book-open",
      color: skir.Color(argb: 0xff7c4dff),
      tags: [mainQuestTag, storyTag],
    );
    seasonalEvents = skir.AuthoringSearchBook(
      id: _id("book", "seasonal_events"),
      title: "Seasonal Events",
      icon: "fa6-solid:snowflake",
      color: skir.Color(argb: 0xff00a6a6),
      tags: [eventTag],
    );
    villageArrival = _page(
      id: "village_arrival",
      name: "Village Arrival",
      kind: pageKind,
      book: mainQuest,
      chapter: "quest.intro",
    );
    meetTheMayor = _page(
      id: "meet_the_mayor",
      name: "Meet the Mayor",
      kind: pageKind,
      book: mainQuest,
      chapter: "quest.intro.dialogue",
    );
    winterFestival = _page(
      id: "winter_festival",
      name: "Winter Festival",
      kind: pageKind,
      book: seasonalEvents,
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

  final organizationId = _id("organization", "widgetbook");
  final realmId = _id("realm_instance", "authoring_demo");

  final mainQuestTag = skir.AuthoringSearchTag(
    id: _id("tag", "main_quest"),
    name: "Main Quest",
    color: skir.Color(argb: 0xffffb300),
  );
  final storyTag = skir.AuthoringSearchTag(
    id: _id("tag", "story"),
    name: "Story",
    color: skir.Color(argb: 0xffab47bc),
  );
  final eventTag = skir.AuthoringSearchTag(
    id: _id("tag", "event"),
    name: "Event",
    color: skir.Color(argb: 0xff26a69a),
  );

  late final skir.AuthoringSearchBook mainQuest;
  late final skir.AuthoringSearchBook seasonalEvents;
  late final skir.AuthoringSearchPage villageArrival;
  late final skir.AuthoringSearchPage meetTheMayor;
  late final skir.AuthoringSearchPage winterFestival;
  late final skir.AuthoringSearchElement mayorGreeting;
  late final skir.AuthoringSearchElement welcomeBundle;
  late final skir.AuthoringSearchElement festivalAnnouncement;

  List<QuerySelectorDefinition> get selectors => [
    KeyValueSelectorDefinition(
      id: "book",
      key: "book:",
      value: QuerySelectorValue.enumValue([
        mainQuest.title,
        seasonalEvents.title,
      ]),
    ),
    KeyValueSelectorDefinition(
      id: "page",
      key: "page:",
      value: QuerySelectorValue.enumValue([
        villageArrival.name,
        meetTheMayor.name,
        winterFestival.name,
      ]),
    ),
    KeyValueSelectorDefinition(
      id: "tag",
      key: "tag:",
      value: QuerySelectorValue.enumValue([
        mainQuestTag.name,
        storyTag.name,
        eventTag.name,
      ]),
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
      mainQuest.title,
    ),
    _node(
      "page:meet_the_mayor",
      authoringPageSearchResultType,
      meetTheMayor,
      meetTheMayor.name,
      "${meetTheMayor.chapter} / ${mainQuest.title}",
    ),
    _node(
      "element:mayor_greeting",
      authoringElementSearchResultType,
      mayorGreeting,
      mayorGreeting.name,
      meetTheMayor.name,
    ),
    _node(
      "element:welcome_bundle",
      authoringElementSearchResultType,
      welcomeBundle,
      welcomeBundle.name,
      villageArrival.name,
    ),
    _node(
      "tag:main_quest",
      authoringTagSearchResultType,
      mainQuestTag,
      mainQuestTag.name,
    ),
    _node(
      "book:seasonal_events",
      authoringBookSearchResultType,
      seasonalEvents,
      seasonalEvents.title,
    ),
    _node(
      "page:winter_festival",
      authoringPageSearchResultType,
      winterFestival,
      winterFestival.name,
      "${winterFestival.chapter} / ${seasonalEvents.title}",
    ),
    _node(
      "element:festival_announcement",
      authoringElementSearchResultType,
      festivalAnnouncement,
      festivalAnnouncement.name,
      winterFestival.name,
    ),
    _node("tag:event", authoringTagSearchResultType, eventTag, eventTag.name),
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

skir.AuthoringSearchPage _page({
  required String id,
  required String name,
  required skir.PageKindRef kind,
  required skir.AuthoringSearchBook book,
  required String chapter,
}) => skir.AuthoringSearchPage(
  id: _id("page", id),
  name: name,
  kind: kind,
  book: skir.AuthoringSearchBookContext(id: book.id, title: book.title),
  chapter: chapter,
);

skir.AuthoringSearchElement _element({
  required String id,
  required String name,
  required String elementType,
  required skir.AuthoringSearchPage page,
  required String text,
  required String highlight,
}) {
  final start = text.indexOf(highlight);
  return skir.AuthoringSearchElement(
    id: _id("element", id),
    name: name,
    elementType: elementType,
    placement: skir.ElementPlacement.createGraph(
      x: 0,
      y: 0,
      width: 4,
      height: 2,
    ),
    page: page,
    match: skir.AuthoringSearchMatch(
      text: text,
      start: start,
      end: start + highlight.length,
    ),
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

skir.RecordId _id(String table, String id) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(id));
