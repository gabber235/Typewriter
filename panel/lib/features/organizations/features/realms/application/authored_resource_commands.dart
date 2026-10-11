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
      if (ref
          .read(authoringWorkspaceProvider(scope))
          .hasWorkFor(preview.resource)) {
        throw StateError(
          "Save or discard pending work before changing type arguments",
        );
      }
      return session.prepareTypeArguments(preview);
    },
    prepareValue: session.prepareValue,
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
    required this.prepareTypeArguments,
    required this.prepareValue,
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
  final Future<skir.PreparedEditResult> Function(
    skir.TypeArgumentChangePreview preview,
  )
  prepareTypeArguments;
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
  final Future<void> Function() reload;
}
