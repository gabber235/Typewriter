part of "members.dart";

/// The membership command owner for one organization in the current resource
/// session. Repeated reads share the repository and its mutation boundary.
@Riverpod(keepAlive: true)
MembershipResourceRepository membershipResourceRepository(
  Ref ref,
  skir.RecordId organization,
) {
  final repository = MembershipResourceRepository(
    ref.watch(resourceSessionProvider),
    organization,
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Owns membership command preparation and confirmed projection facts.
///
/// Each method freezes a request for the local work controller to submit later.
/// Accepted replies publish their captured events through the same sequenced
/// projections as broker delivery. These streams do not replay earlier events.
/// Repository lifetime follows [ResourceSession], while [organization]
/// fixes the scope for every prepared command.
final class MembershipResourceRepository {
  MembershipResourceRepository(this.session, this.organization);

  final ResourceSession session;
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
  var _disposed = false;

  Stream<skir.OrganizationMembersChanged> get members => _members.stream;
  Stream<skir.OrganizationJoinRequestsChanged> get requests => _requests.stream;
  Stream<skir.OrganizationJoinCodesChanged> get codes => _codes.stream;

  void checkActive() {
    session.checkActive();
    if (_disposed) throw StateError("The membership resource session ended");
  }

  String get _userId {
    checkActive();
    return session.requireUserId();
  }

  /// Approves every request in [approvals], each with the roles its new
  /// member receives, in one all or nothing change.
  PreparedCommit<skir.ApproveOrganizationJoinRequestsResponse> approve(
    Map<skir.RecordId, List<skir.OrganizationRole>> approvals,
  ) {
    final request = skir.ApproveOrganizationJoinRequestsRequest(
      approvals: [
        for (final MapEntry(key: requestId, value: roles) in approvals.entries)
          skir.OrganizationJoinRequestApproval(
            requestId: requestId,
            roleIds: roles.map((role) => role.roleId),
          ),
      ],
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Approve membership",
      resources: {for (final id in approvals.keys) (organization, id)},
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

  /// Declines every request in [requestIds] in one all or nothing change.
  PreparedCommit<skir.DeclineOrganizationJoinRequestsResponse> decline(
    Iterable<skir.RecordId> requestIds,
  ) {
    final ids = List<skir.RecordId>.unmodifiable(requestIds);
    final request = skir.DeclineOrganizationJoinRequestsRequest(
      requestIds: ids,
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      submissionId: uuid.v4(),
      label: "Decline membership",
      resources: {for (final id in ids) (organization, id)},
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.DeclineOrganizationJoinRequestsResponse_successWrapper(
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

  /// Revokes every code in [codeIds] in one all or nothing change.
  PreparedCommit<skir.RevokeOrganizationJoinCodesResponse> revoke(
    Iterable<skir.RecordId> codeIds,
  ) {
    final ids = List<skir.RecordId>.unmodifiable(codeIds);
    final request = skir.RevokeOrganizationJoinCodesRequest(codeIds: ids);
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      submissionId: uuid.v4(),
      label: "Revoke join code",
      resources: {for (final id in ids) (organization, id)},
      onResponse: (response) async {
        checkActive();
        if (response
            case skir.RevokeOrganizationJoinCodesResponse_successWrapper(
              :final value,
            )) {
          _codes.add(value.event);
        }
      },
    );
  }

  /// Gives each member in [assignments] its own assignable roles, keeping
  /// protected roles, in one all or nothing change.
  PreparedCommit<skir.UpdateOrganizationMemberRolesResponse> updateRoles(
    Map<skir.RecordId, List<skir.OrganizationRole>> assignments,
  ) {
    final request = skir.UpdateOrganizationMemberRolesRequest(
      assignments: [
        for (final MapEntry(key: userId, value: roles) in assignments.entries)
          skir.OrganizationMemberRoleAssignment(
            userId: userId,
            roleIds: roles
                .where((role) => role.assignable)
                .map((role) => role.roleId),
          ),
      ],
    );
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Update member roles",
      resources: {for (final id in assignments.keys) (organization, id)},
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

  /// Removes every member in [memberIds] in one all or nothing change.
  PreparedCommit<skir.RemoveOrganizationMembersResponse> remove(
    Iterable<skir.RecordId> memberIds,
  ) {
    final ids = List<skir.RecordId>.unmodifiable(memberIds);
    final request = skir.RemoveOrganizationMembersRequest(userIds: ids);
    return session.transport.prepare(
      request.operation(userId: _userId, organizationId: organization),
      label: "Remove member",
      resources: {for (final id in ids) (organization, id)},
      onResponse: (response) async {
        checkActive();
        if (response case skir.RemoveOrganizationMembersResponse_successWrapper(
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
    unawaited(_members.close());
    unawaited(_requests.close());
    unawaited(_codes.close());
  }
}
