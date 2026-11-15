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

extension DeclineOrganizationJoinRequestsOutcome
    on skir.DeclineOrganizationJoinRequestsResponse {
  void requireAccepted() {
    switch (this) {
      case skir.DeclineOrganizationJoinRequestsResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.DeclineOrganizationJoinRequestsResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.DeclineOrganizationJoinRequestsResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.DeclineOrganizationJoinRequestsResponse_requestNotFoundErrorWrapper():
        throw ApiException.notFound("Request");
      case skir.DeclineOrganizationJoinRequestsResponse_invalidSelectionErrorWrapper():
        throw ApiException.badRequest("Select distinct pending requests");
      case skir.DeclineOrganizationJoinRequestsResponse_successWrapper():
        return;
    }
  }
}

extension GenerateOrganizationJoinCodeOutcome
    on skir.GenerateOrganizationJoinCodeResponse {
  /// The generated code; the route needs its record id to announce focus.
  skir.JoinCode requireAccepted() {
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
        return value.code;
    }
  }
}

extension RevokeOrganizationJoinCodesOutcome
    on skir.RevokeOrganizationJoinCodesResponse {
  void requireAccepted() {
    switch (this) {
      case skir.RevokeOrganizationJoinCodesResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.RevokeOrganizationJoinCodesResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.RevokeOrganizationJoinCodesResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.RevokeOrganizationJoinCodesResponse_codeNotFoundErrorWrapper():
        throw ApiException.notFound("Join Code");
      case skir.RevokeOrganizationJoinCodesResponse_invalidSelectionErrorWrapper():
        throw ApiException.badRequest("Select distinct join codes");
      case skir.RevokeOrganizationJoinCodesResponse_successWrapper():
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

extension RemoveOrganizationMembersOutcome
    on skir.RemoveOrganizationMembersResponse {
  void requireAccepted() {
    switch (this) {
      case skir.RemoveOrganizationMembersResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.RemoveOrganizationMembersResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.RemoveOrganizationMembersResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.RemoveOrganizationMembersResponse_userNotMemberErrorWrapper():
        throw ApiException.notFound("Organization member");
      case skir.RemoveOrganizationMembersResponse_founderCannotBeRemovedErrorWrapper():
        throw ApiException.conflict("Organization founder cannot be removed");
      case skir.RemoveOrganizationMembersResponse_invalidSelectionErrorWrapper():
        throw ApiException.badRequest("Select distinct organization members");
      case skir.RemoveOrganizationMembersResponse_successWrapper():
        return;
    }
  }
}

extension MembershipSubmission on WidgetRef {
  MembershipResourceRepository get membershipCommands {
    final organization = read(organizationIdProvider);
    if (organization == null) throw ApiException.noOrganization();
    return read(membershipResourceRepositoryProvider(organization));
  }

  /// Submits through local work ownership, then interprets the typed reply.
  ///
  /// Any failure, including one thrown by [accept], invalidates all membership
  /// projections before escaping so the next read can restore server state.
  /// The invalidation goes through the container, not this widget: a command
  /// such as a decline hides its own row while it sends, so the widget that
  /// started it may be gone when the reply arrives.
  Future<TResult> executeMembership<TResponse, TResult>(
    PreparedCommit<TResponse> command,
    TResult Function(TResponse) accept,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final response = await read(localWorkControllerProvider).execute(command);
      return accept(response);
    } on Object {
      container
        ..invalidate(organizationMembersProvider)
        ..invalidate(organizationJoinRequestsProvider)
        ..invalidate(organizationJoinCodesProvider);
      rethrow;
    }
  }
}
