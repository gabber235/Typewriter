import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _now = DateTime.utc(2026, 10, 27, 12);

final _yesterday = _now.subtract(const Duration(days: 1));

void main() {
  test("a join request leaves the visible list the moment it expires", () {
    fakeAsync((async) {
      withClock(async.getClock(_now), () {
        final request = joinRequest(
          "soon",
          requestedAt: _yesterday,
          expiresAt: _now.add(const Duration(milliseconds: 200)),
        );
        final world = testWorld([
          signedIn(ada, organization: acme),
          membership(joinRequests: [request]),
        ]);
        final visible = world.container.listen(
          visibleOrganizationJoinRequestsProvider,
          (_, _) {},
        );

        async.flushMicrotasks();
        expect(visible.read().value, [request]);
        async.elapse(const Duration(milliseconds: 199));
        expect(visible.read().value, [request]);
        async.elapse(const Duration(milliseconds: 1));
        expect(visible.read().value, isEmpty);
        expect(world.container.read(organizationJoinRequestsProvider).value, [
          request,
        ]);
        visible.close();
      });
    });
  });

  test("expired requests and codes are hidden while the confirmed lists "
      "keep them", () async {
    await withClock(Clock.fixed(_now), () async {
      final activeRequest = joinRequest(
        "active",
        requestedAt: _yesterday,
        expiresAt: DateTime.utc(2100),
      );
      final expiredRequest = joinRequest(
        "expired",
        requestedAt: _yesterday,
        expiresAt: DateTime.utc(2021),
      );
      final activeCode = joinCode("active", createdAt: _yesterday);
      final expiredCode = joinCode(
        "expired",
        createdAt: _yesterday,
        expiresAt: DateTime.utc(2021),
      );
      final world = testWorld([
        signedIn(ada, organization: acme),
        membership(
          joinRequests: [activeRequest, expiredRequest],
          joinCodes: [activeCode, expiredCode],
        ),
      ]);
      final requests = world.container.listen(
        visibleOrganizationJoinRequestsProvider,
        (_, _) {},
      );
      final codes = world.container.listen(
        visibleOrganizationJoinCodesProvider,
        (_, _) {},
      );
      addTearDown(requests.close);
      addTearDown(codes.close);

      expect(
        await world.container.read(organizationJoinRequestsProvider.future),
        [activeRequest, expiredRequest],
      );
      expect(await world.container.read(organizationJoinCodesProvider.future), [
        activeCode,
        expiredCode,
      ]);
      expect(requests.read().value, [activeRequest]);
      expect(codes.read().value, [activeCode]);
    });
  });
}
