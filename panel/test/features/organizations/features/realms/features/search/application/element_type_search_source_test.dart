import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  test("Realm results replace the removed local element type index", () async {
    final fixture = _fixture();
    addTearDown(fixture.container.dispose);
    addTearDown(fixture.subscription.close);
    addTearDown(fixture.controller.dispose);
    await pumpEventQueue();

    expect(fixture.controller.snapshot.status, SearchSourceStatus.ready);
    expect(fixture.session.requests, hasLength(1));
    expect(fixture.session.requests.single.query.normalizedQuery, isEmpty);
  });

  test(
    "query updates reuse the source and issue a fresh Realm search",
    () async {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      addTearDown(fixture.subscription.close);
      addTearDown(fixture.controller.dispose);
      await pumpEventQueue();

      fixture.controller.updateQuery("example");
      fixture.controller.triggerQuery();
      await pumpEventQueue();

      expect(fixture.session.requests.length, greaterThanOrEqualTo(2));
      expect(fixture.session.requests.last.query.normalizedQuery, "example");
      expect(fixture.controller.snapshot.status, SearchSourceStatus.ready);
    },
  );
}

({
  ProviderContainer container,
  ProviderSubscription<AuthoringSessionState> subscription,
  _SearchSession session,
  SourceController controller,
})
_fixture() {
  final organization = recordId("organization:test");
  final realm = recordId("realm:test");
  final session = _SearchSession(_state());
  final container = ProviderContainer.test(
    overrides: [
      organizationIdProvider.overrideWithValue(organization),
      realmIdProvider.overrideWithValue(realm),
      authoringSessionProvider.overrideWith2((_) => session),
    ],
  );
  final source = RealmAuthoringSearchSource(
    ref: container.read(_refProvider),
    organizationId: organization,
    realmId: realm,
  );
  final subscription = container.listen(
    authoringSessionProvider(organization, realm),
    (_, _) {},
  );
  return (
    container: container,
    subscription: subscription,
    session: session,
    controller: SourceController(source: source, baseSelectors: const []),
  );
}

final class _SearchSession extends AuthoringSession {
  _SearchSession(this.initial);

  final AuthoringSessionState initial;
  final requests = <skir.SearchAuthoringRequest>[];

  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => initial;

  @override
  Future<void> refresh({bool catalog = false}) async {}

  @override
  Future<skir.SearchAuthoringResponse> search(
    skir.SearchAuthoringRequest request,
  ) async {
    requests.add(request);
    return skir.SearchAuthoringResponse.createSuccess(
      snapshot: initial.snapshot!.snapshot,
      generation: initial.snapshot!.generation,
      hits: const [],
      facets: const [],
      diagnostics: const [],
    );
  }
}

AuthoringSessionState _state() {
  final generation = skir.CatalogGeneration(value: "catalog:test");
  return AuthoringSessionState(
    catalog: receivedCheckedEditorCatalog(generation: generation),
    snapshot: skir.AuthoringSnapshot(
      snapshot: skir.SnapshotId(value: "snapshot:test"),
      generation: generation,
      resources: const [],
      links: const [],
      findings: const [],
      observations: const [],
      absentInputToken: skir.InputToken(value: "absent"),
      findingsToken: skir.FindingsToken(value: "findings:test"),
    ),
  );
}
