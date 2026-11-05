import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);

  test("the join code count is 0 while the codes are loading", () {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(joinCodes: null),
    ]);

    expect(world.container.read(joinCodeCountProvider), 0);
  });

  test("the join code count holds active and never expiring codes, "
      "not expired ones", () async {
    await withClock(Clock.fixed(now), () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        membership(
          joinCodes: [
            joinCode("active", expiresAt: now.add(const Duration(days: 7))),
            joinCode("expired", expiresAt: now.add(const Duration(days: -1))),
            joinCode("forever"),
          ],
        ),
      ]);
      final count = world.container.listen(joinCodeCountProvider, (_, _) {});
      addTearDown(count.close);
      await world.container.read(organizationJoinCodesProvider.future);

      expect(count.read(), 2);
    });
  });
}
