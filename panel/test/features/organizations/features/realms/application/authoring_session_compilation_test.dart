import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/provider_test_utils.dart";

const _graphSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.graph.query";
const _statusSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.compiled.status.query";
const _compiledSubject =
    "service.from.realm1.organization.org1.realm.compiled.content.watch";

void main() {
  test("compiled content changes refresh resource compilation state", () async {
    final nats = FakeNatsClient();
    skir.CompiledResourceState status = skir.CompiledResourceState.notCompiled;
    var statusRequests = 0;
    nats
      ..registerHandler(
        _graphSubject,
        (_) => skir.QueryAuthoringGraphResponse.serializer.toBytes(
          skir.QueryAuthoringGraphResponse.createSuccess(
            generation: skir.CatalogGeneration(value: "1"),
            sequence: 1,
            resources: [_pageResource],
            edges: const [],
            selections: const [],
            diagnostics: const [],
            presentations: const [],
          ),
        ),
      )
      ..registerHandler(_statusSubject, (_) {
        statusRequests++;
        return skir.QueryCompiledResourceStatusResponse.serializer.toBytes(
          skir.QueryCompiledResourceStatusResponse.createSuccess(
            statuses: [
              skir.CompiledResourceStatus(resource: _page, state: status),
            ],
          ),
        );
      });
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_org),
        realmIdProvider.overrideWithValue(_realm),
        realmEditorCatalogProvider.overrideWithValue(
          AsyncData(
            RealmEditorCatalogState.ready(
              RealmEditorCatalogSnapshot(
                catalog: const TypeCatalog([]),
                generation: const CatalogGeneration("1"),
              ),
            ),
          ),
        ),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    final provider = authoringSessionProvider(_org, _realm);
    final subscription = container.listen(provider, (_, _) {});
    final lease = container.read(provider.notifier).acquirePage(_page);
    await lease.ready;

    expect(
      container.read(provider).compiledStatuses[_page],
      skir.CompiledResourceState.notCompiled,
    );

    status = skir.CompiledResourceState.createBlocked(
      lastActiveManifestId: null,
      diagnosticCount: 1,
    );
    nats.emitMessageOnSubject(
      _compiledSubject,
      skir.WatchCompiledContentResponse.serializer.toBytes(
        skir.WatchCompiledContentResponse.createBlocked(),
      ),
    );
    await waitForProvider(
      container,
      provider,
      (state) =>
          state.compiledStatuses[_page]
              is skir.CompiledResourceState_blockedWrapper,
      description: "blocked resource compilation state",
    );
    expect(statusRequests, greaterThanOrEqualTo(2));

    lease.release();
    subscription.close();
    container.dispose();
    await nats.dispose();
  });
}

final _org = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _page = skir.ResourceId(value: "page1");
final _wireCodec = SkirEditorCodec(TypeRegistry(const TypeCatalog([])));
final _pageType = ResolvedTypeRef(
  id: DeclaredTypeId("22222222222222222222222222222222"),
  revision: 1,
);
final _pageResource = skir.AuthoringResource(
  id: _page,
  kind: skir.ResourceKind.page,
  content: skir.TypedValueEnvelope(
    rootType: _wireCodec.encodeType(_pageType).valueOrNull!,
    rootValue: _wireCodec.encodeValue(const StringValue("Page")).valueOrNull!,
  ),
);
