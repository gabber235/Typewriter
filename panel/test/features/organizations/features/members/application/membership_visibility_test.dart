import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../features/join_codes/application/support/join_codes_test_support.dart"
    as codes;
import "../features/join_requests/application/support/join_requests_test_support.dart"
    as requests;

void main() {
  test("expiry timer removes a request without manual clock changes", () async {
    final request = OrganizationJoinRequest(
      requestId: skir.recordId("request_to_join:soon_expired"),
      userId: skir.recordId("user:soon_expired"),
      requestedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(milliseconds: 200)),
    );
    final container = ProviderContainer.test(
      overrides: [
        pendingMembershipRemovalsProvider.overrideWithValue(const {}),
        organizationJoinRequestsProvider.overrideWith(
          () => requests.MockJoinRequestsNotifier([request]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final firstVisible = Completer<void>();
    final expired = Completer<void>();
    final subscription = container.listen(
      visibleOrganizationJoinRequestsProvider,
      (_, next) {
        if (next case AsyncData(:final value)) {
          if (value.contains(request) && !firstVisible.isCompleted) {
            firstVisible.complete();
          }
          if (firstVisible.isCompleted &&
              value.isEmpty &&
              !expired.isCompleted) {
            expired.complete();
          }
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await firstVisible.future.timeout(const Duration(seconds: 2));
    await expired.future.timeout(const Duration(seconds: 2));
    expect(container.read(organizationJoinRequestsProvider).requireValue, [
      request,
    ]);
  });

  test(
    "derived visibility filters expiry without changing confirmed snapshots",
    () async {
      final activeRequest = OrganizationJoinRequest(
        requestId: skir.recordId("request_to_join:active"),
        userId: skir.recordId("user:active"),
        requestedAt: DateTime.utc(2025),
        expiresAt: DateTime.utc(2100),
      );
      final expiredRequest = OrganizationJoinRequest(
        requestId: skir.recordId("request_to_join:expired"),
        userId: skir.recordId("user:expired"),
        requestedAt: DateTime.utc(2020),
        expiresAt: DateTime.utc(2021),
      );
      final activeCode = OrganizationJoinCode(
        code: skir.recordId("join_code:active"),
        createdAt: DateTime.utc(2025),
        expiresAt: null,
      );
      final expiredCode = OrganizationJoinCode(
        code: skir.recordId("join_code:expired"),
        createdAt: DateTime.utc(2020),
        expiresAt: DateTime.utc(2021),
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

      final requestsReady = Completer<List<OrganizationJoinRequest>>();
      final codesReady = Completer<List<OrganizationJoinCode>>();
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
