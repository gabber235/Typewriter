import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "creation commits an unfinished generic resource without an editor dialog",
    (tester) async {
      final fixture = _fixture();
      late _CreationSession session;
      CreatedAuthoringResource? created;

      final staged = stageResourceCreation(
        baseline: AuthoredDraft.fromState(
          fixture.snapshot,
          catalog: fixture.catalog,
        ),
        request: fixture.request,
        prepared: fixture.prepared,
      );
      expect(staged.initializationFindings, hasLength(1));
      expect(staged.initializationFindings.single.code, "dependent_unfilled");

      await tester.pumpTestApp(
        overrides: [
          organizationIdProvider.overrideWithValue(fixture.organization),
          realmIdProvider.overrideWithValue(fixture.realm),
          authoringSessionProvider.overrideWith2(
            (_) => session = _CreationSession(fixture),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                created = await ref
                    .read(resourceCreationProvider)
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
      expect(session.preparedRequest?.type, fixture.pending);
      expect(session.committed, isNotNull);
      expect(session.awaitedResource, fixture.request.id);
      expect(created, isNull);

      session.adopted.complete(
        skir.AuthoringResource(
          id: fixture.request.id,
          definition: fixture.request.definition,
          content: fixture.prepared.record,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("The generic argument is unfinished"), findsOneWidget);
      expect(created?.content.configuration, fixture.pending);
      expect(created?.content.fields, isEmpty);
      final intent = session.committed!.intents.single;
      expect(intent, isA<skir.EditIntent_createResourceWrapper>());
      final record =
          (intent as skir.EditIntent_createResourceWrapper).value.record;
      expect(record.configuration, fixture.pending);
      final pending = record.configuration as skir.TypeSelection_pendingWrapper;
      expect(pending.value.arguments, [skir.ArgumentSelection.unfilled]);
    },
  );
}

final class _CreationSession extends AuthoringSession {
  _CreationSession(this.fixture);

  final _CreationFixture fixture;
  skir.InitializationRequest? preparedRequest;
  skir.PreparedEdit? committed;
  skir.ResourceId? awaitedResource;
  final adopted = Completer<skir.AuthoringResource>();

  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => AuthoringSessionState(
    snapshot: fixture.snapshot,
    catalog: fixture.catalog,
  );

  @override
  Future<void> refresh({bool catalog = false}) async {}

  @override
  Future<skir.PreparedCreation> prepareCreation(
    skir.InitializationRequest request,
  ) async {
    preparedRequest = request;
    return fixture.prepared;
  }

  @override
  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) async {
    committed = edit;
    return skir.CommitPreparedEditResponse.wrapResult(
      skir.CommitResult.committed,
    );
  }

  @override
  Future<skir.AuthoringResource> awaitResource(skir.ResourceId resource) {
    awaitedResource = resource;
    return adopted.future;
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
  final skir.PreparedCreation prepared;
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
  final prepared = skir.PreparedCreation(
    record: skir.AuthoringRecord(configuration: pending, fields: const []),
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
    organization: recordId("organization:test"),
    realm: recordId("realm:test"),
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
