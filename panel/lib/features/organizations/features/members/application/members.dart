import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

part "members.freezed.dart";
part "members.g.dart";

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
          "cloud.to.user.$userId.organization.${organizationId.id}.members.watch",
      listenSubject:
          "cloud.from.organization.${organizationId.id}.members.watch",
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
            return previous.upsertByKey(
              (member) => member.userId,
              OrganizationMember.fromSkir(value),
            );
          case skir.WatchOrganizationMembersResponse_updateWrapper(
            :final value,
          ):
            return previous.upsertByKey(
              (member) => member.userId,
              OrganizationMember.fromSkir(value),
            );
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

    final roles = await ensureCorrectRoles(memberId, requestedRoles);

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

      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.update",
        skir.UpdateOrganizationMemberRolesRequest.serializer.toBytes(request),
        skir.UpdateOrganizationMemberRolesResponse.serializer,
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
        case skir.UpdateOrganizationMemberRolesResponse_rolesRequiredErrorWrapper():
          throw ApiException.badRequest("At least one role is required");
        case skir.UpdateOrganizationMemberRolesResponse_founderRoleRequiredErrorWrapper():
          throw ApiException.conflict(
            "Organization must retain at least one founder",
          );
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

      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.remove",
        skir.RemoveOrganizationMemberRequest.serializer.toBytes(request),
        skir.RemoveOrganizationMemberResponse.serializer,
      );

      switch (response) {
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
