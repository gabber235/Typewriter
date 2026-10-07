import "dart:convert";

import "package:crypto/crypto.dart";
import "package:flutter/widgets.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:uuid/uuid.dart";

part "resource_creation.g.dart";

@Riverpod(keepAlive: true)
ResourceCreationSession resourceCreation(Ref ref) =>
    ResourceCreationSession(ref);

final class ResourceCreationConnection {
  const ResourceCreationConnection({
    required this.source,
    required this.endpoint,
    required this.path,
  });

  factory ResourceCreationConnection.collection({
    required types.ResourceId source,
    required types.EndpointId endpoint,
    required types.ValuePath containing,
    required types.ItemId item,
  }) => ResourceCreationConnection(
    source: source,
    endpoint: endpoint,
    path: types.ValuePath(
      segments: [
        ...containing.segments,
        types.PathSegment.createItem(id: item),
      ],
    ),
  );

  final types.ResourceId source;
  final types.EndpointId endpoint;
  final types.ValuePath path;
}

final class ResourceCreationRequest {
  ResourceCreationRequest({
    required this.definition,
    required this.configuration,
    this.supplied = const [],
    this.connections = const [],
    types.ResourceId? id,
    types.InitializationRequestId? initializationId,
  }) : id = id ?? newResourceId(),
       initializationId =
           initializationId ??
           types.InitializationRequestId(value: "panel:${_uuid.v4()}");

  final types.ResourceId id;
  final types.InitializationRequestId initializationId;
  final catalog_wire.ResourceDefinitionId definition;
  final types.TypeSelection configuration;
  final List<types.FieldValue> supplied;
  final List<ResourceCreationConnection> connections;

  ResourceCreationRequest withConfiguration(types.TypeSelection next) =>
      ResourceCreationRequest(
        id: id,
        initializationId: initializationId,
        definition: definition,
        configuration: next,
        supplied: supplied,
        connections: connections,
      );
}

typedef CreatedAuthoringResource = ({
  types.ResourceId id,
  catalog_wire.ResourceDefinitionId definition,
  types.AuthoringRecord content,
});

typedef ResourceCreationTemplate = ({
  catalog_wire.ResourceDefinitionId definition,
  types.TypeSelection configuration,
});

ResourceCreationTemplate? resourceCreationTemplate(
  CheckedEditorCatalog? checked,
  String definition,
) {
  if (checked == null) return null;
  final id = catalog_wire.ResourceDefinitionId(value: definition);
  final resource = checked.snapshot.resourceDefinitions
      .where((candidate) => candidate.id == id)
      .firstOrNull;
  if (resource == null) return null;
  final configuration = checked.beginSelection(resource.root);
  if (configuration == types.TypeSelection.unknown) return null;
  return (definition: id, configuration: configuration);
}

AuthoredDraft stageResourceCreation({
  required AuthoredDraft baseline,
  required ResourceCreationRequest request,
  required catalog_wire.PreparedCreation prepared,
}) {
  final draft = baseline.fork()..createPrepared(request.id, prepared);
  for (final connection in request.connections) {
    draft.connect(
      authoring.LinkOccurrence(
        id: authoring.LinkOccurrenceId(
          endpoint: connection.endpoint,
          location: types.ValueLocation(
            resource: connection.source,
            path: connection.path,
          ),
        ),
        source: connection.source,
        target: types.LinkTarget(resource: request.id, opposite: null),
      ),
      request.id,
    );
  }
  return draft;
}

final class ResourceCreationSession {
  const ResourceCreationSession(this.ref);

  final Ref ref;

  Future<CreatedAuthoringResource?> create({
    required BuildContext context,
    required ResourceCreationRequest request,
  }) async {
    final access = ref.readAuthoringSession();
    final checked = access.state.catalog;
    final baseline = access.state.draft;
    if (checked == null || baseline == null) {
      throw StateError("Authoring is not ready");
    }
    var effectiveRequest = request;
    if (checked.isAbstractRecordSelection(effectiveRequest.configuration)) {
      final selection = await showCreationConcreteTypePicker(
        context,
        expected: effectiveRequest.configuration,
        catalog: checked,
      );
      if (selection == null || !context.mounted) return null;
      effectiveRequest = effectiveRequest.withConfiguration(selection);
    }
    if (!checked.isResourceDefinition(
          effectiveRequest.configuration,
          request.definition,
        ) ||
        checked.isAbstractRecordSelection(effectiveRequest.configuration)) {
      throw StateError("The selected resource type is unavailable");
    }
    final initialization = catalog_wire.InitializationRequest(
      id: effectiveRequest.initializationId,
      catalog: baseline.generation,
      type: effectiveRequest.configuration,
      supplied: effectiveRequest.supplied,
      intentHash: _initializationHash(
        effectiveRequest.configuration,
        effectiveRequest.supplied,
      ),
    );
    final prepared = await access.notifier.prepareCreation(initialization);
    final latest = access.state.draft;
    if (latest == null || latest.generation != baseline.generation) {
      throw StateError("The Realm changed while creation was prepared");
    }
    final draft = stageResourceCreation(
      baseline: latest,
      request: effectiveRequest,
      prepared: prepared,
    );
    final response = await access.notifier.commit(draft.prepare());
    final CreatedAuthoringResource created;
    switch (response) {
      case authoring.CommitPreparedEditResponse_resultWrapper(
        value: authoring.CommitResult.committed,
      ):
        await access.notifier.refresh();
        final adopted = await access.notifier.awaitResource(
          effectiveRequest.id,
        );
        created = (
          id: effectiveRequest.id,
          definition: adopted.definition,
          content: adopted.content,
        );
      case authoring.CommitPreparedEditResponse_resultWrapper(
        value: authoring.CommitResult_conflictWrapper(),
      ):
        throw StateError("The Realm changed before this resource was saved");
      case authoring.CommitPreparedEditResponse_resultWrapper(
        value: authoring.CommitResult_catalogChangedWrapper(),
      ):
        throw StateError("The editor catalog changed");
      case authoring.CommitPreparedEditResponse_resultWrapper(
        value: authoring.CommitResult_rejectedWrapper(),
      ):
        throw StateError(response.rejectionMessage);
      default:
        throw StateError("The creation result is unavailable");
    }
    if (prepared.findings.isNotEmpty && context.mounted) {
      showErrorSnackBar(
        context,
        prepared.findings
            .map(formatPortableInitializationDiagnostic)
            .join("\n"),
      );
    }
    return created;
  }
}

const _uuid = Uuid();

String _initializationHash(
  types.TypeSelection selection,
  List<types.FieldValue> fields,
) {
  final canonical = StringBuffer(selection);
  for (final field
      in fields.toList()..sort((a, b) => a.name.compareTo(b.name))) {
    canonical
      ..write("\u0000")
      ..write(field.name)
      ..write("\u0000")
      ..write(field.value);
  }
  return sha256.convert(utf8.encode(canonical.toString())).toString();
}
