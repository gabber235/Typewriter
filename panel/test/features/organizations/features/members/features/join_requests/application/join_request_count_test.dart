import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

import "support/join_requests_test_support.dart";

void main() {
  Future<int> getCount(ProviderContainer container) => readProviderValue(
    (listener) => container.listen(
      joinRequestCountProvider,
      listener,
      fireImmediately: true,
    ),
  );

  group("join request count", () {
    OrganizationJoinRequest createRequest({required bool expired}) {
      final now = DateTime.now();
      return OrganizationJoinRequest(
        requestId: recordId(
          "request_to_join:req-${now.millisecondsSinceEpoch}-${expired ? "exp" : "active"}",
        ),
        userId: recordId("user:user1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: now.subtract(const Duration(hours: 1)),
        expiresAt: expired
            ? now.subtract(const Duration(hours: 1))
            : now.add(const Duration(hours: 24)),
      );
    }

    test("returns 0 when provider is loading", () {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            LoadingJoinRequestsNotifier.new,
          ),
        ],
      );

      expect(container.read(joinRequestCountProvider), 0);
    });

    test("returns 0 when provider has error", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            ErrorJoinRequestsNotifier.new,
          ),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen(organizationJoinRequestsProvider, (
        previous,
        next,
      ) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      try {
        await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TestFailure(
            "organizationJoinRequestsProvider did not emit AsyncError",
          ),
        );
      } finally {
        sub.close();
      }

      expect(container.read(joinRequestCountProvider), 0);
    });

    test("returns 0 for empty list", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier([]),
          ),
        ],
      );

      await readJoinRequests(container);
      expect(await getCount(container), 0);
    });

    test("returns 0 when all requests are expired", () async {
      final expiredRequests = [
        createRequest(expired: true),
        createRequest(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier(expiredRequests),
          ),
        ],
      );

      await readJoinRequests(container);
      expect(await getCount(container), 0);
    });

    test("counts all active requests", () async {
      final activeRequests = [
        createRequest(expired: false),
        createRequest(expired: false),
        createRequest(expired: false),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier(activeRequests),
          ),
        ],
      );

      await readJoinRequests(container);
      expect(await getCount(container), 3);
    });

    test("counts only non-expired requests in mixed list", () async {
      final mixedRequests = [
        createRequest(expired: false),
        createRequest(expired: true),
        createRequest(expired: false),
        createRequest(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => MockJoinRequestsNotifier(mixedRequests),
          ),
        ],
      );

      await readJoinRequests(container);
      expect(await getCount(container), 2);
    });
  });
}
