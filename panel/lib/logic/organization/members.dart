import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/api/organization/member.pb.dart"
    as member_api;
import "package:typewriter_panel/generated/api/organization/role.pb.dart"
    as role_api;
import "package:typewriter_panel/generated/models/organization/member.pb.dart"
    as member_models;
import "package:typewriter_panel/generated/models/organization/role.pb.dart"
    as role_models;
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "members.freezed.dart";
part "members.g.dart";

@freezed
abstract class MemberRole with _$MemberRole {
  const factory MemberRole({
    required String id,
    required String name,
    required Color color,
    @Default(false) bool defaultRole,
    @Default(false) bool assignable,
    @Default(false) bool deletable,
  }) = _MemberRole;
}

@freezed
abstract class OrganizationMember with _$OrganizationMember {
  const factory OrganizationMember({
    required String id,
    required String name,
    required String email,
    required String avatarUrl,
    required List<MemberRole> roles,
    required DateTime joinedAt,
  }) = _OrganizationMember;
}

@freezed
abstract class JoinRequest with _$JoinRequest {
  const factory JoinRequest({
    required String id,
    required String userId,
    required String userName,
    required String userEmail,
    required String userAvatarUrl,
    required DateTime requestedAt,
    required DateTime expiresAt,
  }) = _JoinRequest;

  const JoinRequest._();

  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => remainingDuration == Duration.zero;
}

@freezed
abstract class JoinCode with _$JoinCode {
  const factory JoinCode({
    required String code,
    required DateTime createdAt,
    DateTime? expiresAt,
    @Default(true) bool singleUse,
    JoinCodeAutoAccept? autoAccept,
  }) = _JoinCode;

  const JoinCode._();

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
  const factory JoinCodeAutoAccept({
    required List<String> roleIds,
  }) = _JoinCodeAutoAccept;
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
    List<String>? autoAcceptRoleIds,
  }) = _JoinCodeOptions;
}

/// Converts a proto Role to a dart MemberRole.
MemberRole _protoToMemberRole(role_models.Role proto) {
  return MemberRole(
    id: proto.id,
    name: proto.name,
    color: proto.color.toFlutterColor(),
    defaultRole: proto.defaultRole,
    assignable: proto.assignable,
    deletable: proto.deletable,
  );
}

/// Converts a proto OrganizationMember to a dart OrganizationMember.
OrganizationMember _protoToOrganizationMember(
  member_models.OrganizationMember proto,
) {
  return OrganizationMember(
    id: proto.id,
    name: proto.name,
    email: proto.email,
    avatarUrl: proto.avatarUrl,
    roles: proto.roles.map(_protoToMemberRole).toList(),
    joinedAt: proto.joinedAt.toDateTime(),
  );
}

/// Converts a proto JoinRequest to a dart JoinRequest.
JoinRequest _protoToJoinRequest(member_models.JoinRequest proto) {
  return JoinRequest(
    id: proto.id,
    userId: proto.userId,
    userName: proto.userName,
    userEmail: proto.userEmail,
    userAvatarUrl: proto.userAvatarUrl,
    requestedAt: proto.requestedAt.toDateTime(),
    expiresAt: proto.expiresAt.toDateTime(),
  );
}

/// Converts a proto JoinCode to a dart JoinCode.
JoinCode _protoToJoinCode(member_models.JoinCode proto) {
  return JoinCode(
    code: proto.code,
    createdAt: proto.createdAt.toDateTime(),
    expiresAt: proto.hasExpiresAt() ? proto.expiresAt.toDateTime() : null,
    singleUse: proto.singleUse,
    autoAccept: proto.hasAutoAccept()
        ? JoinCodeAutoAccept(roleIds: proto.autoAccept.roleIds.toList())
        : null,
  );
}

/// Provider for the list of available roles in the current organization.
@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Stream<List<MemberRole>> build() async* {
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

    final request = role_api.ListRolesRequest();
    final stream = ref.requestProtoThenListen(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.roles.list",
      listenSubject: "cloud.in.organization.$organizationId.roles.list",
      request: request,
      responseBuilder: role_api.ListRolesResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.roles.roles.map(_protoToMemberRole).toList();
    }
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

    final request = member_api.ListMembersRequest();
    final stream = ref.requestProtoThenListen(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.members.list",
      listenSubject: "cloud.in.organization.$organizationId.members.list",
      request: request,
      responseBuilder: member_api.ListMembersResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.members.members.map(_protoToOrganizationMember).toList();
    }
  }

  Future<List<MemberRole>> _actualRoles(
    String memberId,
    List<MemberRole> newRoles,
  ) async {
    final oldRoles =
        state.requireValue.firstWhereOrNull((m) => m.id == memberId)?.roles ??
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
    String memberId,
    List<MemberRole> requestedRoles,
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
          .map((m) => m.id == memberId ? m.copyWith(roles: roles) : m)
          .toList(),
    );

    try {
      final request = member_api.UpdateMemberRolesRequest()
        ..memberId = memberId
        ..roleIds.addAll(roles.map((r) => r.id));

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.members.update",
            request,
            member_api.UpdateMemberRolesResponse.new,
          );

      if (response.hasError()) {
        state = previousState;
        ref.invalidateSelf();
        throw ApiException.fromProto(response.error);
      }

      // Use response data to update the member (in case server made changes)
      if (response.hasMember()) {
        final updatedMember = _protoToOrganizationMember(response.member);
        state = AsyncValue.data(
          state.requireValue
              .map((m) => m.id == memberId ? updatedMember : m)
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
  Future<void> removeMember(String memberId) async {
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
      state.requireValue.where((m) => m.id != memberId).toList(),
    );

    try {
      final request = member_api.RemoveMemberRequest()..memberId = memberId;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.members.remove",
            request,
            member_api.RemoveMemberResponse.new,
          );

      if (response.hasError()) {
        state = previousState;
        ref.invalidateSelf();
        throw ApiException.fromProto(response.error);
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
  Stream<List<JoinRequest>> build() async* {
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

    final request = member_api.ListJoinRequestsRequest();
    final stream = ref.requestProtoThenListen(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.members.join_requests.list",
      listenSubject:
          "cloud.in.organization.$organizationId.members.join_requests.list",
      request: request,
      responseBuilder: member_api.ListJoinRequestsResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.requests.requests.map(_protoToJoinRequest).toList();
    }
  }

  /// Approves a join request and assigns roles to the new member.
  Future<void> approveRequest(String requestId, List<MemberRole> roles) async {
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
      state.value!.where((r) => r.id != requestId).toList(),
    );

    try {
      final request = member_api.ApproveJoinRequestRequest()
        ..requestId = requestId
        ..roleIds.addAll(roles.map((r) => r.id));

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.members.join_requests.approve",
            request,
            member_api.ApproveJoinRequestResponse.new,
          );

      if (response.hasError()) {
        state = previousState;
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  /// Declines a join request.
  Future<void> declineRequest(String requestId) async {
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
      state.value!.where((r) => r.id != requestId).toList(),
    );

    try {
      final request = member_api.DeclineJoinRequestRequest()
        ..requestId = requestId;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.members.join_requests.decline",
            request,
            member_api.DeclineJoinRequestResponse.new,
          );

      if (response.hasError()) {
        state = previousState; // Rollback on API error
        ref.invalidateSelf();
        throw ApiException.fromProto(response.error);
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
  Stream<List<JoinCode>> build() async* {
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

    final request = member_api.ListJoinCodesRequest();
    final stream = ref.requestProtoThenListen(
      subject:
          "cloud.out.user.$userId.organization.$organizationId.members.join_codes.list",
      listenSubject:
          "cloud.in.organization.$organizationId.members.join_codes.list",
      request: request,
      responseBuilder: member_api.ListJoinCodesResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.joinCodes.joinCodes.map(_protoToJoinCode).toList();
    }
  }

  /// Revokes a join code.
  Future<void> revokeCode(String codeId) async {
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
      final request = member_api.RevokeJoinCodeRequest()..codeId = codeId;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.$organizationId.members.join_codes.revoke",
            request,
            member_api.RevokeJoinCodeResponse.new,
          );

      if (response.hasError()) {
        state = previousState;
        ref.invalidateSelf();
        throw ApiException.fromProto(response.error);
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
