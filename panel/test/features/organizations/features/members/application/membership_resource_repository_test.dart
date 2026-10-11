import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

final class _Telemetry implements PanelTelemetry {
  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Map<String, String> headers) operation,
  }) => operation(const {});

  @override
  Future<Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<Response> Function(Map<String, String> headers) operation,
  }) => operation(const {});
}

void main() {
  test(
    "prepared membership command freezes values and emits confirmed fact",
    () async {
      final nats = FakeNatsClient(actorId: testUserId);
      addTearDown(nats.dispose);
      final session = ResourceRepositories(
        SkirMutationClient(() => nats, () async => _Telemetry()),
        testUserId,
      );
      addTearDown(session.dispose);
      final repository = session.membership(testOrganizationId);
      final events = <skir.OrganizationMembersChanged>[];
      final subscription = repository.members.listen(events.add);
      addTearDown(subscription.cancel);
      final role = createRole(id: "editor", assignable: true);
      final protected = createRole(id: "founder", assignable: false);
      late skir.UpdateOrganizationMemberRolesRequest firstRequest;
      nats.registerHandler(memberUpdateSubject, (bytes) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(bytes);
        if (nats.requests.length == 1) firstRequest = request;
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            members: const [],
            event: skir.OrganizationMembersChanged(
              sequence: 4,
              changes: const [],
            ),
          ),
        );
      });

      final command = repository.updateRoles([testMemberId], [role, protected]);
      final first = await command.send();
      final second = await command.send();

      expect(command.replay, SubmissionReplay.unsupported);
      expect(firstRequest.userIds, [testMemberId]);
      expect(firstRequest.roleIds, [role.roleId]);
      expect(nats.requests[0].payload, nats.requests[1].payload);
      expect(
        first,
        isA<SubmissionConfirmed<skir.UpdateOrganizationMemberRolesResponse>>(),
      );
      expect(
        second,
        isA<SubmissionConfirmed<skir.UpdateOrganizationMemberRolesResponse>>(),
      );

      await command.integrate!(first);
      expect(events.single.sequence, 4);
    },
  );

  test("membership owner rejects missing identity and use after disposal", () {
    final nats = FakeNatsClient();
    addTearDown(nats.dispose);
    final unauthenticated = ResourceRepositories(
      SkirMutationClient(() => nats, () async => _Telemetry()),
      null,
    );
    expect(
      () => unauthenticated.membership(testOrganizationId).remove(testMemberId),
      throwsA(isA<ApiException>()),
    );
    unauthenticated.dispose();
    expect(
      () => unauthenticated.membership(testOrganizationId),
      throwsStateError,
    );
  });

  test("disposed owner rejects integration of an in flight command", () async {
    final nats = FakeNatsClient(actorId: testUserId);
    addTearDown(nats.dispose);
    final response = Completer<Uint8List>();
    nats.registerHandler(memberRemoveSubject, (_) => response.future);
    final session = ResourceRepositories(
      SkirMutationClient(() => nats, () async => _Telemetry()),
      testUserId,
    );
    final repository = session.membership(testOrganizationId);
    final events = <skir.OrganizationMembersChanged>[];
    final subscription = repository.members.listen(events.add);
    addTearDown(subscription.cancel);
    final command = repository.remove(testMemberId);
    final sending = command.send();
    await pumpEventQueue();

    session.dispose();
    response.complete(
      skir.RemoveOrganizationMemberResponse.serializer.toBytes(
        skir.RemoveOrganizationMemberResponse.createSuccess(
          event: skir.OrganizationMembersChanged(
            sequence: 7,
            changes: [skir.OrganizationMembersChange.wrapRemove(testMemberId)],
          ),
        ),
      ),
    );
    final result = await sending;
    expect(
      result,
      isA<SubmissionConfirmed<skir.RemoveOrganizationMemberResponse>>(),
    );
    await expectLater(command.integrate!(result), throwsStateError);
    expect(events, isEmpty);
  });

  test("membership response adapters reject unconfirmed outcomes", () {
    expect(
      skir.UpdateOrganizationMemberRolesResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
    expect(
      skir.RemoveOrganizationMemberResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
    expect(
      skir.ApproveOrganizationJoinRequestsResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
    expect(
      skir.DeclineOrganizationJoinRequestResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
    expect(
      skir.GenerateOrganizationJoinCodeResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
    expect(
      skir.RevokeOrganizationJoinCodeResponse.createInternalError()
          .requireAccepted,
      throwsA(isA<ApiException>()),
    );
  });

  test("membership response adapters preserve domain rejection meaning", () {
    Matcher apiFailure(int code, String message) => isA<ApiException>()
        .having((error) => error.code, "code", code)
        .having((error) => error.message, "message", message);

    expect(
      skir.UpdateOrganizationMemberRolesResponse.createRolesNotAssignableError(
        userIds: [testMemberId],
        roleIds: [skir.recordId("organization_role:founder")],
      ).requireAccepted,
      throwsA(apiFailure(400, "One or more roles cannot be assigned")),
    );
    expect(
      skir.RemoveOrganizationMemberResponse.createFounderCannotBeRemovedError(
        userId: testMemberId,
      ).requireAccepted,
      throwsA(apiFailure(409, "Organization founder cannot be removed")),
    );
    expect(
      skir.ApproveOrganizationJoinRequestsResponse.createRolesRequiredError()
          .requireAccepted,
      throwsA(apiFailure(400, "At least one role is required")),
    );
    expect(
      skir.DeclineOrganizationJoinRequestResponse.createRequestNotFoundError(
        requestId: skir.recordId("request_to_join:missing"),
      ).requireAccepted,
      throwsA(apiFailure(404, "Request not found")),
    );
    expect(
      skir.GenerateOrganizationJoinCodeResponse.createRolesNotAssignableError(
        roleIds: [skir.recordId("organization_role:founder")],
      ).requireAccepted,
      throwsA(apiFailure(400, "One or more roles cannot be assigned")),
    );
    expect(
      skir.RevokeOrganizationJoinCodeResponse.createCodeNotFoundError(
        codeId: skir.recordId("join_code:missing"),
      ).requireAccepted,
      throwsA(apiFailure(404, "Join Code not found")),
    );
  });
}
