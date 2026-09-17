import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "members.freezed.dart";
part "members.g.dart";

/// Client model for one organization member.
///
/// The server projection is authoritative. The nullable profile fields are
/// observations supplied by the identity system, while [roles] and [joinedAt]
/// describe the membership projection. Conversion methods keep the UI model
/// separate from generated protocol values.
@freezed
abstract class OrganizationMember with _$OrganizationMember {
  const factory OrganizationMember({
    required skir.RecordId userId,
    required List<OrganizationRole> roles,
    required DateTime joinedAt,
    String? name,
    String? email,
    String? avatarUrl,
  }) = _OrganizationMember;

  const OrganizationMember._();

  factory OrganizationMember.fromSkir(skir.OrganizationMember member) =>
      OrganizationMember(
        userId: member.userId,
        name: member.name,
        email: member.email,
        avatarUrl: member.avatarUrl,
        roles: member.roles.map(OrganizationRole.fromSkir).toList(),
        joinedAt: member.joinedAt,
      );

  skir.OrganizationMember toSkir() => skir.OrganizationMember(
    userId: this.userId,
    name: name,
    email: email,
    avatarUrl: avatarUrl,
    roles: roles.map((r) => r.toSkir()),
    joinedAt: joinedAt,
  );
}

/// Owns the current organization's member projection and its mutations.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap or failed mutation makes the local
/// projection unsafe to trust. A successful mutation applies the returned
/// event, so consumers observe the same change stream as remote updates.
@riverpod
class OrganizationMembers extends _$OrganizationMembers {
  @protected
  final sequencedCollection = SequencedCollection<List<OrganizationMember>>();

  @override
  Stream<List<OrganizationMember>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (!ref.mounted) return;

    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationMembersRequest();
    yield* ref.watchSequencedRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.members.watch",
      eventSubject:
          "cloud.from.organization.${organizationId.id}.members.changed",
      requestBytes: skir.WatchOrganizationMembersRequest.serializer.toBytes(
        request,
      ),
      responseSerializer: skir.WatchOrganizationMembersResponse.serializer,
      eventSerializer: skir.OrganizationMembersChanged.serializer,
      snapshot: (response) {
        return switch (response) {
          skir.WatchOrganizationMembersResponse_unknown() =>
            throw ApiException.unknownResponseMessage(),
          skir.WatchOrganizationMembersResponse_internalErrorWrapper() =>
            throw ApiException.internalServerError(),
          skir.WatchOrganizationMembersResponse_snapshotWrapper(:final value) =>
            SequencedSnapshot(
              sequence: value.sequence,
              value: value.values.map(OrganizationMember.fromSkir).toList(),
            ),
          skir.WatchOrganizationMembersResponse_changedWrapper() =>
            throw StateError("Snapshot request returned a delta"),
        };
      },
      eventSequence: (event) => event.sequence,
      reduce: _reduceMembers,
      sequenceState: sequencedCollection,
    );
  }

  /// Preserves protected roles while normalizing an editor's assignable role
  /// choice. If the choice would leave a member without roles, returns the
  /// organization's default role instead of emitting an invalid request.
  Future<List<OrganizationRole>> ensureCorrectRoles(
    skir.RecordId memberId,
    List<OrganizationRole> newRoles,
  ) async {
    final oldRoles =
        state.requireValue
            .firstWhereOrNull((m) => m.userId == memberId)
            ?.roles ??
        [];

    final roles = {
      ...oldRoles.where((r) => !r.assignable),
      ...newRoles.where((r) => r.assignable),
    };

    if (roles.isEmpty) {
      final availableRoles = await ref.read(organizationRolesProvider.future);
      final defaultRoles = availableRoles
          .where((role) => role.defaultRole)
          .toList();
      assert(defaultRoles.isNotEmpty, "No default roles available.");
      return defaultRoles;
    }

    return roles.toList();
  }

  /// Submits one role selection for all [memberIds].
  ///
  /// Protected roles are retained by the server and only assignable roles from
  /// [requestedRoles] cross the mutation boundary. The request is replay safe
  /// for identical input. Rejected or uncertain delivery invalidates this
  /// provider, forcing recovery from a fresh snapshot rather than preserving a
  /// possibly stale projection.
  ///
  /// The server treats the selection as one transaction, so callers do not need
  /// to compensate for a partial role update.
  Future<void> updateMemberRoles(
    Iterable<skir.RecordId> memberIds,
    List<OrganizationRole> requestedRoles,
  ) async {
    final ids = List<skir.RecordId>.unmodifiable(memberIds);
    final requested = List<OrganizationRole>.unmodifiable(requestedRoles);
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    try {
      final request = skir.UpdateOrganizationMemberRolesRequest(
        operationId: uuid.v4(),
        userIds: ids,
        roleIds: requested
            .where((role) => role.assignable)
            .map((role) => role.roleId),
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.update",
        skir.UpdateOrganizationMemberRolesRequest.serializer.toBytes(request),
        skir.UpdateOrganizationMemberRolesResponse.serializer,
        onResponse: (response) async {
          if (!ref.mounted ||
              ref.read(organizationIdProvider) != organizationId) {
            return;
          }
          if (response
              case skir.UpdateOrganizationMemberRolesResponse_successWrapper(
                :final value,
              )) {
            _applyEvent(value.event);
          }
        },
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Update member roles",
        resources: {for (final id in ids) (organizationId, id)},
        classify: (response) => switch (response) {
          skir.UpdateOrganizationMemberRolesResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.UpdateOrganizationMemberRolesResponse_unknown() ||
          skir.UpdateOrganizationMemberRolesResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.UpdateOrganizationMemberRolesResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdateOrganizationMemberRolesResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdateOrganizationMemberRolesResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.UpdateOrganizationMemberRolesResponse_userNotFoundErrorWrapper():
          throw ApiException.notFound("User");
        case skir.UpdateOrganizationMemberRolesResponse_rolesNotFoundErrorWrapper():
          throw ApiException.notFound("Roles");
        case skir.UpdateOrganizationMemberRolesResponse_rolesNotAssignableErrorWrapper():
          throw ApiException.badRequest("One or more roles cannot be assigned");
        case skir.UpdateOrganizationMemberRolesResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.UpdateOrganizationMemberRolesResponse_invalidSelectionErrorWrapper():
          throw ApiException.badRequest("Select distinct organization members");
        case skir.UpdateOrganizationMemberRolesResponse_rolesRequiredErrorWrapper():
          throw ApiException.badRequest("At least one role is required");
        case skir.UpdateOrganizationMemberRolesResponse_founderRoleRequiredErrorWrapper():
          throw ApiException.conflict(
            "Organization must retain at least one founder",
          );
        case skir.UpdateOrganizationMemberRolesResponse_successWrapper():
          break;
      }
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Removes [memberId] through the organization mutation boundary.
  ///
  /// Success is reflected by the returned sequenced event. A missing member or
  /// protected founder is reported as an [ApiException]. Unknown or internal
  /// responses invalidate the local projection so the next read can recover
  /// from the server's membership snapshot.
  Future<void> removeMember(skir.RecordId memberId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();

    try {
      final request = skir.RemoveOrganizationMemberRequest(
        operationId: uuid.v4(),
        userId: memberId,
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.remove",
        skir.RemoveOrganizationMemberRequest.serializer.toBytes(request),
        skir.RemoveOrganizationMemberResponse.serializer,
        onResponse: (response) async {
          if (!ref.mounted ||
              ref.read(organizationIdProvider) != organizationId) {
            return;
          }
          if (response
              case skir.RemoveOrganizationMemberResponse_successWrapper(
                :final value,
              )) {
            _applyEvent(value.event);
          }
        },
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label:
            "Remove member: ${state.requireValue.firstWhereOrNull((member) => member.userId == memberId)?.name ?? memberId.id}",
        resources: {(organizationId, memberId)},
        classify: (response) => switch (response) {
          skir.RemoveOrganizationMemberResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.RemoveOrganizationMemberResponse_unknown() ||
          skir.RemoveOrganizationMemberResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.RemoveOrganizationMemberResponse_invalidOperationIdErrorWrapper():
          throw ApiException.badRequest("Operation identity is required");
        case skir.RemoveOrganizationMemberResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.RemoveOrganizationMemberResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.RemoveOrganizationMemberResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.RemoveOrganizationMemberResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.RemoveOrganizationMemberResponse_userNotMemberErrorWrapper():
          throw ApiException.notFound("Organization member");
        case skir.RemoveOrganizationMemberResponse_founderCannotBeRemovedErrorWrapper():
          throw ApiException.conflict("Organization founder cannot be removed");
        case skir.RemoveOrganizationMemberResponse_successWrapper():
          break;
      }
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Applies a server event only when its sequence advances the local projection.
  /// Duplicate events are harmless. A gap discards the projection and requests a
  /// new snapshot because the missing changes cannot be reconstructed locally.
  void _applyEvent(skir.OrganizationMembersChanged event) {
    switch (sequencedCollection.apply(
      sequence: event.sequence,
      reduce: (members) => _reduceMembers(members, event),
    )) {
      case SequencedEventResult.duplicate:
        return;
      case SequencedEventResult.applied:
        state = AsyncData(sequencedCollection.value);
      case SequencedEventResult.gap:
        ref.invalidateSelf();
    }
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<OrganizationMember>> previous,
    AsyncValue<List<OrganizationMember>> next,
  ) => true;
}

/// Reduces complete add and update values, plus identity only removals, into
/// the immutable member list used by the provider state.
List<OrganizationMember> _reduceMembers(
  List<OrganizationMember> members,
  skir.OrganizationMembersChanged event,
) {
  return event.changes.fold(members, (current, change) {
    return switch (change) {
      skir.OrganizationMembersChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationMembersChange_addWrapper(:final value) ||
      skir.OrganizationMembersChange_updateWrapper(
        :final value,
      ) => current.upsertByKey(
        (member) => member.userId,
        OrganizationMember.fromSkir(value),
      ),
      skir.OrganizationMembersChange_removeWrapper(:final value) =>
        current.where((member) => member.userId != value).toList(),
    };
  });
}
