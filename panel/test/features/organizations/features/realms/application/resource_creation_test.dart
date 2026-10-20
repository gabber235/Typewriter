import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  for (final cancellation in [
    "none",
    "realm",
    "realm return",
    "catalog",
    "catalog return",
    "wrong realm",
    "dispose",
  ]) {
    testWidgets(
      "creation completes atomically with $cancellation cancellation",
      (tester) async {
        final fixture = _fixture();
        final document = AuthoringDocument.fromState(
          fixture.snapshot,
          catalog: fixture.catalog,
        );
        final transport = ScriptedAuthoringTransport(AsyncData(document));
        addTearDown(transport.dispose);
        final preparation = Completer<skir.PreparationStep>();
        skir.PreparationOperation? operation;
        AuthoringResourceIdentifier? created;
        RealmEditing? workspace;
        var ambientRealm = fixture.realm;
        final commands = AuthoredResourceCommands(
          previewTypeArguments: ({
            required resource,
            required requested,
          }) async => throw UnimplementedError(),
          prepareTypeArguments: (_) async => throw UnimplementedError(),
          prepareValue: (_) async => throw UnimplementedError(),
          prepareStep: (input) {
            operation = input;
            return preparation.future;
          },
          invokeCommand: ({required capabilityId, required payload}) async =>
              throw UnimplementedError(),
          watchSearch: (_) => const Stream.empty(),
          search: (_) async => throw UnimplementedError(),
          reload: () async {},
        );
        await tester.pumpTestApp(
          overrides: [
            organizationIdProvider.overrideWith((_) => fixture.organization),
            realmIdProvider.overrideWith((_) => ambientRealm),
            ...authoringFixtureOverrides(
              document: document,
              transport: transport,
              commands: commands,
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  workspace = ref.readRealmEditing();
                  created = await ref
                      .read(
                        resourceCreationProvider(
                          AuthoringScope(
                            organizationId: fixture.organization,
                            realmId: fixture.realm,
                          ),
                        ),
                      )
                      .create(context: context, request: fixture.request);
                },
                child: const Text("Create"),
              ),
            ),
          ),
        );
        if (cancellation == "wrong realm") {
          ambientRealm = skir.recordId("realm:other");
          tester.container().invalidate(realmIdProvider);
          await tester.pump();
        }
        await tester.tap(find.text("Create"));
        await tester.pump();
        if (cancellation == "wrong realm") {
          expect(operation, isNull);
          expect(created, isNull);
          expect(transport.requests, isEmpty);
          return;
        }
        expect(operation, isA<skir.PreparationOperation_startWrapper>());
        expect(workspace!.document.resource(fixture.request.id), isNull);
        expect(transport.requests, isEmpty);
        if (cancellation.startsWith("realm")) {
          ambientRealm = skir.recordId("realm:other");
          tester.container().invalidate(realmIdProvider);
          await tester.pump();
          if (cancellation == "realm return") {
            ambientRealm = fixture.realm;
            tester.container().invalidate(realmIdProvider);
            await tester.pump();
          }
        } else if (cancellation.startsWith("catalog")) {
          final changed = fixture.catalog.snapshot.toMutable()
            ..generation = skir.CatalogGeneration(value: "catalog:changed");
          workspace!.acceptConfirmed(
            document.copyWith(
              catalog: CheckedEditorCatalog(changed.toFrozen()),
            ),
          );
          await tester.pump();
          if (cancellation == "catalog return") {
            workspace!.acceptConfirmed(document);
            await tester.pump();
          }
        } else if (cancellation == "dispose") {
          await tester.pumpWidget(const SizedBox());
        }
        preparation.complete(skir.PreparationStep.wrapReady(fixture.prepared));
        await tester.pump();
        if (cancellation == "none") {
          expect(created?.resourceId, fixture.request.id);
          expect(
            workspace!.document
                .entry(fixture.request.id)
                ?.content
                .configuration,
            fixture.request.configuration,
          );
          expect(
            workspace!.document.initializationFindings.single.diagnostic.code,
            "preparation_detail",
          );
          await tester.pump(const Duration(seconds: 1));
          expect(transport.requests, hasLength(1));
          expect(transport.requests.single.edit.intents, hasLength(1));
        } else {
          expect(created, isNull);
          expect(transport.requests, isEmpty);
        }
      },
    );
  }
}

final class _CreationFixture {
  const _CreationFixture({
    required this.organization,
    required this.realm,
    required this.snapshot,
    required this.catalog,
    required this.pending,
    required this.request,
    required this.prepared,
  });

  final skir.RecordId organization;
  final skir.RecordId realm;
  final skir.AuthoringState snapshot;
  final CheckedEditorCatalog catalog;
  final skir.TypeSelection pending;
  final ResourceCreationRequest request;
  final skir.PreparedValue prepared;
}

_CreationFixture _fixture() {
  final generation = skir.CatalogGeneration(value: "catalog:creation");
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "test",
      name: "GenericResource",
    ),
    revision: 1,
  );
  final pending = skir.TypeSelection.createComplete(
    definition: definition,
    arguments: const [],
  );
  final store = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Store"),
    revision: 1,
  );
  final storeLink = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "StoreLink"),
    revision: 1,
  );
  final owner = skir.EndpointId(value: "test.store:first");
  skir.PublishedType published(
    skir.TypeDefinitionId id,
    skir.RepresentationTemplate representation,
  ) => skir.PublishedType(
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: const [],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: const [],
    display: defaultTypeDisplay(""),
  );
  final wire = skir.EditorCatalogWireSnapshot(
    resourceDisplays: const [],
    resourceOperations: const [],
    resourceOperationContributions: const [],
    generation: generation,
    types: [
      skir.PublishedType(
        searchKey: null,
        placementField: null,
        definition: skir.TypeDefinition(
          id: definition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
        display: defaultTypeDisplay(""),
      ),
      // A store owns the resource, which makes it a creatable resource type.
      published(
        store,
        skir.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
      ),
      published(
        storeLink,
        skir.RepresentationTemplate.createLink(
          endpoint: owner,
          target: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ),
    ],
    relations: [
      skir.RelationContract(
        id: skir.RelationId(value: "test.store"),
        families: [skir.RelationFamilyId(value: "resource.ownership")],
        first: skir.EndpointDefinition(
          id: owner,
          slot: skir.EndpointSlot.first,
          resource: skir.NamedTypeTemplate(
            definition: store,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.cascade,
        ),
        second: skir.EndpointDefinition(
          id: skir.EndpointId(value: "test.store:second"),
          slot: skir.EndpointSlot.second,
          resource: skir.NamedTypeTemplate(
            definition: definition,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
      ),
    ],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final prepared = skir.PreparedValue(
    content: skir.PreparedContent.wrapRecord(
      skir.AuthoringRecord(configuration: pending, fields: const []),
    ),
    findings: [
      skir.InitializationDiagnostic(
        field: null,
        code: "preparation_detail",
        message: "A retained preparation finding",
        relativePath: skir.ValuePath(segments: const []),
      ),
    ],
  );
  final snapshot = skir.AuthoringState(
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    generation: generation,
    resources: const [],
    links: const [],
    findings: const [],
  );
  return _CreationFixture(
    organization: skir.recordId("organization:test"),
    realm: skir.recordId("realm:test"),
    snapshot: snapshot,
    catalog: CheckedEditorCatalog(wire),
    pending: pending,
    request: ResourceCreationRequest(
      id: skir.ResourceId(value: "resource:created"),
      type: definition,
      configuration: pending,
    ),
    prepared: prepared,
  );
}
