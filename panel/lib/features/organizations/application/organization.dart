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
  Stream<List<skir.Organization>> build() => ref.watchSignedIn(
    signedOut: const [],
    (userId) =>
        skir.WatchUserOrganizationsRequest().watch<List<skir.Organization>>(
          ref,
          userId: userId,
          snapshot: (response) =>
              _organizationSnapshot(response).values.toList(),
          reduce: _reduceOrganizations,
          reconciliation: ProjectionReconciliation.sequenced(
            snapshotSequence: (response) =>
                _organizationSnapshot(response).sequence,
            eventSequence: (event) => event.sequence,
            sequenceState: _sequenceState,
          ),
        ),
  );

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

  /// Prepares one all or nothing batch of organization [updates].
  ///
  /// The caller's own organization list change from a successful reply is
  /// applied before the reply returns. A refused batch changes nothing; the
  /// caller reads each refused item from the reply. Sending the same request
  /// again is safe, because an update to the stored values changes nothing.
  PreparedCommit<skir.UpdateOrganizationsResponse> prepareUpdate(
    List<skir.OrganizationUpdate> updates,
  ) {
    final userId =
        ref.read(userIdProvider).value ??
        (throw ApiException.notAuthenticated());
    return ref.prepareSkir(
      skir.UpdateOrganizationsRequest(updates: updates)
          .operation(userId: userId),
      label: updates.length == 1
          ? "Update organization"
          : "Update ${updates.length} organizations",
      resources: {for (final update in updates) update.organizationId},
      replay: SubmissionReplay.identicalRequest,
      onResponse: (response) async {
        if (response case skir.UpdateOrganizationsResponse_successWrapper(
          :final value,
        )) {
          _applyEvent(value.event);
        }
      },
    );
  }

  /// Prepares the deletion of every one of [organizations], or none of them.
  ///
  /// A successful reply applies the caller's own organization list change,
  /// so the deleted organizations leave the list at once.
  PreparedCommit<skir.DeleteOrganizationsResponse> prepareDelete(
    Set<skir.RecordId> organizations,
  ) {
    final userId =
        ref.read(userIdProvider).value ??
        (throw ApiException.notAuthenticated());
    return ref.prepareSkir(
      skir.DeleteOrganizationsRequest(organizationIds: organizations.toList())
          .operation(userId: userId),
      label: organizations.length == 1
          ? "Delete organization"
          : "Delete ${organizations.length} organizations",
      resources: organizations,
      onResponse: (response) async {
        if (response case skir.DeleteOrganizationsResponse_successWrapper(
          :final value,
        )) {
          _applyEvent(value.event);
        }
      },
    );
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
      skir.UserOrganizationsChange_addWrapper(:final value) ||
      skir.UserOrganizationsChange_updateWrapper(
        :final value,
      ) => current.upsertByKey(
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

/// Organization commands sent through the local work owner, which the
/// organization list itself cannot reach: the owner depends on the open
/// organization, which depends on that list.
extension OrganizationCommands on WidgetRef {
  /// Changes the icon of [organization] to [logoUrl].
  ///
  /// A refusal throws a [ShownFailure] that says why in plain words.
  Future<void> changeOrganizationIcon(
    skir.RecordId organization,
    String logoUrl,
  ) async {
    final response = await read(localWorkControllerProvider).execute(
      read(organizationsProvider.notifier).prepareUpdate([
        skir.OrganizationUpdate(
          organizationId: organization,
          name: null,
          logoUrl: logoUrl,
        ),
      ]),
    );
    switch (response) {
      case skir.UpdateOrganizationsResponse_successWrapper():
        return;
      case skir.UpdateOrganizationsResponse_refusedErrorWrapper(:final value):
        throw OrganizationRefusal(
          value.firstOrNull?.reason.message ??
              "The organization was not changed.",
        );
      case skir.UpdateOrganizationsResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.UpdateOrganizationsResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }

  /// Deletes every one of [organizations], or none of them.
  ///
  /// A refusal throws [RefusedTargets] naming the refused organizations
  /// with the first reason.
  Future<void> deleteOrganizations(Set<skir.RecordId> organizations) async {
    final response = await read(localWorkControllerProvider).execute(
      read(organizationsProvider.notifier).prepareDelete(organizations),
    );
    switch (response) {
      case skir.DeleteOrganizationsResponse_successWrapper():
        return;
      case skir.DeleteOrganizationsResponse_refusedErrorWrapper(:final value):
        throw RefusedTargets(
          OrganizationRefusal(
            value.firstOrNull?.reason.message ??
                "The organization was not deleted.",
          ),
          {for (final refused in value) refused.organizationId},
        );
      case skir.DeleteOrganizationsResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.DeleteOrganizationsResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }
}

/// Whether [userId] founded this organization; only the founder may delete
/// it.
extension OrganizationFounder on skir.Organization {
  bool foundedBy(String? userId) => userId != null && founderId.id == userId;
}

/// A change the backend refused, said in plain words.
final class OrganizationRefusal implements ShownFailure {
  const OrganizationRefusal(this.message);

  @override
  final String message;

  @override
  String toString() => message;
}

/// What an update refusal means, in plain words with the next step.
extension OrganizationUpdateRefusalMessage on skir.OrganizationUpdateRefusal {
  String get message => switch (this) {
    skir.OrganizationUpdateRefusal_nameTakenErrorWrapper() =>
      "Another organization already uses this name. Choose another name.",
    skir.OrganizationUpdateRefusal_nameInvalidErrorWrapper() =>
      organizationNameRule,
    skir.OrganizationUpdateRefusal_logoUrlInvalidErrorWrapper() =>
      "This icon address is not a web address. Pick another icon.",
    skir.OrganizationUpdateRefusal_organizationNotFoundErrorWrapper() =>
      "This organization no longer exists, or you are no longer a member.",
    skir.OrganizationUpdateRefusal_duplicateErrorWrapper() =>
      "This organization was changed twice in one change.",
    skir.OrganizationUpdateRefusal_invalidRecordIdErrorWrapper() ||
    skir.OrganizationUpdateRefusal_unknown() =>
      "The organization could not be changed. Try again.",
  };
}

/// What a delete refusal means, in plain words with the next step.
extension OrganizationDeleteRefusalMessage on skir.OrganizationDeleteRefusal {
  String get message => switch (this) {
    skir.OrganizationDeleteRefusal_founderRequiredErrorWrapper() =>
      onlyFounderDeletes,
    skir.OrganizationDeleteRefusal_organizationNotFoundErrorWrapper() =>
      "This organization no longer exists, or you are no longer a member.",
    skir.OrganizationDeleteRefusal_duplicateErrorWrapper() =>
      "This organization was named twice in one change.",
    skir.OrganizationDeleteRefusal_invalidRecordIdErrorWrapper() ||
    skir.OrganizationDeleteRefusal_unknown() =>
      "The organization could not be deleted. Try again.",
  };
}

/// Why someone who did not found an organization cannot delete it.
const onlyFounderDeletes = "Only the founder can delete this organization.";

/// The rule an organization name follows, as a person reads it.
const organizationNameRule =
    "Use at least three lowercase letters or digits, with underscores only "
    "between them.";

/// Builds the deterministic placeholder logo URL used during organization setup.
///
/// The seed is derived by the caller from the organization name and a random
/// value. The resulting URL is persisted as display data by the create mutation.
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/webp?seed=$seed";
}
