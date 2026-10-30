import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _discord = {
  "id": "discord-ada",
  "username": "ada.discord",
  "avatar_url": "https://cdn.test/discord.png",
  "roles": ["writer"],
};

void main() {
  group("avatar", () {
    for (final (source, claims, avatar) in [
      (
        "the provider avatar",
        {
          "avatar_url": "https://cdn.test/provider.png",
          "discord": _discord,
          "picture": "https://cdn.test/picture.png",
        },
        "https://cdn.test/provider.png",
      ),
      (
        "the Discord avatar",
        {"discord": _discord, "picture": "https://cdn.test/picture.png"},
        "https://cdn.test/discord.png",
      ),
      (
        "the picture",
        {"picture": "https://cdn.test/picture.png"},
        "https://cdn.test/picture.png",
      ),
      ("nothing", <String, Object?>{}, null),
    ]) {
      test("falls back to $source", () async {
        expect(
          (await testWorld([signedIn(ada.withClaims(claims))]).container
                  .read(authUserInfoProvider.future))
              .avatarUrl,
          avatar,
        );
      });
    }
  });

  group("username", () {
    for (final (source, claims, username) in [
      (
        "the preferred username",
        {"preferred_username": "ada.l", "nickname": "Countess"},
        "ada.l",
      ),
      (
        "the nickname",
        {"preferred_username": null, "nickname": "Countess"},
        "Countess",
      ),
      ("the name", {"preferred_username": null}, ada.name),
    ]) {
      test("falls back to $source", () async {
        expect(
          (await testWorld([signedIn(ada.withClaims(claims))]).container
                  .read(authUserInfoProvider.future))
              .username,
          username,
        );
      });
    }
  });

  test("a Discord profile is read from its claims", () async {
    final account = await testWorld([
      signedIn(ada.withClaims({"discord": _discord})),
    ]).container.read(authUserInfoProvider.future);

    expect(
      account.discord,
      const DiscordInfo(
        id: "discord-ada",
        username: "ada.discord",
        avatarUrl: "https://cdn.test/discord.png",
        roles: ["writer"],
      ),
    );
  });

  test("without a session there is no account to show", () async {
    final container = testWorld(const []).container;

    await expectLater(
      container.read(authUserInfoProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
