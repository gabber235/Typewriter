part of "members.dart";

extension ApproveOrganizationJoinRequestsOutcome
    on skir.ApproveOrganizationJoinRequestsResponse {
  void requireAccepted() {
    switch (this) {
      case skir.ApproveOrganizationJoinRequestsResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.ApproveOrganizationJoinRequestsResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.ApproveOrganizationJoinRequestsResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.ApproveOrganizationJoinRequestsResponse_requestNotFoundErrorWrapper():
        throw ApiException.notFound("Request");
      case skir.ApproveOrganizationJoinRequestsResponse_rolesNotFoundErrorWrapper():
        throw ApiException.notFound("Roles");
      case skir.ApproveOrganizationJoinRequestsResponse_rolesNotAssignableErrorWrapper():
        throw ApiException.badRequest("One or more roles cannot be assigned");
      case skir.ApproveOrganizationJoinRequestsResponse_invalidSelectionErrorWrapper():
        throw ApiException.badRequest("Select distinct pending requests");
      case skir.ApproveOrganizationJoinRequestsResponse_rolesRequiredErrorWrapper():
        throw ApiException.badRequest("At least one role is required");
      case skir.ApproveOrganizationJoinRequestsResponse_userAlreadyMemberErrorWrapper():
        throw ApiException.conflict("User is already an organization member");
      case skir.ApproveOrganizationJoinRequestsResponse_successWrapper():
        return;
    }
  }
}

extension DeclineOrganizationJoinRequestOutcome
    on skir.DeclineOrganizationJoinRequestResponse {
  void requireAccepted() {
    switch (this) {
      case skir.DeclineOrganizationJoinRequestResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.DeclineOrganizationJoinRequestResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.DeclineOrganizationJoinRequestResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.DeclineOrganizationJoinRequestResponse_requestNotFoundErrorWrapper():
        throw ApiException.notFound("Request");
      case skir.DeclineOrganizationJoinRequestResponse_successWrapper():
        return;
    }
  }
}

extension GenerateOrganizationJoinCodeOutcome
    on skir.GenerateOrganizationJoinCodeResponse {
  SecretFieldRevealed requireAccepted() {
    switch (this) {
      case skir.GenerateOrganizationJoinCodeResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.GenerateOrganizationJoinCodeResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.GenerateOrganizationJoinCodeResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotFoundErrorWrapper():
        throw ApiException.notFound("Roles");
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotAssignableErrorWrapper():
        throw ApiException.badRequest("One or more roles cannot be assigned");
      case skir.GenerateOrganizationJoinCodeResponse_invalidExpirationErrorWrapper():
        throw ApiException.badRequest("Expiration duration must be positive");
      case skir.GenerateOrganizationJoinCodeResponse_successWrapper(
        :final value,
      ):
        return SecretFieldRevealed(
          value: value.code.code.id,
          expiresAt: value.code.expiresAt,
        );
    }
  }
}

extension RevokeOrganizationJoinCodeOutcome
    on skir.RevokeOrganizationJoinCodeResponse {
  void requireAccepted() {
    switch (this) {
      case skir.RevokeOrganizationJoinCodeResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.RevokeOrganizationJoinCodeResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.RevokeOrganizationJoinCodeResponse_codeNotFoundErrorWrapper():
        throw ApiException.notFound("Join Code");
      case skir.RevokeOrganizationJoinCodeResponse_successWrapper():
        return;
    }
  }
}

extension UpdateOrganizationMemberRolesOutcome
    on skir.UpdateOrganizationMemberRolesResponse {
  void requireAccepted() {
    switch (this) {
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
      case skir.UpdateOrganizationMemberRolesResponse_invalidSelectionErrorWrapper():
        throw ApiException.badRequest("Select distinct organization members");
      case skir.UpdateOrganizationMemberRolesResponse_rolesRequiredErrorWrapper():
        throw ApiException.badRequest("At least one role is required");
      case skir.UpdateOrganizationMemberRolesResponse_founderRoleRequiredErrorWrapper():
        throw ApiException.conflict(
          "Organization must retain at least one founder",
        );
      case skir.UpdateOrganizationMemberRolesResponse_successWrapper():
        return;
    }
  }
}

extension RemoveOrganizationMemberOutcome
    on skir.RemoveOrganizationMemberResponse {
  void requireAccepted() {
    switch (this) {
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
        return;
    }
  }
}

extension MembershipSubmission on WidgetRef {
  MembershipResourceRepository get membershipCommands {
    final organization = read(organizationIdProvider);
    if (organization == null) throw ApiException.noOrganization();
    return read(resourceRepositoriesProvider).membership(organization);
  }

  Future<TResult> executeMembership<TResponse, TResult>(
    PreparedCommit<TResponse> command,
    TResult Function(TResponse) accept,
  ) async {
    try {
      final response = await read(localWorkControllerProvider).execute(command);
      return accept(response);
    } on Object {
      invalidate(organizationMembersProvider);
      invalidate(organizationJoinRequestsProvider);
      invalidate(organizationJoinCodesProvider);
      rethrow;
    }
  }
}
