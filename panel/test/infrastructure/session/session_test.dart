import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("a signed in session scopes backend calls to the provider subject "
      "and carries a token that expires with the provider lifetime", () async {
    final now = DateTime.utc(2026, 10, 27, 12);
    await withClock(Clock.fixed(now), () async {
      final container = testWorld([signedIn(ada)]).container;

      expect(await container.read(isAuthenticatedProvider.future), isTrue);
      expect(await container.read(userIdProvider.future), ada.id);
      final token = (await container.read(authSessionProvider.future))?.token;
      expect(token?.token, "access-token-${ada.id}");
      expect(token?.expiresAt, now.add(const Duration(days: 1)));
    });
  });

  test("without a session nothing claims an identity", () async {
    final container = testWorld(const []).container;

    expect(await container.read(isAuthenticatedProvider.future), isFalse);
    expect(await container.read(userIdProvider.future), isNull);
    expect(await container.read(authSessionProvider.future), isNull);
  });
}
