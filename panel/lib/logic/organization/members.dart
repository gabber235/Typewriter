import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/organization/organization.dart";

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

/// Provider for the list of available roles in the current organization.
@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Future<List<MemberRole>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) return [];

    // TODO: Implement fetching roles from backend
    throw UnimplementedError();
  }
}

/// Provider for the list of members in the current organization.
@riverpod
class OrganizationMembers extends _$OrganizationMembers {
  @override
  Future<List<OrganizationMember>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) return [];

    // TODO: Implement fetching members from backend
    throw UnimplementedError();
  }

  /// Updates the roles for a member.
  Future<void> updateMemberRoles(
    String memberId,
    List<MemberRole> roles,
  ) async {
    // TODO: Implement updating member roles
    throw UnimplementedError();
  }

  /// Removes a member from the organization.
  Future<void> removeMember(String memberId) async {
    // TODO: Implement removing a member
    throw UnimplementedError();
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
  Future<List<JoinRequest>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) return [];

    // TODO: Implement fetching join requests from backend
    throw UnimplementedError();
  }

  /// Approves a join request and assigns roles to the new member.
  Future<void> approveRequest(String requestId, List<MemberRole> roles) async {
    // TODO: Implement approving a join request
    throw UnimplementedError();
  }

  /// Declines a join request.
  Future<void> declineRequest(String requestId) async {
    // TODO: Implement declining a join request
    throw UnimplementedError();
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
