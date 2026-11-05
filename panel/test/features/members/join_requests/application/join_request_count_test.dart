import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);

  test("the join request count is 0 while the requests are loading", () {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(joinRequests: null),
    ]);

    expect(world.container.read(joinRequestCountProvider), 0);
  });

  test("the join request count is 0 when the requests fail to load", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        joinRequests: null,
        failure: ApiException.internalServerError(),
      ),
    ]);
    final count = world.container.listen(joinRequestCountProvider, (_, _) {});
    addTearDown(count.close);

    await expectLater(
      world.container.read(organizationJoinRequestsProvider.future),
      throwsA(isA<ApiException>()),
    );
    expect(count.read(), 0);
  });

  test("the join request count holds only requests not yet expired", () async {
    await withClock(Clock.fixed(now), () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        membership(
          joinRequests: [
            joinRequest("first", expiresAt: now.add(const Duration(hours: 24))),
            joinRequest(
              "lapsed",
              expiresAt: now.add(const Duration(hours: -1)),
            ),
            joinRequest("second", expiresAt: now.add(const Duration(hours: 1))),
            joinRequest("gone", expiresAt: now.add(const Duration(hours: -24))),
          ],
        ),
      ]);
      final count = world.container.listen(joinRequestCountProvider, (_, _) {});
      addTearDown(count.close);
      await world.container.read(organizationJoinRequestsProvider.future);

      expect(count.read(), 2);
    });
  });
}
