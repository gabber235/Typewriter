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
    commitTypeArguments: (preview) {
      if (ref
          .read(authoringWorkspaceProvider(scope))
          .hasWorkFor(preview.resource)) {
        throw StateError(
          "Save or discard pending work before changing type arguments",
        );
      }
      return session.commitTypeArguments(preview);
    },
    prepareCreation: session.prepareCreation,
    invokeCommand: session.invokeCommand,
    watchSearch: session.watchPresentationSearch,
    search: session.search,
    reload: () =>
        ref.read(authoringWorkspaceProvider(scope)).refreshConfirmed(),
  );
}

final class AuthoredResourceCommands {
  const AuthoredResourceCommands({
    required this.previewTypeArguments,
    required this.commitTypeArguments,
    required this.prepareCreation,
    required this.invokeCommand,
    required this.watchSearch,
    required this.search,
    required this.reload,
  });

  final Future<skir.TypePreviewResult> Function({
    required skir.ResourceId resource,
    required skir.TypeSelection requested,
  })
  previewTypeArguments;
  final Future<skir.CommitTypeArgumentChangeResponse> Function(
    skir.TypeArgumentChangePreview preview,
  )
  commitTypeArguments;
  final Future<skir.PreparedCreation> Function(
    skir.InitializationRequest request,
  )
  prepareCreation;
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
  final Future<void> Function() reload;
}
