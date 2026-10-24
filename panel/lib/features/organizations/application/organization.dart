import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "organization.g.dart";

/// Owns the current user's organization list projection.
///
/// The provider combines an initial snapshot with ordered change events. A
/// duplicate event is ignored, an ordered event updates the projection, and a
/// sequence gap invalidates the stream so the server snapshot can re establish
/// authority. Mutations apply their returned event immediately, avoiding a
/// second request while preserving the same sequence rules.
@riverpod
class Organizations extends _$Organizations {
  final _sequenceState = SequencedCollection<List<skir.Organization>>();

  @override
  Stream<List<skir.Organization>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (!ref.mounted) return;

    if (userId == null) {
      yield [];
      return;
    }

    yield* skir.WatchUserOrganizationsRequest().watch<List<skir.Organization>>(
      ref,
      userId: userId,
      snapshot: (response) => _organizationSnapshot(response).values.toList(),
      reduce: _reduceOrganizations,
      reconciliation: ProjectionReconciliation.sequenced(
        snapshotSequence: (response) =>
            _organizationSnapshot(response).sequence,
        eventSequence: (event) => event.sequence,
        sequenceState: _sequenceState,
      ),
    );
  }

  /// Creates an organization for the authenticated user.
  ///
  /// On success, the returned user scoped change event is applied locally and the
  /// new organization identity is returned for navigation. Rejected responses
  /// become actionable [ApiException] values; unknown or internal responses stay
  /// uncertain so the shared mutation layer can expose recovery state.
  Future<skir.RecordId> createOrganization({
    required String name,
    required String logoUrl,
  }) async {
    state.ensureReady();

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    final request = skir.CreateOrganizationRequest(
      name: name,
      logoUrl: logoUrl,
    );

    debugPrint(
      "Creating organization with name: '$name' and logoUrl: '$logoUrl'",
    );

    final response = await ref.mutateSkir(
      request.operation(userId: userId),
      label: "Create organization",
    );

    switch (response) {
      case skir.CreateOrganizationResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.CreateOrganizationResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.CreateOrganizationResponse_successWrapper(:final value):
        _applyEvent(value.event);
        return value.organization.organizationId;
    }
  }

  void _applyEvent(skir.UserOrganizationsChanged event) {
    switch (_sequenceState.apply(
      sequence: event.sequence,
      reduce: (organizations) => _reduceOrganizations(organizations, event),
    )) {
      case SequencedEventResult.duplicate:
        return;
      case SequencedEventResult.applied:
        state = AsyncData(_sequenceState.value);
      case SequencedEventResult.gap:
        ref.invalidateSelf();
    }
  }
}

skir.UserOrganizationsSnapshot _organizationSnapshot(
  skir.WatchUserOrganizationsResponse response,
) => switch (response) {
  skir.WatchUserOrganizationsResponse_snapshotWrapper(:final value) => value,
  skir.WatchUserOrganizationsResponse_unknown() =>
    throw ApiException.unknownResponseMessage(),
  skir.WatchUserOrganizationsResponse_internalErrorWrapper() =>
    throw ApiException.internalServerError(),
  skir.WatchUserOrganizationsResponse_changedWrapper() => throw StateError(
    "Snapshot request returned a delta",
  ),
};

List<skir.Organization> _reduceOrganizations(
  List<skir.Organization> organizations,
  skir.UserOrganizationsChanged event,
) {
  return event.changes.fold(organizations, (current, change) {
    return switch (change) {
      skir.UserOrganizationsChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.UserOrganizationsChange_addWrapper(:final value) =>
        current.upsertByKey(
          (organization) => organization.organizationId,
          value,
        ),
      skir.UserOrganizationsChange_removeWrapper(:final value) =>
        current
            .where((organization) => organization.organizationId != value)
            .toList(),
    };
  });
}

/// Selects the routed organization from the user's canonical organization list.
///
/// This is a read projection, not a second organization cache. It stays null
/// until the route has an identity or the membership stream contains that
/// identity, which prevents nested pages from using stale organization data.
@riverpod
class Organization extends _$Organization {
  @override
  Future<skir.Organization?> build() async {
    final id = ref.watch(organizationIdProvider);
    if (id == null) {
      return null;
    }
    final organizations = await ref.watch(organizationsProvider.future);
    return organizations.firstWhereOrNull((org) => org.organizationId == id);
  }
}

/// Builds the deterministic placeholder logo URL used during organization setup.
///
/// The seed is derived by the caller from the organization name and a random
/// value. The resulting URL is persisted as display data by the create mutation.
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/webp?seed=$seed";
}
