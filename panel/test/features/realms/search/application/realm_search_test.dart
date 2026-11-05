import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("a search lists the Realms whose name matches", () async {
    final topology = ValueNotifier<AsyncValue<List<skir.RealmInstance>>>(
      AsyncData([
        realmInstance(
          "stories",
          host: "stories",
          hostName: "realm_instance:stories",
          engine: "typewritermc:paper",
          state: childRuntimeState(artifact: null),
        ),
        realmInstance(
          "maps",
          host: "maps",
          hostName: "realm_instance:maps",
          engine: "typewritermc:paper",
          state: childRuntimeState(artifact: null),
        ),
      ]),
    );
    addTearDown(topology.dispose);
    final source = RealmsSearchSource(topology);
    addTearDown(source.dispose);
    source.initialize(
      SearchQueryContext(normalizedQuery: "stories", selectors: const []),
    );
    final snapshot = await source.snapshots.first;

    expect(snapshot.status, SearchSourceStatus.ready);
    expect(
      [
        for (final section in snapshot.nodes.whereType<SearchSectionNode>())
          for (final hit in section.children.whereType<SearchResultNode>())
            hit.result.title!,
      ],
      ["realm_instance:stories"],
    );
  });

  test("a topology that fails to load is reported as a Realms error", () async {
    final topology = ValueNotifier<AsyncValue<List<skir.RealmInstance>>>(
      AsyncError(StateError("Topology unreachable"), StackTrace.empty),
    );
    addTearDown(topology.dispose);
    final source = RealmsSearchSource(topology);
    addTearDown(source.dispose);
    source.initialize(
      SearchQueryContext(normalizedQuery: "stories", selectors: const []),
    );
    final snapshot = await source.snapshots.first;

    expect(snapshot.status, SearchSourceStatus.error);
    expect(snapshot.errorSummaries.single.sourceLabel, "Realms");
    expect(
      snapshot.errorSummaries.single.message,
      contains("Topology unreachable"),
    );
  });

  test("opening a Realm from search follows its live availability", () {
    final availability = ValueNotifier<AsyncValue<Map<skir.RecordId, bool>>>(
      const AsyncLoading(),
    );
    addTearDown(availability.dispose);
    final realm = realmInstance(
      "stories",
      host: "stories",
      hostName: "realm_instance:stories",
      engine: "typewritermc:paper",
      state: childRuntimeState(artifact: null),
    );
    final result = SearchResult(
      id: realm.realmId.id,
      type: realmSearchResultType,
      payload: realm,
    );
    final target = SearchCommandTarget(
      primary: result,
      selection: [result],
      query: SearchQueryContext.empty,
    );
    final command = openRealmCommand(
      organizationId: skir.recordId("organization:acme"),
      availability: availability,
    );

    expect(command.evaluate(target), isA<SearchCommandDisabled>());
    availability.value = AsyncData({realm.realmId: false});
    expect(command.evaluate(target), isA<SearchCommandHidden>());
    availability.value = AsyncData({realm.realmId: true});
    expect(command.evaluate(target), isA<SearchCommandEnabled>());
  });
}
