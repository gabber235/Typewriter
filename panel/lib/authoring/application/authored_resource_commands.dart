import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_resource_commands.g.dart";

/// External capabilities. Working value edits belong to the workspace.
@riverpod
AuthoredResourceCommands authoredResourceCommands(
  Ref ref,
  AuthoringScope scope,
) {
  final session = ref.watch(
    authoringSessionProvider(scope.organizationId, scope.realmId).notifier,
  );
  return AuthoredResourceCommands(
    previewTypeArguments: session.previewTypeArguments,
    prepareTypeArguments: (preview) {
      if (ref.read(realmEditingProvider(scope)).hasWorkFor(preview.resource)) {
        throw StateError(
          "Save or discard pending work before changing type arguments",
        );
      }
      return session.prepareTypeArguments(preview);
    },
    prepareValue: session.prepareValue,
    resolveResourceOperations: session.resolveResourceOperations,
    resolveDropCandidates: session.resolveDropCandidates,
    prepareAuthoringAction: session.prepareAuthoringAction,
    prepareStep: session.prepareStep,
    invokeCommand: session.invokeCommand,
    watchSearch: session.watchPresentationSearch,
    search: session.search,
    reload: () => ref.read(realmEditingProvider(scope)).refreshConfirmed(),
  );
}

final class AuthoredResourceCommands {
  const AuthoredResourceCommands({
    required this.previewTypeArguments,
    required this.prepareTypeArguments,
    required this.prepareValue,
    required this.prepareStep,
    required this.invokeCommand,
    required this.watchSearch,
    required this.search,
    required this.reload,
    this.resolveResourceOperations = _operationsUnavailable,
    this.resolveDropCandidates = _dropCandidatesUnavailable,
    this.prepareAuthoringAction = _preparationUnavailable,
  });

  final Future<skir.PreviewTypeArgumentChangeResponse> Function({
    required skir.ResourceId resource,
    required skir.TypeSelection requested,
  })
  previewTypeArguments;
  final Future<skir.PrepareTypeArgumentChangeResponse> Function(
    skir.TypeArgumentChangePreview preview,
  )
  prepareTypeArguments;
  final Future<skir.PrepareValueResult> Function(
    skir.PreparationOperation operation,
  )
  prepareStep;
  final Future<skir.PreparedValue> Function(
    skir.ValuePreparationRequest request,
  )
  prepareValue;
  final Future<skir.CommandResult> Function({
    required skir.CapabilityId capabilityId,
    required skir.DataValue payload,
  })
  invokeCommand;
  final Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest request,
  )
  watchSearch;
  final Future<skir.SearchAuthoringResponse> Function(
    skir.SearchAuthoringRequest request,
  )
  search;
  final Future<skir.ResolveResourceOperationsResult> Function(
    skir.ResolveResourceOperationsRequest request,
  )
  resolveResourceOperations;

  /// Resolves, once per drag, where the dragged resources may land.
  final Future<skir.ResolveDropCandidatesResult> Function(
    skir.ResolveDropCandidatesRequest request,
  )
  resolveDropCandidates;
  final Future<skir.AuthoringActionResult> Function(
    skir.PrepareAuthoringActionRequest request,
  )
  prepareAuthoringAction;
  final Future<void> Function() reload;

  static Future<skir.ResolveResourceOperationsResult> _operationsUnavailable(
    skir.ResolveResourceOperationsRequest request,
  ) async => throw StateError("Resource operations are unavailable");

  static Future<skir.ResolveDropCandidatesResult> _dropCandidatesUnavailable(
    skir.ResolveDropCandidatesRequest request,
  ) async => throw StateError("Drop candidates are unavailable");

  static Future<skir.AuthoringActionResult> _preparationUnavailable(
    skir.PrepareAuthoringActionRequest request,
  ) async => throw StateError("Authoring preparation is unavailable");
}
