import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("cleanupExpiredRequests", () {
    UserJoinRequest createRequest({
      required String id,
      required DateTime expiresAt,
    }) => UserJoinRequest(
      requestId: recordId("request_to_join:$id"),
      organizationId: recordId("organization:$id"),
      organizationName: "Organization $id",
      organizationLogoUrl: "https://example.com/$id.png",
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
            userJoinRequestsProvider.overrideWith(
              () => MockUserJoinRequestsNotifier([
                activeFirst,
                expired,
                activeLast,
              ]),
            ),
          ],
        );

        await readUserJoinRequests(container);

        container
            .read(userJoinRequestsProvider.notifier)
            .cleanupExpiredRequests();

        expect(container.read(userJoinRequestsProvider).requireValue, [
          activeFirst,
          activeLast,
        ]);
      },
    );

    test("removes all requests when all are expired", () async {
      final container = ProviderContainer.test(
        overrides: [
          userJoinRequestsProvider.overrideWith(
            () => MockUserJoinRequestsNotifier([
              createRequest(id: "expired-1", expiresAt: DateTime.utc(2020)),
              createRequest(id: "expired-2", expiresAt: DateTime.utc(2021)),
            ]),
          ),
        ],
      );

      await readUserJoinRequests(container);

      container
          .read(userJoinRequestsProvider.notifier)
          .cleanupExpiredRequests();

      expect(container.read(userJoinRequestsProvider).requireValue, isEmpty);
    });

    test("preserves state when no requests are expired", () async {
      final requests = [
        createRequest(id: "active-1", expiresAt: DateTime.utc(2100)),
        createRequest(id: "active-2", expiresAt: DateTime.utc(2101)),
      ];
      final container = ProviderContainer.test(
        overrides: [
          userJoinRequestsProvider.overrideWith(
            () => MockUserJoinRequestsNotifier(requests),
          ),
        ],
      );

      await readUserJoinRequests(container);

      container
          .read(userJoinRequestsProvider.notifier)
          .cleanupExpiredRequests();

      expect(container.read(userJoinRequestsProvider).requireValue, requests);
    });
  });
}

Future<List<UserJoinRequest>> readUserJoinRequests(
  ProviderContainer container,
) async {
  final result = Completer<List<UserJoinRequest>>();
  final subscription = container.listen(userJoinRequestsProvider, (
    previous,
    next,
  ) {
    if (result.isCompleted) return;
    switch (next) {
      case AsyncData(:final value):
        result.complete(value);
      case AsyncError(:final error, :final stackTrace):
        result.completeError(error, stackTrace);
      default:
    }
  }, fireImmediately: true);
  try {
    return await result.future;
  } finally {
    subscription.close();
  }
}

class MockUserJoinRequestsNotifier extends UserJoinRequests {
  MockUserJoinRequestsNotifier(this.requests);

  final List<UserJoinRequest> requests;

  @override
  Stream<List<UserJoinRequest>> build() async* {
    yield requests;
  }
}
