import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../application/support/members_test_support.dart";
import "support/join_requests_test_support.dart";

void main() {
  group("Organization join request command errors", () {
    late MockNatsClient mockNats;

    setUp(() => mockNats = MockNatsClient());
    tearDown(() => mockNats.dispose());

    Matcher apiException(int code, String message) => isA<ApiException>()
        .having((error) => error.code, "code", code)
        .having((error) => error.message, "message", message);

    final approveRequestErrors =
        <
          ({
            String name,
            skir.ApproveOrganizationJoinRequestResponse response,
            int code,
            String message,
          })
        >[
          (
            name: "roles required",
            response: skir
                .ApproveOrganizationJoinRequestResponse.createRolesRequiredError(),
            code: 400,
            message: "At least one role is required",
          ),
          (
            name: "user already member",
            response:
                skir.ApproveOrganizationJoinRequestResponse.createUserAlreadyMemberError(
                  userId: testMemberId,
                ),
            code: 409,
            message: "User is already an organization member",
          ),
        ];

    for (final outcome in approveRequestErrors) {
      test("approveRequest maps ${outcome.name}", () async {
        final request = OrganizationJoinRequest(
          requestId: recordId("request_to_join:req-1"),
          userId: recordId("user:m1"),
          requestedAt: testTimestamp,
          expiresAt: testTimestamp.add(const Duration(days: 1)),
        );
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => testUserId),
            organizationIdProvider.overrideWith((ref) => testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationJoinRequestsProvider.overrideWith(
              () => MockJoinRequestsNotifier([request]),
            ),
          ],
        );
        final subscription =
            await retainUntilReady<List<OrganizationJoinRequest>>(
              (listener) => container.listen(
                organizationJoinRequestsProvider,
                listener,
                fireImmediately: true,
              ),
            );
        addTearDown(subscription.close);
        final subject =
            "cloud.to.user.$testUserId.organization.${testOrganizationId.id}.members.join_requests.approve";
        mockNats.registerHandler(
          subject,
          (data) => skir.ApproveOrganizationJoinRequestResponse.serializer
              .toBytes(outcome.response),
        );

        await expectLater(
          container
              .read(organizationJoinRequestsProvider.notifier)
              .approveRequest(request.requestId, []),
          throwsA(apiException(outcome.code, outcome.message)),
        );
      });
    }
  });
}
