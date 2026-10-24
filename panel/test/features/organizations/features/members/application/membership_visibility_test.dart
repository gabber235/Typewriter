import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../features/join_codes/application/support/join_codes_test_support.dart"
    as codes;
import "../features/join_requests/application/support/join_requests_test_support.dart"
    as requests;

void main() {
  test("expiry timer removes a request without manual invalidation", () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime.utc(2026));
      final request = skir.OrganizationJoinRequest(
        requestId: skir.recordId("request_to_join:soon_expired"),
        userId: skir.recordId("user:soon_expired"),
        requestedAt: clock.now(),
        expiresAt: clock.now().add(const Duration(milliseconds: 200)),
        userName: null,
        userEmail: null,
        userAvatarUrl: null,
      );
      final container = ProviderContainer.test(
        overrides: [
          membershipDisplayTimeProvider.overrideWith((ref) => clock.now()),
          pendingMembershipRemovalsProvider.overrideWithValue(const {}),
          organizationJoinRequestsProvider.overrideWith(
            () => requests.MockJoinRequestsNotifier([request]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final observations = <List<skir.OrganizationJoinRequest>>[];
      final subscription = container.listen(
        visibleOrganizationJoinRequestsProvider,
        (_, next) {
          if (next case AsyncData(:final value)) {
            observations.add(value);
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      async
        ..flushMicrotasks()
        ..elapse(Duration.zero);
      expect(observations.last, [request]);
      async.elapse(const Duration(milliseconds: 199));
      expect(observations.last, [request]);
      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();
      expect(observations.last, isEmpty);
      expect(container.read(organizationJoinRequestsProvider).requireValue, [
        request,
      ]);
      subscription.close();
      container.dispose();
    });
  });

  test(
    "derived visibility filters expiry without changing confirmed snapshots",
    () async {
      final activeRequest = skir.OrganizationJoinRequest(
        requestId: skir.recordId("request_to_join:active"),
        userId: skir.recordId("user:active"),
        requestedAt: DateTime.utc(2025),
        expiresAt: DateTime.utc(2100),
        userName: null,
        userEmail: null,
        userAvatarUrl: null,
      );
      final expiredRequest = skir.OrganizationJoinRequest(
        requestId: skir.recordId("request_to_join:expired"),
        userId: skir.recordId("user:expired"),
        requestedAt: DateTime.utc(2020),
        expiresAt: DateTime.utc(2021),
        userName: null,
        userEmail: null,
        userAvatarUrl: null,
      );
      final activeCode = skir.JoinCode(
        code: skir.recordId("join_code:active"),
        createdAt: DateTime.utc(2025),
        expiresAt: null,
        singleUse: true,
        autoAccept: skir.JoinCode_AutoAccept(roleIds: const []),
      );
      final expiredCode = skir.JoinCode(
        code: skir.recordId("join_code:expired"),
        createdAt: DateTime.utc(2020),
        expiresAt: DateTime.utc(2021),
        singleUse: true,
        autoAccept: skir.JoinCode_AutoAccept(roleIds: const []),
      );
      final container = ProviderContainer.test(
        overrides: [
          pendingMembershipRemovalsProvider.overrideWithValue(const {}),
          organizationJoinRequestsProvider.overrideWith(
            () => requests.MockJoinRequestsNotifier([
              activeRequest,
              expiredRequest,
            ]),
          ),
          organizationJoinCodesProvider.overrideWith(
            () => codes.MockJoinCodesNotifier([activeCode, expiredCode]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final requestsReady = Completer<List<skir.OrganizationJoinRequest>>();
      final codesReady = Completer<List<skir.JoinCode>>();
      final requestsSubscription = container.listen(
        visibleOrganizationJoinRequestsProvider,
        (_, next) {
          if (next case AsyncData(:final value)
              when !requestsReady.isCompleted) {
            requestsReady.complete(value);
          }
        },
        fireImmediately: true,
      );
      final codesSubscription = container.listen(
        visibleOrganizationJoinCodesProvider,
        (_, next) {
          if (next case AsyncData(:final value) when !codesReady.isCompleted) {
            codesReady.complete(value);
          }
        },
        fireImmediately: true,
      );
      addTearDown(requestsSubscription.close);
      addTearDown(codesSubscription.close);
      final visibleRequests = await requestsReady.future;
      final visibleCodes = await codesReady.future;

      expect(visibleRequests, [activeRequest]);
      expect(visibleCodes, [activeCode]);
      expect(container.read(organizationJoinRequestsProvider).requireValue, [
        activeRequest,
        expiredRequest,
      ]);
      expect(container.read(organizationJoinCodesProvider).requireValue, [
        activeCode,
        expiredCode,
      ]);
    },
  );
}
