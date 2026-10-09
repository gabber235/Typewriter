import "package:flutter_test/flutter_test.dart";
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
    expect(fixture.requests, hasLength(1));
    expect(fixture.requests.single.query, isEmpty);
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

      expect(fixture.requests.length, greaterThanOrEqualTo(2));
      expect(fixture.requests.last.query, "example");
      expect(fixture.controller.snapshot.status, SearchSourceStatus.ready);
    },
  );
  test(
    "remote membership keeps working labels and hides local deletions",
    () async {
      final id = skir.ResourceId(value: "tag:hit");
      final created = skir.ResourceId(value: "tag:new");
      final context = skir.PortableValue(
        actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        payload: skir.DataValue.wrapStringValue("confirmed command context"),
      );
      final document = fixtureAuthoringDocument(
        tags: [
          Tag(
            tagId: id,
            name: "Saved name",
            color: Colors.blue,
            parentIds: const [],
            placement: const GraphPlacement(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
      );
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      addTearDown(transport.dispose);
      final base = fixtureAuthoringCommands(transport);
      final commands = AuthoredResourceCommands(
        previewTypeArguments: base.previewTypeArguments,
        prepareTypeArguments: base.prepareTypeArguments,
        prepareValue: base.prepareValue,
        invokeCommand: base.invokeCommand,
        watchSearch: base.watchSearch,
        reload: base.reload,
        search: (_) async => skir.SearchAuthoringResponse.createSuccess(
          generation: document.generation,
          hits: [
            skir.AuthoringSearchHit(
              resource: id,
              definition: document.entry(id)!.definition,
              subject: skir.PresentationSubject(
                resource: id,
                definition: document.entry(id)!.definition,
                content: document.resource(id)!,
                descriptor: skir.DataValue.wrapStringValue("Saved name"),
              ),
              context: context,
            ),
          ],
          diagnostics: const [],
        ),
      );
      final container = ProviderContainer.test(
        overrides: authoringFixtureOverrides(
          document: document,
          transport: transport,
          commands: commands,
        ),
      );
      addTearDown(container.dispose);
      final scope = container.read(selectedAuthoringScopeProvider)!;
      final controller = SourceController(
        source: RealmAuthoringSearchSource(
          ref: container.read(_refProvider),
          organizationId: scope.organizationId,
          realmId: scope.realmId,
        ),
        baseSelectors: const [],
      )..triggerQuery();
      addTearDown(controller.dispose);
      await pumpEventQueue();
      final workspace = container.read(authoringWorkspaceProvider(scope));
      final binding = workspace.attach(
        id,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(binding.detach);
      binding.edit(
        label: "Rename hit",
        apply: (edit) => edit.set(
          authoredFieldLocation(id, ["name"]),
          skir.DataValue.wrapStringValue("Working name"),
        ),
      );
      await pumpEventQueue();
      final result =
          (controller.snapshot.nodes.single as SearchResultNode).result;
      expect(result.title, "Working name");
      expect((result.payload as AuthoringSearchResultPayload).context, context);
      workspace.edit(
        label: "Create unrelated tag",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.create(
          created,
          document.resource(id)!,
          definition: document.entry(id)!.definition,
        ),
      );
      await pumpEventQueue();
      expect(controller.snapshot.nodes, hasLength(1));
      workspace.edit(
        label: "Delete hit",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.delete(id),
      );
      await pumpEventQueue();
      expect(controller.snapshot.nodes, isEmpty);
      expect(transport.observation.requireValue.entry(id), isNotNull);
      expect(transport.requests, isEmpty);
    },
  );
}

({
  ProviderContainer container,
  ProviderSubscription<AuthoringWorkspace> subscription,
  List<skir.SearchAuthoringRequest> requests,
  SourceController controller,
})
_fixture() {
  final organization = skir.recordId("organization:test");
  final realm = skir.recordId("realm:test");
  final initial = _state().confirmedDocument!;
  final requests = <skir.SearchAuthoringRequest>[];
  final transport = ScriptedAuthoringTransport(AsyncData(initial));
  final commands = AuthoredResourceCommands(
    previewTypeArguments: ({required resource, required requested}) async =>
        throw UnimplementedError(),
    prepareTypeArguments: (_) async => throw UnimplementedError(),
    prepareValue: (_) async => throw UnimplementedError(),
    invokeCommand: ({required capabilityId, required payload}) async =>
        throw UnimplementedError(),
    watchSearch: (_) => const Stream.empty(),
    reload: () async {},
    search: (request) async {
      requests.add(request);
      return skir.SearchAuthoringResponse.createSuccess(
        generation: initial.generation,
        hits: const [],
        diagnostics: const [],
      );
    },
  );
  final container = ProviderContainer.test(
    overrides: [
      organizationIdProvider.overrideWithValue(organization),
      realmIdProvider.overrideWithValue(realm),
      ...authoringFixtureOverrides(
        document: initial,
        transport: transport,
        commands: commands,
      ),
    ],
  );
  final source = RealmAuthoringSearchSource(
    ref: container.read(_refProvider),
    organizationId: organization,
    realmId: realm,
  );
  final subscription = container.listen(
    authoringWorkspaceProvider(
      AuthoringScope(organizationId: organization, realmId: realm),
    ),
    (_, _) {},
  );
  return (
    container: container,
    subscription: subscription,
    requests: requests,
    controller: SourceController(source: source, baseSelectors: const []),
  );
}

AuthoringSessionState _state() {
  final generation = skir.CatalogGeneration(value: "catalog:test");
  return AuthoringSessionState(
    catalog: receivedCheckedEditorCatalog(generation: generation),
    snapshot: skir.AuthoringState(
      generation: generation,
      resources: const [],
      links: const [],
      findings: const [],
    ),
  );
}
