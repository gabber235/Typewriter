import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_creation_operation.dart";
part "resource_creation_questions.dart";
part "resource_creation.freezed.dart";
part "resource_creation.g.dart";

@Riverpod(keepAlive: true)
ResourceCreationSession resourceCreation(Ref ref, AuthoringScope scope) =>
    ResourceCreationSession(ref, scope);

/// One resource to create: a resource of [type], configured as
/// [configuration], with [supplied] initial field values. An abstract
/// configuration asks for a concrete subtype of [type] during creation.
@freezed
abstract class ResourceCreationRequest with _$ResourceCreationRequest {
  factory ResourceCreationRequest({
    required skir.TypeDefinitionId type,
    required skir.TypeSelection configuration,
    skir.ResourceId? id,
    List<skir.FieldValue> supplied = const [],
  }) => ResourceCreationRequest.data(
    id: id ?? skir.newResourceId(),
    type: type,
    configuration: configuration,
    supplied: supplied,
  );
  const factory ResourceCreationRequest.data({
    required skir.ResourceId id,
    required skir.TypeDefinitionId type,
    required skir.TypeSelection configuration,
    @Default([]) List<skir.FieldValue> supplied,
  }) = _ResourceCreationRequest;
}

/// How creating a resource of [type] starts: its first type selection.
@freezed
abstract class ResourceCreationTemplate with _$ResourceCreationTemplate {
  const factory ResourceCreationTemplate({
    required skir.TypeDefinitionId type,
    required skir.TypeSelection configuration,
  }) = _ResourceCreationTemplate;
}

extension ResourceCreationCatalog on CheckedEditorCatalog? {
  /// The creation template for [type], or null when a person may not create
  /// resources of that type.
  ResourceCreationTemplate? resourceCreationTemplate(
    skir.TypeDefinitionId type,
  ) {
    final checked = this;
    if (checked == null) return null;
    final configuration = checked.beginSelection(type);
    if (configuration == skir.TypeSelection.unknown) return null;
    final creatable = checked.creatableTypes.toSet();
    if (!checked
        .concreteRecordSelections(configuration)
        .any(
          (concrete) => switch (concrete.definition) {
            final definition? => creatable.contains(definition),
            null => false,
          },
        )) {
      return null;
    }
    return ResourceCreationTemplate(type: type, configuration: configuration);
  }
}

/// A path from a resource type up to one of its owner types, such as from a
/// page element through its Page to the Book.
@freezed
abstract class OwnerRoute with _$OwnerRoute {
  const factory OwnerRoute({
    /// The owner type this route reaches.
    required skir.TypeDefinitionId ownerRoot,

    /// The member endpoints followed from the starting type, nearest owner
    /// first. A creation constraint follows them in this order.
    required List<skir.EndpointId> endpoints,

    /// Owner types this route reached, so a type that owns its own type, such
    /// as a Folder holding Folders, ends the walk.
    required Set<skir.TypeDefinitionId> visited,
  }) = _OwnerRoute;

  const OwnerRoute._();

  OwnerRoute extend(skir.TypeDefinitionId owner, skir.EndpointId endpoint) =>
      OwnerRoute(
        ownerRoot: owner,
        endpoints: [...endpoints, endpoint],
        visited: {...visited, owner},
      );
}

extension OwnerRoutes on CheckedEditorCatalog {
  /// Routes from [configuration] to each owner type above it, nearest first,
  /// following ownership member endpoints upward without revisiting a type.
  /// Acyclic ownership holds between resources, not types, so a type may own
  /// its own type; the walk still reaches it once.
  Iterable<OwnerRoute> ownerRoutes(skir.TypeSelection configuration) sync* {
    final start = configuration.definition;
    if (start == null) return;
    var frontier = [
      OwnerRoute(ownerRoot: start, endpoints: const [], visited: const {}),
    ];
    while (frontier.isNotEmpty) {
      final next = <OwnerRoute>[];
      for (final route in frontier) {
        for (final ownership in ownershipRelations) {
          if (!isNominalSubtype(
            route.ownerRoot,
            ownership.member.resource.definition,
          )) {
            continue;
          }
          final owner = ownership.owner.resource.definition;
          if (route.visited.contains(owner)) continue;
          final extended = route.extend(owner, ownership.member.id);
          yield extended;
          next.add(extended);
        }
      }
      frontier = next;
    }
  }
}

/// Resolves the creation template for [type] in the selected Realm.
///
/// Null means creation is unavailable: no Realm is selected, its working
/// catalog is not ready, or a person may not create resources of [type].
@riverpod
ResourceCreationTemplate? selectedResourceCreationTemplate(
  Ref ref,
  skir.TypeDefinitionId type,
) {
  if (ref.watch(selectedAuthoringScopeProvider) == null) return null;
  return ref
      .watch(selectedWorkingAuthoringDocumentProvider)
      .value
      ?.catalog
      .resourceCreationTemplate(type);
}

/// Coordinates one creation action without publishing its unfinished dependencies.
/// Each invocation owns its draft; the shared provider holds no mutable session.
/// Scope or catalog changes cancel outstanding prompts. After all dependencies
/// are ready, one local edit rechecks selected destinations and stages the graph;
/// durable saving remains the shared workspace driver's responsibility.
final class ResourceCreationSession {
  const ResourceCreationSession(this.ref, this.scope);

  final Ref ref;
  final AuthoringScope scope;

  Future<AuthoringResourceIdentifier?> create({
    required BuildContext context,
    required ResourceCreationRequest request,
    CreationContext? creationContext,
  }) async {
    if (!context.mounted) return null;
    if (ref.read(selectedAuthoringScopeProvider) case final selected?
        when selected != scope) {
      return null;
    }
    final editing = ref.listen(realmEditingProvider(scope), (_, _) {});
    ProviderSubscription<AuthoredResourceCommands>? capabilities;
    ProviderSubscription<AuthoringScope?>? scopeChanges;
    RealmEditing? workspace;
    VoidCallback? catalogChanged;
    try {
      capabilities = ref.listen(
        authoredResourceCommandsProvider(scope),
        (_, _) {},
      );
      final editingWorkspace = editing.read();
      workspace = editingWorkspace;
      final base = editingWorkspace.document;
      final initialScope = ref.read(selectedAuthoringScopeProvider);
      final operation = _ResourceCreationOperation(
        base: base,
        commands: capabilities.read(),
        context: context,
        isCurrent: () =>
            ref.mounted &&
            context.mounted &&
            !editingWorkspace.workspace.closed &&
            ref.read(selectedAuthoringScopeProvider) == initialScope &&
            editingWorkspace.document.generation == base.generation,
      );
      scopeChanges = ref.listen(selectedAuthoringScopeProvider, (_, next) {
        if (next != initialScope) operation.cancel();
      });
      catalogChanged = () {
        if (editingWorkspace.workspace.closed ||
            editingWorkspace.document.generation != base.generation) {
          operation.cancel();
        }
      };
      editingWorkspace.addListener(catalogChanged);
      await operation.resolve(
        request,
        creationContext ??
            CreationContext(
              preferredResources: ambientCreationResources(ref, scope, base),
            ),
      );
      operation.requireReady();
      final result = editingWorkspace.edit(
        label:
            "Create ${base.catalog.typeSelectionName(request.configuration)}",
        apply: operation.apply,
      );
      return switch (result) {
        EditStaged() => AuthoringResourceIdentifier.inScope(scope, request.id),
        EditUnchanged() => throw StateError("Creation produced no changes"),
        EditStageRejected(cause: _CreationCancelled()) => null,
        EditStageRejected(cause: final cause?) => Error.throwWithStackTrace(
          cause,
          StackTrace.current,
        ),
        EditStageRejected(:final message, cause: null) => throw StateError(
          message,
        ),
      };
    } on _CreationCancelled {
      return null;
    } finally {
      if (workspace != null && catalogChanged != null) {
        workspace.removeListener(catalogChanged);
      }
      scopeChanges?.close();
      capabilities?.close();
      editing.close();
    }
  }
}

extension OwnedResourceCreation on ResourceCreationSession {
  /// Creates a resource of [type] that joins the owning link field at
  /// [owner], when given, with [supplied] initial field values, then opens or
  /// selects it as every creation does.
  Future<AuthoringResourceIdentifier?> createOwnedResource({
    required BuildContext context,
    required skir.TypeDefinitionId type,
    skir.ValueLocation? owner,
    List<skir.FieldValue> supplied = const [],
  }) {
    final document = ref.read(realmEditingProvider(scope)).document;
    final template = document.catalog.resourceCreationTemplate(type);
    if (template == null) {
      throw StateError("Resources of this type cannot be created");
    }
    return createAndReveal(
      context: context,
      request: ResourceCreationRequest(
        type: template.type,
        configuration: template.configuration,
        supplied: supplied,
      ),
      creationContext: owner == null
          ? null
          : ownerCreationContext(
              document,
              owner,
              preferredResources: ambientCreationResources(
                ref,
                scope,
                document,
              ),
            ),
    );
  }
}

/// The creation context of a resource that joins the owning link field at
/// [owner], such as the pages of a Book: the created resource must link back
/// to the owner through that field's member endpoint.
CreationContext ownerCreationContext(
  AuthoringDocument document,
  skir.ValueLocation owner, {
  List<skir.ResourceId> preferredResources = const [],
}) {
  final record = document.resource(owner.resource);
  final field = record == null
      ? null
      : document.catalog.owningFieldAt(record.configuration, owner.path);
  if (field == null) {
    throw StateError("New resources cannot join this field");
  }
  return CreationContext(
    preferredResources: [owner.resource, ...preferredResources],
    constraints: [
      CreationReferenceConstraint(
        route: [field.ownership.member.id],
        targets: {owner.resource},
      ),
    ],
  );
}

/// Resources a creation prefers as destinations when it asks for one: the
/// selection in [scope], then the routed resource and its owners.
List<skir.ResourceId> ambientCreationResources(
  Ref ref,
  AuthoringScope scope,
  AuthoringDocument document,
) {
  final routed = ref.read(routedResourceProvider(scope));
  return <skir.ResourceId>{
    ...ref
        .read(selectionProvider)
        .whereType<AuthoringResourceIdentifier>()
        .where((resource) => resource.scope == scope)
        .map((resource) => resource.resourceId),
    if (routed != null) ...[
      routed,
      ...document.relations.ownerPath(routed).owners,
    ],
  }.toList();
}

final class _CreationCancelled implements Exception {
  const _CreationCancelled();
}

@freezed
abstract class _PendingCreation with _$PendingCreation {
  const factory _PendingCreation({
    required ResourceCreationRequest request,
    required CreationContext context,
    required skir.PreparationStep step,
  }) = __PendingCreation;
}

extension on skir.PreparationStep {
  skir.PreparedValue get materialized => switch (this) {
    skir.PreparationStep_readyWrapper(:final value) => value,
    skir.PreparationStep_needsInputWrapper(:final value) ||
    skir.PreparationStep_unavailableWrapper(
      :final value,
    ) => skir.PreparedValue(content: value.content, findings: value.findings),
    skir.PreparationStep_unknown() => throw StateError(
      "Unknown preparation outcome",
    ),
  };
}
