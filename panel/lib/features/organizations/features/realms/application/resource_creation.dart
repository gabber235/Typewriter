import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_creation.g.dart";
part "resource_creation.freezed.dart";

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
    required skir.ResourceId source,
    required skir.EndpointId endpoint,
    required skir.ValuePath containing,
    required skir.ItemId item,
  }) => ResourceCreationConnection(
    source: source,
    endpoint: endpoint,
    path: skir.ValuePath(
      segments: [
        ...containing.segments,
        skir.PathSegment.createItem(id: item),
      ],
    ),
  );

  final skir.ResourceId source;
  final skir.EndpointId endpoint;
  final skir.ValuePath path;
}

final class ResourceCreationRequest {
  ResourceCreationRequest({
    required this.definition,
    required this.configuration,
    this.supplied = const [],
    this.connections = const [],
    skir.ResourceId? id,
    skir.InitializationRequestId? initializationId,
  }) : id = id ?? skir.newResourceId(),
       initializationId =
           initializationId ??
           skir.InitializationRequestId(value: "panel:${_uuid.v4()}");

  final skir.ResourceId id;
  final skir.InitializationRequestId initializationId;
  final skir.ResourceDefinitionId definition;
  final skir.TypeSelection configuration;
  final List<skir.FieldValue> supplied;
  final List<ResourceCreationConnection> connections;

  ResourceCreationRequest withConfiguration(skir.TypeSelection next) =>
      ResourceCreationRequest(
        id: id,
        initializationId: initializationId,
        definition: definition,
        configuration: next,
        supplied: supplied,
        connections: connections,
      );
}

@freezed
abstract class CreatedAuthoringResource with _$CreatedAuthoringResource {
  const factory CreatedAuthoringResource({
    required skir.ResourceId id,
    required skir.ResourceDefinitionId definition,
    required skir.AuthoringRecord content,
  }) = _CreatedAuthoringResource;
}

@freezed
abstract class ResourceCreationTemplate with _$ResourceCreationTemplate {
  const factory ResourceCreationTemplate({
    required skir.ResourceDefinitionId definition,
    required skir.TypeSelection configuration,
  }) = _ResourceCreationTemplate;
}

extension ResourceCreationCatalog on CheckedEditorCatalog? {
  ResourceCreationTemplate? resourceCreationTemplate(String definition) {
    final checked = this;
    if (checked == null) return null;
    final id = skir.ResourceDefinitionId(value: definition);
    final resource = checked.snapshot.resourceDefinitions
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    if (resource == null) return null;
    final configuration = checked.beginSelection(resource.root);
    if (configuration == skir.TypeSelection.unknown) return null;
    return ResourceCreationTemplate(
      definition: id,
      configuration: configuration,
    );
  }
}

void createAuthoringResource({
  required AuthoringEdit edit,
  required ResourceCreationRequest request,
  required skir.PreparedValue prepared,
}) {
  edit.createPrepared(request.id, prepared, definition: request.definition);
  for (final connection in request.connections) {
    edit.connect(
      skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: connection.endpoint,
          location: skir.ValueLocation(
            resource: connection.source,
            path: connection.path,
          ),
        ),
        source: connection.source,
        target: skir.LinkTarget(resource: request.id, opposite: null),
      ),
      request.id,
    );
  }
}

final class ResourceCreationSession {
  const ResourceCreationSession(this.ref);

  final Ref ref;

  Future<CreatedAuthoringResource?> create({
    required BuildContext context,
    required ResourceCreationRequest request,
  }) async {
    final workspace = ref.readAuthoringWorkspace();
    final scope = ref.read(selectedAuthoringScopeProvider)!;
    final checked = workspace.document.catalog;
    final commands = ref.read(authoredResourceCommandsProvider(scope));
    CreatedAuthoringResource? created;
    final outcome = await workspace.prepare(
      label: "Create resource",
      apply: (edit) async {
        var effectiveRequest = request;
        if (checked.isAbstractRecordSelection(effectiveRequest.configuration)) {
          final selection = await showCreationConcreteTypePicker(
            context,
            expected: effectiveRequest.configuration,
            catalog: checked,
          );
          if (selection == null || !context.mounted) return;
          effectiveRequest = effectiveRequest.withConfiguration(selection);
        }
        if (!checked.isResourceDefinition(
              effectiveRequest.configuration,
              request.definition,
            ) ||
            checked.isAbstractRecordSelection(effectiveRequest.configuration)) {
          throw StateError("The selected resource type is unavailable");
        }
        final initialization = skir.ValuePreparationRequest(
          id: effectiveRequest.initializationId,
          catalog: edit.generation,
          target: skir.PreparationTarget.wrapRecord(
            effectiveRequest.configuration,
          ),
          suppliedValue: skir.DataValue.createRecord(
            fields: effectiveRequest.supplied,
          ),
          intentHash: _initializationHash(
            effectiveRequest.configuration,
            effectiveRequest.supplied,
          ),
        );
        final prepared = await commands.prepareValue(initialization);
        if (!context.mounted) {
          throw StateError("The creation view closed during preparation");
        }
        createAuthoringResource(
          edit: edit,
          request: effectiveRequest,
          prepared: prepared,
        );
        created = CreatedAuthoringResource(
          id: effectiveRequest.id,
          definition: effectiveRequest.definition,
          content: prepared.recordContent,
        );
        if (prepared.findings.isNotEmpty && context.mounted) {
          showErrorSnackBar(
            context,
            prepared.findings
                .map(formatPortableInitializationDiagnostic)
                .join("\n"),
          );
        }
      },
    );
    outcome.requireAccepted();
    return created;
  }
}

const _uuid = Uuid();

String _initializationHash(
  skir.TypeSelection selection,
  List<skir.FieldValue> fields,
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
