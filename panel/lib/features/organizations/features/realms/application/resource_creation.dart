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

@freezed
abstract class ResourceCreationRequest with _$ResourceCreationRequest {
  factory ResourceCreationRequest({
    required skir.ResourceDefinitionId definition,
    required skir.TypeSelection configuration,
    skir.ResourceId? id,
    List<skir.FieldValue> supplied = const [],
  }) => ResourceCreationRequest.data(
    id: id ?? skir.newResourceId(),
    definition: definition,
    configuration: configuration,
    supplied: supplied,
  );
  const factory ResourceCreationRequest.data({
    required skir.ResourceId id,
    required skir.ResourceDefinitionId definition,
    required skir.TypeSelection configuration,
    @Default([]) List<skir.FieldValue> supplied,
  }) = _ResourceCreationRequest;
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

/// Coordinates one creation action without publishing its unfinished dependencies.
/// Each invocation owns its draft; the shared provider holds no mutable session.
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
              preferredResources: <skir.ResourceId>{
                ...ref
                    .read(selectionProvider)
                    .whereType<AuthoringResourceIdentifier>()
                    .where((resource) => resource.scope == scope)
                    .map((resource) => resource.resourceId),
                ?ref.read(pageIdProvider),
                ?ref.read(bookIdProvider),
              }.toList(),
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
