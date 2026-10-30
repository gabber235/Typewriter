import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// The membership service of one organization, answering the panel over
/// NATS: its roles, members, join codes and join requests.
///
/// Unlike [FakeMembership], the panel's real projections and commands run:
/// the service answers their snapshots and keeps every command the panel
/// sends (generate or revoke a code, approve or decline a request, change
/// roles, remove a member) in memory, replying with the change event the
/// projections apply. So stories and widget tests see their own changes. It
/// holds no service rules: every command succeeds.
///
/// A list left null never arrives, so its page keeps loading, or fails with
/// [failure] when one is given. Every command answers after [latency], or
/// fails with [commandFailure] when one is given, and changes nothing.
final class FakeMembershipService {
  FakeMembershipService({
    List<skir.OrganizationRole>? roles = const [],
    List<skir.OrganizationMember>? members = const [],
    List<skir.JoinCode>? joinCodes = const [],
    List<skir.OrganizationJoinRequest>? joinRequests = const [],
    this.failure,
    this.commandFailure,
  }) : _roles = roles == null ? null : [...roles],
       _members = members == null ? null : [...members],
       _codes = joinCodes == null ? null : [...joinCodes],
       _requests = joinRequests == null ? null : [...joinRequests];

  final List<skir.OrganizationRole>? _roles;
  final List<skir.OrganizationMember>? _members;
  final List<skir.JoinCode>? _codes;
  final List<skir.OrganizationJoinRequest>? _requests;

  /// What every list left null fails with; null keeps them loading.
  final Object? failure;

  /// What every command fails with, as when the service cannot be reached;
  /// null confirms every command.
  final Object? commandFailure;

  /// How long the service takes to answer a command.
  Duration latency = Duration.zero;

  var _memberSequence = 1;
  var _codeSequence = 1;
  var _requestSequence = 1;
  var _generated = 0;

  /// The members as the service holds them now.
  List<skir.OrganizationMember> get members => [...?_members];

  /// The join codes as the service holds them now.
  List<skir.JoinCode> get joinCodes => [...?_codes];

  /// The join requests as the service holds them now.
  List<skir.OrganizationJoinRequest> get joinRequests => [...?_requests];

  /// Answers the requests [user] makes about [organization] on [nats].
  void serve(
    FakeNats nats, {
    required String user,
    required skir.RecordId organization,
  }) {
    void command<TRequest, TResponse>(
      SkirRouteOperation<TResponse> operation,
      skir.Serializer<TRequest> requests,
      TResponse Function(TRequest request) reply,
    ) => nats.registerHandler(operation.subject, (bytes) async {
      await Future<void>.delayed(latency);
      if (commandFailure case final error?) throw error;
      return operation.responseSerializer.toBytes(
        reply(requests.fromBytes(bytes)),
      );
    });

    void watch<TResponse>(
      SkirRouteOperation<TResponse> operation,
      TResponse? Function() snapshot,
    ) => nats.registerHandler(operation.subject, (_) {
      final value = snapshot();
      if (value != null) return operation.responseSerializer.toBytes(value);
      if (failure case final error?) throw error;
      return Completer<Uint8List>().future;
    });

    watch(
      skir.WatchOrganizationRolesRequest().operation(
        userId: user,
        organizationId: organization,
      ),
      () => switch (_roles) {
        final roles? => skir.WatchOrganizationRolesResponse.wrapList(roles),
        null => null,
      },
    );
    watch(
      skir.WatchOrganizationMembersRequest().operation(
        userId: user,
        organizationId: organization,
      ),
      () => switch (_members) {
        final members? => skir.WatchOrganizationMembersResponse.wrapSnapshot(
          skir.OrganizationMembersSnapshot(
            sequence: _memberSequence,
            values: members,
          ),
        ),
        null => null,
      },
    );
    watch(
      skir.WatchOrganizationJoinCodesRequest().operation(
        userId: user,
        organizationId: organization,
      ),
      () => switch (_codes) {
        final codes? => skir.WatchOrganizationJoinCodesResponse.wrapSnapshot(
          skir.OrganizationJoinCodesSnapshot(
            sequence: _codeSequence,
            values: codes,
          ),
        ),
        null => null,
      },
    );
    watch(
      skir.WatchOrganizationJoinRequestsRequest().operation(
        userId: user,
        organizationId: organization,
      ),
      () => switch (_requests) {
        final requests? =>
          skir.WatchOrganizationJoinRequestsResponse.wrapSnapshot(
            skir.OrganizationJoinRequestsSnapshot(
              sequence: _requestSequence,
              values: requests,
            ),
          ),
        null => null,
      },
    );

    command(
      skir.GenerateOrganizationJoinCodeRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.GenerateOrganizationJoinCodeRequest.serializer,
      _generate,
    );
    command(
      skir.RevokeOrganizationJoinCodeRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.RevokeOrganizationJoinCodeRequest.serializer,
      _revoke,
    );
    command(
      skir.ApproveOrganizationJoinRequestsRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.ApproveOrganizationJoinRequestsRequest.serializer,
      _approve,
    );
    command(
      skir.DeclineOrganizationJoinRequestRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.DeclineOrganizationJoinRequestRequest.serializer,
      _decline,
    );
    command(
      skir.UpdateOrganizationMemberRolesRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.UpdateOrganizationMemberRolesRequest.serializer,
      _updateRoles,
    );
    command(
      skir.RemoveOrganizationMemberRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.RemoveOrganizationMemberRequest.serializer,
      _remove,
    );
  }

  skir.GenerateOrganizationJoinCodeResponse _generate(
    skir.GenerateOrganizationJoinCodeRequest request,
  ) {
    final now = clock.now();
    final code = skir.JoinCode(
      code: skir.recordId("organization_join_code:generated_${++_generated}"),
      createdAt: now,
      expiresAt: switch (request.expiration) {
        skir.GenerateOrganizationJoinCodeRequest_Expiration_durationWrapper(
          :final value,
        ) =>
          now.add(Duration(milliseconds: value.milliseconds)),
        _ => null,
      },
      singleUse: request.singleUse,
      autoAccept: skir.JoinCode_AutoAccept(roleIds: request.autoAccept.roleIds),
    );
    _codes?.add(code);
    return skir.GenerateOrganizationJoinCodeResponse.createSuccess(
      code: code,
      event: _codesChanged([skir.OrganizationJoinCodesChange.wrapAdd(code)]),
    );
  }

  skir.RevokeOrganizationJoinCodeResponse _revoke(
    skir.RevokeOrganizationJoinCodeRequest request,
  ) {
    _codes?.removeWhere((code) => code.code == request.codeId);
    return skir.RevokeOrganizationJoinCodeResponse.createSuccess(
      event: _codesChanged([
        skir.OrganizationJoinCodesChange.wrapRemove(request.codeId),
      ]),
    );
  }

  skir.ApproveOrganizationJoinRequestsResponse _approve(
    skir.ApproveOrganizationJoinRequestsRequest request,
  ) {
    final roles = [
      for (final role in _roles ?? const <skir.OrganizationRole>[])
        if (request.roleIds.contains(role.roleId)) role,
    ];
    final approvals = [
      for (final joinRequest in [...?_requests])
        if (request.requestIds.contains(joinRequest.requestId))
          skir.ApprovedOrganizationJoinRequest(
            requestId: joinRequest.requestId,
            member: skir.OrganizationMember(
              userId: joinRequest.userId,
              name: joinRequest.userName,
              email: joinRequest.userEmail,
              avatarUrl: joinRequest.userAvatarUrl,
              roles: roles,
              joinedAt: clock.now(),
            ),
          ),
    ];
    _requests?.removeWhere(
      (joinRequest) => request.requestIds.contains(joinRequest.requestId),
    );
    _members?.addAll(approvals.map((approval) => approval.member));
    return skir.ApproveOrganizationJoinRequestsResponse.createSuccess(
      approvals: approvals,
      joinRequestsEvent: _requestsChanged([
        for (final approval in approvals)
          skir.OrganizationJoinRequestsChange.wrapRemove(approval.requestId),
      ]),
      membersEvent: _membersChanged([
        for (final approval in approvals)
          skir.OrganizationMembersChange.wrapAdd(approval.member),
      ]),
    );
  }

  skir.DeclineOrganizationJoinRequestResponse _decline(
    skir.DeclineOrganizationJoinRequestRequest request,
  ) {
    _requests?.removeWhere(
      (joinRequest) => joinRequest.requestId == request.requestId,
    );
    return skir.DeclineOrganizationJoinRequestResponse.createSuccess(
      event: _requestsChanged([
        skir.OrganizationJoinRequestsChange.wrapRemove(request.requestId),
      ]),
    );
  }

  skir.UpdateOrganizationMemberRolesResponse _updateRoles(
    skir.UpdateOrganizationMemberRolesRequest request,
  ) {
    final roles = [
      for (final role in _roles ?? const <skir.OrganizationRole>[])
        if (request.roleIds.contains(role.roleId)) role,
    ];
    final updated = <skir.OrganizationMember>[];
    final members = _members;
    if (members != null) {
      for (final (index, member) in members.indexed) {
        if (!request.userIds.contains(member.userId)) continue;
        final next = skir.OrganizationMember(
          userId: member.userId,
          name: member.name,
          email: member.email,
          avatarUrl: member.avatarUrl,
          roles: roles,
          joinedAt: member.joinedAt,
        );
        members[index] = next;
        updated.add(next);
      }
    }
    return skir.UpdateOrganizationMemberRolesResponse.createSuccess(
      members: updated,
      event: _membersChanged([
        for (final member in updated)
          skir.OrganizationMembersChange.wrapUpdate(member),
      ]),
    );
  }

  skir.RemoveOrganizationMemberResponse _remove(
    skir.RemoveOrganizationMemberRequest request,
  ) {
    _members?.removeWhere((member) => member.userId == request.userId);
    return skir.RemoveOrganizationMemberResponse.createSuccess(
      event: _membersChanged([
        skir.OrganizationMembersChange.wrapRemove(request.userId),
      ]),
    );
  }

  skir.OrganizationMembersChanged _membersChanged(
    List<skir.OrganizationMembersChange> changes,
  ) => skir.OrganizationMembersChanged(
    sequence: ++_memberSequence,
    changes: changes,
  );

  skir.OrganizationJoinCodesChanged _codesChanged(
    List<skir.OrganizationJoinCodesChange> changes,
  ) => skir.OrganizationJoinCodesChanged(
    sequence: ++_codeSequence,
    changes: changes,
  );

  skir.OrganizationJoinRequestsChanged _requestsChanged(
    List<skir.OrganizationJoinRequestsChange> changes,
  ) => skir.OrganizationJoinRequestsChanged(
    sequence: ++_requestSequence,
    changes: changes,
  );
}
