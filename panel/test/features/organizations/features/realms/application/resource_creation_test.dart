import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "creation publishes an unfinished resource before server acknowledgement",
    (tester) async {
      final fixture = _fixture();
      final document = AuthoringDocument.fromState(
        fixture.snapshot,
        catalog: fixture.catalog,
      );
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      addTearDown(transport.dispose);
      skir.ValuePreparationRequest? preparedRequest;
      CreatedAuthoringResource? created;
      AuthoringWorkspace? workspace;
      var ambientOrganization = fixture.organization;
      var ambientRealm = fixture.realm;
      final preparation = Completer<skir.PreparedValue>();
      final commands = AuthoredResourceCommands(
        previewTypeArguments: ({required resource, required requested}) async =>
            throw UnimplementedError(),
        prepareTypeArguments: (_) async => throw UnimplementedError(),
        prepareValue: (request) async {
          preparedRequest = request;
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
          organizationIdProvider.overrideWith((ref) => ambientOrganization),
          realmIdProvider.overrideWith((ref) => ambientRealm),
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
                workspace = ref.readAuthoringWorkspace();
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
      await tester.tap(find.text("Create"));
      await tester.pump();
      expect(find.byType(Dialog), findsNothing);
      expect(preparedRequest?.recordSelection, fixture.pending);
      ambientOrganization = skir.recordId("organization:other");
      ambientRealm = skir.recordId("realm:other");
      tester.container()
        ..invalidate(organizationIdProvider)
        ..invalidate(realmIdProvider);
      await tester.pump();
      preparation.complete(fixture.prepared);
      await tester.pump();
      expect(created?.id, fixture.request.id);
      expect(
        created?.scope,
        AuthoringScope(
          organizationId: fixture.organization,
          realmId: fixture.realm,
        ),
      );
      expect(created?.content.configuration, fixture.pending);
      expect(
        workspace!.document.entry(fixture.request.id)?.definition,
        fixture.request.definition,
      );
      expect(
        workspace!.document.initializationFindings.single.code,
        "dependent_unfilled",
      );
      expect(transport.requests, isEmpty);
      await tester.pump(AuthoringWorkspace.debounce);
      await tester.pump();
      expect(transport.requests, hasLength(1));
      final intent =
          transport.requests.single.edit.intents.single
              as skir.EditIntent_createResourceWrapper;
      expect(intent.value.record.configuration, fixture.pending);
      expect(
        (intent.value.record.configuration as skir.TypeSelection_pendingWrapper)
            .value
            .arguments,
        [skir.ArgumentSelection.unfilled],
      );
      expect(transport.observation.requireValue.entry(created!.id), isNull);
      expect(find.text("The generic argument is unfinished"), findsOneWidget);
    },
  );
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
  final parameter = skir.ParameterKey(owner: definition, index: 0);
  final pending = skir.TypeSelection.createPending(
    definition: definition,
    arguments: [skir.ArgumentSelection.unfilled],
  );
  final resourceDefinition = skir.ResourceDefinitionId(
    value: "test.generic_resource",
  );
  final wire = skir.EditorCatalogWireSnapshot(
    generation: generation,
    types: [
      skir.PublishedType(
        definition: skir.TypeDefinition(
          id: definition,
          parameters: [
            skir.TypeParameter(key: parameter, name: "T", bounds: const []),
          ],
          representation: skir.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
        display: null,
      ),
    ],
    relations: const [],
    resourceDefinitions: [
      skir.AuthoringResourceDefinition(
        id: resourceDefinition,
        root: definition,
        navigationHandler: "",
      ),
    ],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
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
        code: "dependent_unfilled",
        message: "The generic argument is unfinished",
        relativePath: skir.ValuePath(segments: const []),
      ),
    ],
  );
  final snapshot = skir.AuthoringState(
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
      initializationId: skir.InitializationRequestId(value: "create:test"),
      definition: resourceDefinition,
      configuration: pending,
    ),
    prepared: prepared,
  );
}
