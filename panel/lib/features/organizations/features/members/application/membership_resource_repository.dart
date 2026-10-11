part of "members.dart";

/// Owns membership command preparation and confirmed projection facts.
final class MembershipResourceRepository {
  MembershipResourceRepository(this.session, this.organization);

  final ResourceRepositories session;
  final skir.RecordId organization;
  final _members = StreamController<skir.OrganizationMembersChanged>.broadcast(
    sync: true,
  );
  final _requests =
      StreamController<skir.OrganizationJoinRequestsChanged>.broadcast(
        sync: true,
      );
  final _codes = StreamController<skir.OrganizationJoinCodesChanged>.broadcast(
    sync: true,
  );
  final _removals = <Object, (MembershipRemovalKind, skir.RecordId)>{};
  var _disposed = false;

  Stream<skir.OrganizationMembersChanged> get members => _members.stream;
  Stream<skir.OrganizationJoinRequestsChanged> get requests => _requests.stream;
  Stream<skir.OrganizationJoinCodesChanged> get codes => _codes.stream;

  (MembershipRemovalKind, skir.RecordId)? removalFor(Object submission) =>
      _removals[submission];

  void checkActive() {
    session.checkActive();
    if (_disposed) throw StateError("The membership resource session ended");
  }

  String get _userId {
    checkActive();
    return session.requireUserId();
  }

  PreparedCommit<skir.ApproveOrganizationJoinRequestsResponse> approve(
    Iterable<skir.RecordId> requestIds,
    List<OrganizationRole> roles,
  ) {
    final ids = List<skir.RecordId>.unmodifiable(requestIds);
    final selectedRoles = List<OrganizationRole>.unmodifiable(roles);
    final request = skir.ApproveOrganizationJoinRequestsRequest(
      requestIds: ids,
      roleIds: selectedRoles.map((role) => role.roleId),
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Approve membership",
      resources: {for (final id in ids) (organization, id)},
      classify: _classifyApprove,
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.ApproveOrganizationJoinRequestsResponse_successWrapper(
              :final value,
            )) {
          _requests.add(value.joinRequestsEvent);
          _members.add(value.membersEvent);
        }
      },
    );
  }

  PreparedCommit<skir.DeclineOrganizationJoinRequestResponse> decline(
    skir.RecordId requestId,
  ) {
    final submissionId = uuid.v4();
    final request = skir.DeclineOrganizationJoinRequestRequest(
      requestId: requestId,
    );
    _removals[submissionId] = (MembershipRemovalKind.joinRequest, requestId);
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      submissionId: submissionId,
      label: "Decline membership",
      resources: {(organization, requestId)},
      classify: _classifyDecline,
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.DeclineOrganizationJoinRequestResponse_successWrapper(
              :final value,
            )) {
          _requests.add(value.event);
        }
      },
    );
  }

  PreparedCommit<skir.GenerateOrganizationJoinCodeResponse> generate({
    JoinCodeOptions options = const JoinCodeOptions(),
  }) {
    final request = skir.GenerateOrganizationJoinCodeRequest(
      singleUse: options.singleUse,
      expiration: switch (options.expiration) {
        JoinCodeExpirationNever() =>
          skir.GenerateOrganizationJoinCodeRequest_Expiration.never,
        JoinCodeExpirationDuration(:final duration) =>
          skir.GenerateOrganizationJoinCodeRequest_Expiration.createDuration(
            milliseconds: duration.inMilliseconds,
          ),
      },
      autoAccept: skir.GenerateOrganizationJoinCodeRequest_AutoAccept(
        roleIds: options.autoAcceptRoleIds,
      ),
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Generate join code",
      classify: _classifyGenerate,
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.GenerateOrganizationJoinCodeResponse_successWrapper(
              :final value,
            )) {
          _codes.add(value.event);
        }
      },
    );
  }

  PreparedCommit<skir.RevokeOrganizationJoinCodeResponse> revoke(
    skir.RecordId codeId,
  ) {
    final submissionId = uuid.v4();
    final request = skir.RevokeOrganizationJoinCodeRequest(codeId: codeId);
    _removals[submissionId] = (MembershipRemovalKind.joinCode, codeId);
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      submissionId: submissionId,
      label: "Revoke join code",
      resources: {(organization, codeId)},
      classify: _classifyRevoke,
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.RevokeOrganizationJoinCodeResponse_successWrapper(
              :final value,
            )) {
          _codes.add(value.event);
        }
      },
    );
  }

  PreparedCommit<skir.UpdateOrganizationMemberRolesResponse> updateRoles(
    Iterable<skir.RecordId> memberIds,
    List<OrganizationRole> requestedRoles,
  ) {
    final ids = List<skir.RecordId>.unmodifiable(memberIds);
    final roles = List<OrganizationRole>.unmodifiable(requestedRoles);
    final request = skir.UpdateOrganizationMemberRolesRequest(
      userIds: ids,
      roleIds: roles
          .where((role) => role.assignable)
          .map((role) => role.roleId),
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Update member roles",
      resources: {for (final id in ids) (organization, id)},
      classify: _classifyUpdate,
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.UpdateOrganizationMemberRolesResponse_successWrapper(
              :final value,
            )) {
          _members.add(value.event);
        }
      },
    );
  }

  PreparedCommit<skir.RemoveOrganizationMemberResponse> remove(
    skir.RecordId memberId,
  ) {
    final request = skir.RemoveOrganizationMemberRequest(userId: memberId);
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Remove member",
      resources: {(organization, memberId)},
      classify: _classifyRemove,
      onResponse: (response) async {
        checkActive();
        if (response case skir.RemoveOrganizationMemberResponse_successWrapper(
          :final value,
        )) {
          _members.add(value.event);
        }
      },
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _removals.clear();
    unawaited(_members.close());
    unawaited(_requests.close());
    unawaited(_codes.close());
  }
}

enum MembershipRemovalKind { joinRequest, joinCode }

MutationResponseDisposition _classifyApprove(
  skir.ApproveOrganizationJoinRequestsResponse response,
) => switch (response) {
  skir.ApproveOrganizationJoinRequestsResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.ApproveOrganizationJoinRequestsResponse_unknown() ||
  skir.ApproveOrganizationJoinRequestsResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};

MutationResponseDisposition _classifyDecline(
  skir.DeclineOrganizationJoinRequestResponse response,
) => switch (response) {
  skir.DeclineOrganizationJoinRequestResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.DeclineOrganizationJoinRequestResponse_unknown() ||
  skir.DeclineOrganizationJoinRequestResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};

MutationResponseDisposition _classifyGenerate(
  skir.GenerateOrganizationJoinCodeResponse response,
) => switch (response) {
  skir.GenerateOrganizationJoinCodeResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.GenerateOrganizationJoinCodeResponse_unknown() ||
  skir.GenerateOrganizationJoinCodeResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};

MutationResponseDisposition _classifyRevoke(
  skir.RevokeOrganizationJoinCodeResponse response,
) => switch (response) {
  skir.RevokeOrganizationJoinCodeResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.RevokeOrganizationJoinCodeResponse_unknown() ||
  skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};

MutationResponseDisposition _classifyUpdate(
  skir.UpdateOrganizationMemberRolesResponse response,
) => switch (response) {
  skir.UpdateOrganizationMemberRolesResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.UpdateOrganizationMemberRolesResponse_unknown() ||
  skir.UpdateOrganizationMemberRolesResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};

MutationResponseDisposition _classifyRemove(
  skir.RemoveOrganizationMemberResponse response,
) => switch (response) {
  skir.RemoveOrganizationMemberResponse_successWrapper() =>
    MutationResponseDisposition.confirmed,
  skir.RemoveOrganizationMemberResponse_unknown() ||
  skir.RemoveOrganizationMemberResponse_internalErrorWrapper() =>
    MutationResponseDisposition.uncertain,
  _ => MutationResponseDisposition.rejected,
};
