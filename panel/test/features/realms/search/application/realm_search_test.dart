import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final stories = realmInstance(
    "stories",
    host: "stories",
    hostName: "realm_instance:stories",
    engine: "typewritermc:paper",
    state: childRuntimeState(artifact: null),
  );
  final maps = realmInstance(
    "maps",
    host: "maps",
    hostName: "realm_instance:maps",
    engine: "typewritermc:paper",
    state: childRuntimeState(artifact: null),
  );

  test("a search lists the Realms whose name matches", () async {
    final list = DrivenList<List<skir.RealmInstance>>();
    await list.emit([stories, maps]);
    final snapshot = await firstSnapshot(
      realmsSearchSource,
      list,
      query: "stories",
    );

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
    final list = DrivenList<List<skir.RealmInstance>>();
    await list.fail(StateError("Topology unreachable"));
    final snapshot = await firstSnapshot(
      realmsSearchSource,
      list,
      query: "stories",
    );

    expect(snapshot.status, SearchSourceStatus.error);
    expect(snapshot.errorSummaries.single.sourceLabel, "Realms");
    expect(
      snapshot.errorSummaries.single.message,
      contains("Topology unreachable"),
    );
  });

  test("an empty search lists every Realm", () async {
    final list = DrivenList<List<skir.RealmInstance>>();
    await list.emit([stories, maps]);
    final results = resultsOf(await firstSnapshot(realmsSearchSource, list));

    expect(
      results.map((result) => result.title),
      unorderedEquals(["realm_instance:stories", "realm_instance:maps"]),
    );
  });

  test("a topology that fails after loading keeps its Realms listed beside "
      "the error", () async {
    final list = DrivenList<List<skir.RealmInstance>>();
    await list.emit([stories]);
    await list.fail(StateError("Topology unreachable"));
    final snapshot = await firstSnapshot(
      realmsSearchSource,
      list,
      query: "stories",
    );

    expect(snapshot.status, SearchSourceStatus.error);
    expect(snapshot.errorSummaries.single.sourceLabel, "Realms");
    expect(resultsOf(snapshot).single.title, "realm_instance:stories");
  });

  test("opening a Realm from search follows its live availability", () {
    final availability = ValueNotifier<AsyncValue<Map<skir.RecordId, bool>>>(
      const AsyncLoading(),
    );
    addTearDown(availability.dispose);
    final realm = stories;
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
