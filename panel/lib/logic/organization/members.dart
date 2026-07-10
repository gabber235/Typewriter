import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/api_exception.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/skir.dart";

part "members.freezed.dart";
part "members.g.dart";

@freezed
abstract class OrganizationRole with _$OrganizationRole {
  const factory OrganizationRole({
    required skir.RecordId roleId,
    required String name,
    required Color color,
    @Default(false) bool defaultRole,
    @Default(false) bool assignable,
    @Default(false) bool deletable,
  }) = _OrganizationRole;

  const OrganizationRole._();

  factory OrganizationRole.fromSkir(skir.OrganizationRole role) =>
      OrganizationRole(
        roleId: role.roleId,
        name: role.name,
        color: role.color.toFlutterColor(),
        defaultRole: role.defaultRole,
        assignable: role.assignable,
        deletable: role.deletable,
      );

  skir.OrganizationRole toSkir() => skir.OrganizationRole(
    roleId: roleId,
    name: name,
    color: color.toSkirColor(),
    defaultRole: defaultRole,
    assignable: assignable,
    deletable: deletable,
  );
}

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

@freezed
abstract class OrganizationJoinRequest with _$OrganizationJoinRequest {
  const factory OrganizationJoinRequest({
    required skir.RecordId requestId,
    required skir.RecordId userId,
    required DateTime requestedAt,
    required DateTime expiresAt,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
  }) = _OrganizationJoinRequest;

  const OrganizationJoinRequest._();

  factory OrganizationJoinRequest.fromSkir(
    skir.OrganizationJoinRequest request,
  ) => OrganizationJoinRequest(
    requestId: request.requestId,
    userId: request.userId,
    requestedAt: request.requestedAt,
    expiresAt: request.expiresAt,
    userName: request.userName,
    userEmail: request.userEmail,
    userAvatarUrl: request.userAvatarUrl,
  );

  skir.OrganizationJoinRequest toSkir() => skir.OrganizationJoinRequest(
    requestId: requestId,
    userId: this.userId,
    requestedAt: requestedAt,
    expiresAt: expiresAt,
    userName: userName,
    userEmail: userEmail,
    userAvatarUrl: userAvatarUrl,
  );

  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => remainingDuration == Duration.zero;
}

@freezed
abstract class OrganizationJoinCode with _$OrganizationJoinCode {
  const factory OrganizationJoinCode({
    required skir.RecordId code,
    required DateTime createdAt,
    DateTime? expiresAt,
    @Default(true) bool singleUse,
    @Default(JoinCodeAutoAccept()) JoinCodeAutoAccept autoAccept,
  }) = _OrganizationJoinCode;

  const OrganizationJoinCode._();

  factory OrganizationJoinCode.fromSkir(skir.JoinCode request) =>
      OrganizationJoinCode(
        code: request.code,
        createdAt: request.createdAt,
        expiresAt: request.expiresAt,
        singleUse: request.singleUse,
        autoAccept: JoinCodeAutoAccept.fromSkir(request.autoAccept),
      );

  skir.JoinCode toSkir() => skir.JoinCode(
    code: code,
    createdAt: createdAt,
    expiresAt: expiresAt,
    singleUse: singleUse,
    autoAccept: autoAccept.toSkir(),
  );

  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return remainingDuration == Duration.zero;
  }

  bool get neverExpires => expiresAt == null;
}

/// Auto-accept configuration for a join code.
@freezed
abstract class JoinCodeAutoAccept with _$JoinCodeAutoAccept {
  const factory JoinCodeAutoAccept({@Default([]) List<skir.RecordId> roleIds}) =
      _JoinCodeAutoAccept;

  const JoinCodeAutoAccept._();

  factory JoinCodeAutoAccept.fromSkir(skir.JoinCode_AutoAccept request) =>
      JoinCodeAutoAccept(roleIds: request.roleIds.toList());

  skir.JoinCode_AutoAccept toSkir() =>
      skir.JoinCode_AutoAccept(roleIds: roleIds);
}

/// Expiration configuration for generating a join code.
@freezed
sealed class JoinCodeExpiration with _$JoinCodeExpiration {
  const factory JoinCodeExpiration.never() = JoinCodeExpirationNever;
  const factory JoinCodeExpiration.duration(Duration duration) =
      JoinCodeExpirationDuration;
}

/// Options for generating a join code.
@freezed
abstract class JoinCodeOptions with _$JoinCodeOptions {
  const factory JoinCodeOptions({
    @Default(true) bool singleUse,
    @Default(JoinCodeExpiration.duration(Duration(days: 7)))
    JoinCodeExpiration expiration,
    @Default([]) List<skir.RecordId> autoAcceptRoleIds,
  }) = _JoinCodeOptions;
}

/// Provider for the list of available roles in the current organization.
@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Stream<List<OrganizationRole>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationRolesRequest();

    yield* ref.watchRequest(
      subject:
          "cloud.out.user.$userId.organization.${organizationId.key}.roles.watch",
      listenSubject: "cloud.in.organization.${organizationId.key}.roles.watch",
      requestBytes: skir.WatchOrganizationRolesRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationRolesResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationRolesResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationRolesResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationRolesResponse_listWrapper(:final value):
            return value.map(OrganizationRole.fromSkir).toList();
          case skir.WatchOrganizationRolesResponse_addWrapper(:final value):
            return [...?previous, OrganizationRole.fromSkir(value)];
          case skir.WatchOrganizationRolesResponse_removeWrapper(:final value):
            return previous?.where((role) => role.roleId != value).toList() ??
                [];
        }
      },
    );
  }
}

/// Provider for the list of members in the current organization.
@riverpod
class OrganizationMembers extends _$OrganizationMembers {
  @override
  Stream<List<OrganizationMember>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
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
    yield* ref.watchRequest(
      subject:
          "cloud.out.user.$userId.organization.${organizationId.key}.members.watch",
      listenSubject:
          "cloud.in.organization.${organizationId.key}.members.watch",
      requestBytes: skir.WatchOrganizationMembersRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationMembersResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationMembersResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationMembersResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationMembersResponse_listWrapper(:final value):
            return value.map(OrganizationMember.fromSkir).toList();
          case skir.WatchOrganizationMembersResponse_addWrapper(:final value):
            return [...?previous, OrganizationMember.fromSkir(value)];
          case skir.WatchOrganizationMembersResponse_removeWrapper(
            :final value,
          ):
            return previous
                    ?.where((member) => member.userId != value)
                    .toList() ??
                [];
        }
      },
    );
  }

  Future<List<OrganizationRole>> _actualRoles(
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
      return defaultRoles;
    }

    return roles.toList();
  }

  /// Updates the roles for a member.
  Future<void> updateMemberRoles(
    skir.RecordId memberId,
    List<OrganizationRole> requestedRoles,
  ) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    final previousState = state;

    final roles = await _actualRoles(memberId, requestedRoles);

    // Optimistically update the member's roles
    state = AsyncValue.data(
      state.requireValue
          .map((m) => m.userId == memberId ? m.copyWith(roles: roles) : m)
          .toList(),
    );

    try {
      final request = skir.UpdateOrganizationMemberRolesRequest(
        userId: memberId,
        roleIds: roles.map((r) => r.roleId),
      );

      final response = await ref
          .read(natsProvider)
          .requestSkir(
            "cloud.out.user.$userId.organization.${organizationId.key}.members.update",
            skir.UpdateOrganizationMemberRolesRequest.serializer.toBytes(
              request,
            ),
            skir.UpdateOrganizationMemberRolesResponse.serializer,
          );

      switch (response) {
        case skir.UpdateOrganizationMemberRolesResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdateOrganizationMemberRolesResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdateOrganizationMemberRolesResponse_userNotFoundErrorWrapper():
          throw ApiException.notFound("User");
        case skir.UpdateOrganizationMemberRolesResponse_rolesNotFoundErrorWrapper():
          throw ApiException.notFound("Roles");
        case skir.UpdateOrganizationMemberRolesResponse_successWrapper(
          :final value,
        ):
          state = AsyncValue.data(
            state.requireValue
                .map(
                  (m) => m.userId == memberId
                      ? OrganizationMember.fromSkir(value)
                      : m,
                )
                .toList(),
          );
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Removes a member from the organization.
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
    final previousState = state;

    // Optimistically remove the member
    state = AsyncValue.data(
      state.requireValue.where((m) => m.userId != memberId).toList(),
    );

    try {
      final request = skir.RemoveOrganizationMemberRequest(userId: memberId);

      final response = await ref
          .read(natsProvider)
          .requestSkir(
            "cloud.out.user.$userId.organization.${organizationId.key}.members.remove",
            skir.RemoveOrganizationMemberRequest.serializer.toBytes(request),
            skir.RemoveOrganizationMemberResponse.serializer,
          );

      switch (response) {
        case skir.RemoveOrganizationMemberResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.RemoveOrganizationMemberResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.RemoveOrganizationMemberResponse_userNotMemberErrorWrapper():
          throw ApiException.userNotMemberError();
        case skir.RemoveOrganizationMemberResponse_successWrapper():
          debugPrint("removed $memberId from $organizationId");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<OrganizationMember>> previous,
    AsyncValue<List<OrganizationMember>> next,
  ) => true;
}

/// Provider for the list of pending join requests to the current organization.
@riverpod
class OrganizationJoinRequests extends _$OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationJoinRequestsRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.out.user.$userId.organization.${organizationId.key}.members.join_requests.watch",
      listenSubject:
          "cloud.in.organization.${organizationId.key}.members.join_requests.watch",
      requestBytes: skir.WatchOrganizationJoinRequestsRequest.serializer
          .toBytes(request),
      serializer: skir.WatchOrganizationJoinRequestsResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationJoinRequestsResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationJoinRequestsResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationJoinRequestsResponse_listWrapper(
            :final value,
          ):
            return value.map(OrganizationJoinRequest.fromSkir).toList();
          case skir.WatchOrganizationJoinRequestsResponse_addWrapper(
            :final value,
          ):
            return [...?previous, OrganizationJoinRequest.fromSkir(value)];
          case skir.WatchOrganizationJoinRequestsResponse_removeWrapper(
            :final value,
          ):
            return previous?.where((e) => e.requestId != value).toList() ?? [];
        }
      },
    );
  }

  /// Approves a join request and assigns roles to the new member.
  Future<void> approveRequest(
    skir.RecordId requestId,
    List<OrganizationRole> roles,
  ) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    // Store previous state for rollback
    final previousState = state;

    // Optimistically remove the request from join requests
    state = AsyncValue.data(
      state.value!.where((r) => r.requestId != requestId).toList(),
    );

    try {
      final request = skir.ApproveOrganizationJoinRequestRequest(
        requestId: requestId,
        roleIds: roles.map((r) => r.roleId),
      );

      final response = await ref
          .read(natsProvider)
          .requestSkir(
            "cloud.out.user.$userId.organization.$organizationId.members.join_requests.approve",
            skir.ApproveOrganizationJoinRequestRequest.serializer.toBytes(
              request,
            ),
            skir.ApproveOrganizationJoinRequestResponse.serializer,
          );

      switch (response) {
        case skir.ApproveOrganizationJoinRequestResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.ApproveOrganizationJoinRequestResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.ApproveOrganizationJoinRequestResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Request");
        case skir.ApproveOrganizationJoinRequestResponse_rolesNotFoundErrorWrapper():
          throw ApiException.notFound("Roles");
        case skir.ApproveOrganizationJoinRequestResponse_successWrapper(
          :final value,
        ):
          debugPrint(
            "Successfully approved join request $requestId for ${value.name ?? value.email ?? value.userId}",
          );
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Declines a join request.
  Future<void> declineRequest(skir.RecordId requestId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    // Store previous state for rollback
    final previousState = state;

    // Optimistically remove the request
    state = AsyncValue.data(
      state.value!.where((r) => r.requestId != requestId).toList(),
    );

    try {
      final request = skir.DeclineOrganizationJoinRequestRequest(
        requestId: requestId,
      );

      final response = await ref
          .read(natsProvider)
          .requestSkir(
            "cloud.out.user.$userId.organization.$organizationId.members.join_requests.decline",
            skir.DeclineOrganizationJoinRequestRequest.serializer.toBytes(
              request,
            ),
            skir.DeclineOrganizationJoinRequestResponse.serializer,
          );

      switch (response) {
        case skir.DeclineOrganizationJoinRequestResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.DeclineOrganizationJoinRequestResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.DeclineOrganizationJoinRequestResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Request");
        case skir.DeclineOrganizationJoinRequestResponse_successWrapper():
          debugPrint("Request $requestId declined successfully");
      }
    } catch (e) {
      state = previousState; // Rollback on any exception
      ref.invalidateSelf();
      rethrow;
    }
  }
}

/// Provider for the count of pending join requests.
@riverpod
int joinRequestCount(Ref ref) {
  final requests = ref.watch(organizationJoinRequestsProvider);
  return requests.maybeWhen(
    data: (data) => data.where((request) => !request.isExpired).length,
    orElse: () => 0,
  );
}

/// Provider for the list of active join codes in the current organization.
@riverpod
class OrganizationJoinCodes extends _$OrganizationJoinCodes {
  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationJoinCodesRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.members.join_codes.watch",
      listenSubject:
          "cloud.in.organization.$organizationId.members.join_codes.watch",
      requestBytes: skir.WatchOrganizationJoinCodesRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationJoinCodesResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationJoinCodesResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationJoinCodesResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationJoinCodesResponse_listWrapper(
            :final value,
          ):
            return value.map(OrganizationJoinCode.fromSkir).toList();
          case skir.WatchOrganizationJoinCodesResponse_addWrapper(:final value):
            return [...?previous, OrganizationJoinCode.fromSkir(value)];
          case skir.WatchOrganizationJoinCodesResponse_removeWrapper(
            :final value,
          ):
            return previous?.where((code) => code.code != value).toList() ?? [];
        }
      },
    );
  }

  /// Revokes a join code.
  Future<void> revokeCode(skir.RecordId codeId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    final previousState = state;

    // Optimistically remove the code
    state = AsyncValue.data(
      state.requireValue.where((c) => c.code != codeId).toList(),
    );

    try {
      final request = skir.RevokeOrganizationJoinCodeRequest(codeId: codeId);

      final response = await ref
          .read(natsProvider)
          .requestSkir(
            "cloud.out.user.$userId.organization.$organizationId.members.join_codes.revoke",
            skir.RevokeOrganizationJoinCodeRequest.serializer.toBytes(request),
            skir.RevokeOrganizationJoinCodeResponse.serializer,
          );

      switch (response) {
        case skir.RevokeOrganizationJoinCodeResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.RevokeOrganizationJoinCodeResponse_codeNotFoundErrorWrapper():
          throw ApiException.notFound("Join Code");
        case skir.RevokeOrganizationJoinCodeResponse_successWrapper():
          debugPrint("Join code $codeId revoked successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }
}

/// Provider for the count of active join codes.
@riverpod
int joinCodeCount(Ref ref) {
  final codes = ref.watch(organizationJoinCodesProvider);
  return codes.maybeWhen(
    data: (data) => data.where((code) => !code.isExpired).length,
    orElse: () => 0,
  );
}
