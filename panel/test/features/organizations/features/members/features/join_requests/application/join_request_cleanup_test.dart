import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/join_requests_test_support.dart";

void main() {
  group("cleanupExpiredRequests", () {
    OrganizationJoinRequest createRequest({
      required String id,
      required DateTime expiresAt,
    }) => OrganizationJoinRequest(
      requestId: recordId("request_to_join:$id"),
      userId: recordId("user:$id"),
      requestedAt: DateTime.utc(2024),
      expiresAt: expiresAt,
    );

    test(
      "removes expired requests and preserves active request order",
      () async {
        final activeFirst = createRequest(
          id: "active-first",
          expiresAt: DateTime.utc(2100),
        );
        final expired = createRequest(
          id: "expired",
          expiresAt: DateTime.utc(2020),
        );
        final activeLast = createRequest(
          id: "active-last",
          expiresAt: DateTime.utc(2100),
        );
        final container = ProviderContainer.test(
          overrides: [
            organizationJoinRequestsProvider.overrideWith(
              () =>
                  MockJoinRequestsNotifier([activeFirst, expired, activeLast]),
            ),
          ],
        );

        await readJoinRequests(container);

        container
            .read(organizationJoinRequestsProvider.notifier)
            .cleanupExpiredRequests();

        expect(container.read(organizationJoinRequestsProvider).requireValue, [
          activeFirst,
          activeLast,
        ]);
      },
    );

    test("removes all requests when all are expired", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier([
              createRequest(id: "expired-1", expiresAt: DateTime.utc(2020)),
              createRequest(id: "expired-2", expiresAt: DateTime.utc(2021)),
            ]),
          ),
        ],
      );

      await readJoinRequests(container);

      container
          .read(organizationJoinRequestsProvider.notifier)
          .cleanupExpiredRequests();

      expect(
        container.read(organizationJoinRequestsProvider).requireValue,
        isEmpty,
      );
    });

    test("preserves state when no requests are expired", () async {
      final requests = [
        createRequest(id: "active-1", expiresAt: DateTime.utc(2100)),
        createRequest(id: "active-2", expiresAt: DateTime.utc(2101)),
      ];
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier(requests),
          ),
        ],
      );

      await readJoinRequests(container);

      container
          .read(organizationJoinRequestsProvider.notifier)
          .cleanupExpiredRequests();

      expect(
        container.read(organizationJoinRequestsProvider).requireValue,
        requests,
      );
    });
  });
}
