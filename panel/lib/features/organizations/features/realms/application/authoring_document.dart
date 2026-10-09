part of "authoring_workspace.dart";

/// A complete immutable observation, paired with the catalog that interprets it.
///
/// Display queries use this value without collecting save expectations. Resource
/// definitions and unfinished authored values survive every working publication.
@freezed
abstract class AuthoringDocument
    with _$AuthoringDocument
    implements PortableAuthoringView {
  const factory AuthoringDocument({
    required CheckedEditorCatalog catalog,
    required Map<skir.ResourceId, skir.AuthoringResource> entries,
    required List<skir.LinkProjection> links,
    @Default(0) int revision,
    @Default([]) List<skir.InitializationDiagnostic> initializationFindings,
  }) = _AuthoringDocument;

  const AuthoringDocument._();

  factory AuthoringDocument.fromState(
    skir.AuthoringState state, {
    required CheckedEditorCatalog catalog,
  }) {
    if (state.generation != catalog.snapshot.generation) {
      throw StateError("The authoring state and catalog do not match");
    }
    return AuthoringDocument(
      catalog: catalog,
      entries: Map.unmodifiable({
        for (final entry in state.resources) entry.id: entry,
      }),
      links: List.unmodifiable(state.links),
    );
  }

  @override
  skir.CatalogGeneration get generation => catalog.snapshot.generation;
  skir.AuthoringResource? entry(skir.ResourceId id) => entries[id];
  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => entries[id]?.content;
  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources => Map.unmodifiable({
    for (final entry in entries.entries) entry.key: entry.value.content,
  });
  @override
  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _AuthoringDefaults(catalog)._defaultForType(type, const {});
  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      resource(location.resource)?.readAt(location.path) ??
      const PortablePathUnavailable("The resource is absent");
}

@freezed
abstract class AuthoringScope with _$AuthoringScope {
  const factory AuthoringScope({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
  }) = _AuthoringScope;
}

@freezed
abstract class AuthoringGroupId with _$AuthoringGroupId {
  const factory AuthoringGroupId(int value) = _AuthoringGroupId;
}

@freezed
sealed class AuthoringGroupPhase with _$AuthoringGroupPhase {
  const factory AuthoringGroupPhase.dirty() = AuthoringGroupDirty;
  const factory AuthoringGroupPhase.awaitingDependency(
    Set<AuthoringGroupId> groups,
  ) = AuthoringGroupAwaitingDependency;
  const factory AuthoringGroupPhase.saving() = AuthoringGroupSaving;
  const factory AuthoringGroupPhase.committedAwaitingRefresh(Object? cause) =
      AuthoringGroupCommittedAwaitingRefresh;
  const factory AuthoringGroupPhase.conflict(
    String message,
    skir.EditExpectation? expected,
    skir.EditExpectation? actual,
  ) = AuthoringGroupConflict;
  const factory AuthoringGroupPhase.rejected(String message, Object? cause) =
      AuthoringGroupRejected;
  const factory AuthoringGroupPhase.catalogChanged() =
      AuthoringGroupCatalogChanged;
  const factory AuthoringGroupPhase.uncertain(Object cause) =
      AuthoringGroupUncertain;
  const factory AuthoringGroupPhase.resourceMissing(
    skir.ResourceId resource,
    AuthoringDocument proposal,
  ) = AuthoringGroupResourceMissing;
}

extension AuthoringGroupPhaseDisplay on AuthoringGroupPhase {
  bool get blocked =>
      this is! AuthoringGroupDirty &&
      this is! AuthoringGroupAwaitingDependency &&
      this is! AuthoringGroupSaving;
  String get message => switch (this) {
    AuthoringGroupDirty() => "Changes await saving",
    AuthoringGroupAwaitingDependency() =>
      "Waiting for related pending changes. Apply or discard that work first",
    AuthoringGroupSaving() => "Saving",
    AuthoringGroupCommittedAwaitingRefresh() => "Changes were saved. Current Realm values are unavailable; later edits remain local",
    AuthoringGroupConflict(:final message) ||
    AuthoringGroupRejected(:final message) => message,
    AuthoringGroupCatalogChanged() =>
      "The editor catalog changed. Review or discard pending work",
    AuthoringGroupUncertain() => "The save outcome is unknown. Local work is retained and will not be resubmitted",
    AuthoringGroupResourceMissing() =>
      "The resource was removed. Its proposal is retained for comparison",
  };
}

@freezed
abstract class AuthoringGroup with _$AuthoringGroup {
  const factory AuthoringGroup({
    required AuthoringGroupId id,
    required String label,
    required EditorCommitPolicy policy,
    required AuthoringGroupPhase phase,
    required Set<skir.ResourceId> resources,
    required int operationCount,
    required AuthoringDocument original,
  }) = _AuthoringGroup;
}

@freezed
abstract class AuthoringWorkspaceState with _$AuthoringWorkspaceState {
  const factory AuthoringWorkspaceState({
    AuthoringDocument? confirmed,
    AuthoringDocument? working,
    @Default({}) Map<AuthoringGroupId, AuthoringGroup> groups,
    Object? failure,
  }) = _AuthoringWorkspaceState;
}

@freezed
sealed class AuthoringEditResult with _$AuthoringEditResult {
  const factory AuthoringEditResult.staged(AuthoringGroupId group) =
      AuthoringEditStaged;
  const factory AuthoringEditResult.unchanged() = AuthoringEditUnchanged;
  const factory AuthoringEditResult.rejected(String message, Object? cause) =
      AuthoringEditRejected;
}

/// Makes rejected operations visible to callers that already present failures.
extension AuthoringEditOutcome on AuthoringEditResult {
  void requireAccepted() {
    if (this case AuthoringEditRejected(:final message)) {
      throw StateError(message);
    }
  }

  void report(BuildContext context) {
    if (this case AuthoringEditRejected(:final message)) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
