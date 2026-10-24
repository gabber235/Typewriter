import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("realm open command follows live availability", () {
    final availability = ValueNotifier<AsyncValue<Map<skir.RecordId, bool>>>(
      const AsyncLoading(),
    );
    addTearDown(availability.dispose);
    final realm = TopologyRealm(
      realmId: skir.recordId("realm:test"),
      ownerHost: TopologyOwnerHost(
        id: skir.recordId("service:test"),
        name: "test",
      ),
      revision: 1,
      targetEngine: const TopologyEngineTarget(
        engineId: "typewritermc:paper",
        versionConstraint: "*",
      ),
      state: TopologyRuntimeState(
        status: TopologyRuntimeStatus.active,
        activeArtifactVersion: null,
        message: null,
        updatedAt: DateTime(2026),
      ),
    );
    final result = SearchResult(
      id: "realm:test",
      type: realmSearchResultType,
      payload: realm,
    );
    final target = SearchCommandTarget(
      primary: result,
      selection: [result],
      query: SearchQueryContext.empty,
    );
    final command = openRealmCommand(
      organizationId: skir.recordId("organization:test"),
      availability: availability,
    );

    expect(command.evaluate(target), isA<SearchCommandDisabled>());
    availability.value = AsyncData({realm.realmId: false});
    expect(command.evaluate(target), isA<SearchCommandHidden>());
    availability.value = AsyncData({realm.realmId: true});
    expect(command.evaluate(target), isA<SearchCommandEnabled>());
  });
}
