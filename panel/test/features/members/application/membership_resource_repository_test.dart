import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _user = "ada";
final _organization = skir.recordId("organization:acme");
final _grace = skir.recordId("user:grace");
const _scope = "cloud.to.user.ada.organization.acme.members";

void main() {
  group("updating member roles", () {
    final updated = skir.UpdateOrganizationMemberRolesResponse.serializer
        .toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            members: const [],
            event: skir.OrganizationMembersChanged(
              sequence: 4,
              changes: const [],
            ),
          ),
        );

    test("sends the members and roles chosen when it was prepared", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.update", (_) => updated);
      addTearDown(nats.dispose);
      final requests = nats
          .requestsTo("$_scope.update")
          .map((request) => request.payload);
      final members = [_grace];
      final roles = [role("editor")];
      final command = membershipCommands(
        nats,
        organization: _organization,
        user: _user,
      ).updateRoles(members, roles);

      members.add(skir.recordId("user:other"));
      roles.add(role("viewer"));
      await command.send();
      await command.send();

      expect(
        requests
            .map(skir.UpdateOrganizationMemberRolesRequest.serializer.fromBytes)
            .map((request) => request.userIds),
        [
          [_grace],
          [_grace],
        ],
      );
      expect(
        requests
            .map(skir.UpdateOrganizationMemberRolesRequest.serializer.fromBytes)
            .map((request) => request.roleIds),
        [
          [role("editor").roleId],
          [role("editor").roleId],
        ],
      );
    });

    test("leaves out roles that cannot be assigned", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.update", (_) => updated);
      addTearDown(nats.dispose);
      final requests = nats
          .requestsTo("$_scope.update")
          .map((request) => request.payload);

      await membershipCommands(nats, organization: _organization, user: _user)
          .updateRoles(
            [_grace],
            [role("editor"), role("founder", assignable: false)],
          )
          .send();

      expect(
        skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(requests.single)
            .roleIds,
        [role("editor").roleId],
      );
    });

    test("publishes the confirmed event to the member projection", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.update", (_) => updated);
      addTearDown(nats.dispose);
      final repository = membershipCommands(
        nats,
        organization: _organization,
        user: _user,
      );
      final events = <skir.OrganizationMembersChanged>[];
      final subscription = repository.members.listen(events.add);
      addTearDown(subscription.cancel);
      final command = repository.updateRoles([_grace], [role("editor")]);

      await command.integrate!(await command.send());

      expect(events.single.sequence, 4);
    });
  });

  test("approving a join request removes the request and adds the member "
      "in the same confirmed step", () async {
    final requestId = skir.recordId("request_to_join:grace");
    final member = skir.OrganizationMember(
      userId: _grace,
      name: "Grace",
      email: null,
      avatarUrl: null,
      roles: [role("editor")],
      joinedAt: DateTime.utc(2026),
    );
    final nats = FakeNatsClient(actorId: _user)
      ..registerHandler(
        "$_scope.join_requests.approve",
        (_) => skir.ApproveOrganizationJoinRequestsResponse.serializer.toBytes(
          skir.ApproveOrganizationJoinRequestsResponse.createSuccess(
            approvals: [
              skir.ApprovedOrganizationJoinRequest(
                requestId: requestId,
                member: member,
              ),
            ],
            joinRequestsEvent: skir.OrganizationJoinRequestsChanged(
              sequence: 3,
              changes: [
                skir.OrganizationJoinRequestsChange.wrapRemove(requestId),
              ],
            ),
            membersEvent: skir.OrganizationMembersChanged(
              sequence: 8,
              changes: [skir.OrganizationMembersChange.wrapAdd(member)],
            ),
          ),
        ),
      );
    addTearDown(nats.dispose);
    final repository = membershipCommands(
      nats,
      organization: _organization,
      user: _user,
    );
    final seen = <String>[];
    final requests = repository.requests.listen(
      (event) => seen.add("requests ${event.changes}"),
    );
    final members = repository.members.listen(
      (event) => seen.add("members ${event.changes}"),
    );
    addTearDown(requests.cancel);
    addTearDown(members.cancel);
    final command = repository.approve([requestId], [role("editor")]);

    final result = await command.send();
    expect(seen, isEmpty);
    await command.integrate!(result);

    expect(seen, [
      "requests ${[skir.OrganizationJoinRequestsChange.wrapRemove(requestId)]}",
      "members ${[skir.OrganizationMembersChange.wrapAdd(member)]}",
    ]);
  });

  group("generating a join code", () {
    final generated = skir.GenerateOrganizationJoinCodeResponse.serializer
        .toBytes(
          skir.GenerateOrganizationJoinCodeResponse.createSuccess(
            code: joinCode("new"),
            event: skir.OrganizationJoinCodesChanged(
              sequence: 2,
              changes: const [],
            ),
          ),
        );

    test("asks by default for a single use code that expires in 7 days "
        "and needs approval", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.join_codes.generate", (_) => generated);
      addTearDown(nats.dispose);
      await membershipCommands(
        nats,
        organization: _organization,
        user: _user,
      ).generate(options: const JoinCodeOptions()).send();
      final request = skir.GenerateOrganizationJoinCodeRequest.serializer
          .fromBytes(
            nats.requestsTo("$_scope.join_codes.generate").single.payload,
          );

      expect(request.singleUse, isTrue);
      expect(
        request.expiration,
        skir.GenerateOrganizationJoinCodeRequest_Expiration.createDuration(
          milliseconds: const Duration(days: 7).inMilliseconds,
        ),
      );
      expect(request.autoAccept.roleIds, isEmpty);
    });

    test("asks for a reusable code that never expires and accepts "
        "into the chosen roles", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.join_codes.generate", (_) => generated);
      addTearDown(nats.dispose);
      await membershipCommands(nats, organization: _organization, user: _user)
          .generate(
            options: JoinCodeOptions(
              singleUse: false,
              expiration: JoinCodeExpiration.never(),
              autoAcceptRoleIds: [role("editor").roleId],
            ),
          )
          .send();
      final request = skir.GenerateOrganizationJoinCodeRequest.serializer
          .fromBytes(
            nats.requestsTo("$_scope.join_codes.generate").single.payload,
          );

      expect(request.singleUse, isFalse);
      expect(
        request.expiration,
        skir.GenerateOrganizationJoinCodeRequest_Expiration.never,
      );
      expect(request.autoAccept.roleIds, [role("editor").roleId]);
    });

    test("asks for the custom duration chosen", () async {
      final nats = FakeNatsClient(actorId: _user)
        ..registerHandler("$_scope.join_codes.generate", (_) => generated);
      addTearDown(nats.dispose);
      await membershipCommands(nats, organization: _organization, user: _user)
          .generate(
            options: JoinCodeOptions(
              expiration: JoinCodeExpiration.duration(const Duration(hours: 3)),
            ),
          )
          .send();
      final request = skir.GenerateOrganizationJoinCodeRequest.serializer
          .fromBytes(
            nats.requestsTo("$_scope.join_codes.generate").single.payload,
          );

      expect(
        request.expiration,
        skir.GenerateOrganizationJoinCodeRequest_Expiration.createDuration(
          milliseconds: const Duration(hours: 3).inMilliseconds,
        ),
      );
    });
  });

  test("a signed out user cannot prepare a membership command", () {
    final nats = FakeNatsClient();
    addTearDown(nats.dispose);

    expect(
      () => membershipCommands(
        nats,
        organization: _organization,
        user: null,
      ).remove(_grace),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, "code", 401)
            .having(
              (error) => error.message,
              "message",
              "User not authenticated",
            ),
      ),
    );
  });

  test("an ended session cannot prepare a membership command", () {
    final nats = FakeNatsClient(actorId: _user);
    addTearDown(nats.dispose);
    final repository = membershipCommands(
      nats,
      organization: _organization,
      user: _user,
    );

    repository.session.end();

    expect(() => repository.remove(_grace), throwsStateError);
  });

  test(
    "a disposed owner rejects integration of an in flight command",
    () async {
      final nats = FakeNatsClient(actorId: _user);
      addTearDown(nats.dispose);
      final response = Completer<Uint8List>();
      nats.registerHandler("$_scope.remove", (_) => response.future);
      final repository = membershipCommands(
        nats,
        organization: _organization,
        user: _user,
      );
      final events = <skir.OrganizationMembersChanged>[];
      final subscription = repository.members.listen(events.add);
      addTearDown(subscription.cancel);
      final command = repository.remove(_grace);
      final sending = command.send();
      await pumpEventQueue();

      repository.session.end();
      repository.dispose();
      response.complete(
        skir.RemoveOrganizationMemberResponse.serializer.toBytes(
          skir.RemoveOrganizationMemberResponse.createSuccess(
            event: skir.OrganizationMembersChanged(
              sequence: 7,
              changes: [skir.OrganizationMembersChange.wrapRemove(_grace)],
            ),
          ),
        ),
      );
      final result = await sending;

      await expectLater(command.integrate!(result), throwsStateError);
      expect(events, isEmpty);
    },
  );

  group("a membership reply that is not accepted", () {
    final internalErrors = <String, void Function()>{
      "a role update":
          skir.UpdateOrganizationMemberRolesResponse.createInternalError()
              .requireAccepted,
      "a member removal":
          skir.RemoveOrganizationMemberResponse.createInternalError()
              .requireAccepted,
      "an approval":
          skir.ApproveOrganizationJoinRequestsResponse.createInternalError()
              .requireAccepted,
      "a decline":
          skir.DeclineOrganizationJoinRequestResponse.createInternalError()
              .requireAccepted,
      "a code generation":
          skir.GenerateOrganizationJoinCodeResponse.createInternalError()
              .requireAccepted,
      "a code revocation":
          skir.RevokeOrganizationJoinCodeResponse.createInternalError()
              .requireAccepted,
    };
    for (final MapEntry(key: command, value: accept)
        in internalErrors.entries) {
      test("fails $command answered with an internal error as a server "
          "error", () {
        expect(
          accept,
          throwsA(
            isA<ApiException>()
                .having((error) => error.code, "code", 500)
                .having(
                  (error) => error.message,
                  "message",
                  isIn(funnyErrorTitles),
                ),
          ),
        );
      });
    }

    final rejections = <String, (void Function(), int, String)>{
      "roles that cannot be assigned": (
        skir.UpdateOrganizationMemberRolesResponse.createRolesNotAssignableError(
          userIds: [_grace],
          roleIds: [role("founder").roleId],
        ).requireAccepted,
        400,
        "One or more roles cannot be assigned",
      ),
      "the last founder losing the founder role": (
        skir.UpdateOrganizationMemberRolesResponse.createFounderRoleRequiredError()
            .requireAccepted,
        409,
        "Organization must retain at least one founder",
      ),
      "a repeated member in a role update": (
        skir.UpdateOrganizationMemberRolesResponse.createInvalidSelectionError()
            .requireAccepted,
        400,
        "Select distinct organization members",
      ),
      "removing the founder": (
        skir.RemoveOrganizationMemberResponse.createFounderCannotBeRemovedError(
          userId: _grace,
        ).requireAccepted,
        409,
        "Organization founder cannot be removed",
      ),
      "removing someone who is not a member": (
        skir.RemoveOrganizationMemberResponse.createUserNotMemberError(
          userId: _grace,
        ).requireAccepted,
        404,
        "Organization Member not found",
      ),
      "approving without roles": (
        skir.ApproveOrganizationJoinRequestsResponse.createRolesRequiredError()
            .requireAccepted,
        400,
        "At least one role is required",
      ),
      "approving someone who already is a member": (
        skir.ApproveOrganizationJoinRequestsResponse.createUserAlreadyMemberError(
          userIds: [_grace],
        ).requireAccepted,
        409,
        "User is already an organization member",
      ),
      "a repeated request in an approval": (
        skir.ApproveOrganizationJoinRequestsResponse.createInvalidSelectionError()
            .requireAccepted,
        400,
        "Select distinct pending requests",
      ),
      "declining a missing request": (
        skir.DeclineOrganizationJoinRequestResponse.createRequestNotFoundError(
          requestId: skir.recordId("request_to_join:missing"),
        ).requireAccepted,
        404,
        "Request not found",
      ),
      "a code generation with roles that cannot be assigned": (
        skir.GenerateOrganizationJoinCodeResponse.createRolesNotAssignableError(
          roleIds: [role("founder").roleId],
        ).requireAccepted,
        400,
        "One or more roles cannot be assigned",
      ),
      "a code that would never become valid": (
        skir.GenerateOrganizationJoinCodeResponse.createInvalidExpirationError(
          duration: skir.Duration.defaultInstance,
        ).requireAccepted,
        400,
        "Expiration duration must be positive",
      ),
      "revoking a missing code": (
        skir.RevokeOrganizationJoinCodeResponse.createCodeNotFoundError(
          codeId: skir.recordId("join_code:missing"),
        ).requireAccepted,
        404,
        "Join Code not found",
      ),
    };
    for (final MapEntry(key: reason, value: (accept, code, message))
        in rejections.entries) {
      test("rejects $reason with code $code and its reason", () {
        expect(
          accept,
          throwsA(
            isA<ApiException>()
                .having((error) => error.code, "code", code)
                .having((error) => error.message, "message", message),
          ),
        );
      });
    }
  });
}
