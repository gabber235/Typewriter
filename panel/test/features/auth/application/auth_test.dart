import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  group("UserInfo", () {
    test("holds all provided fields", () {
      const discord = DiscordInfo(
        id: "discord-123",
        username: "testuser",
        avatarUrl: "https://cdn.discord.com/avatar.png",
        email: "discord@example.com",
        roles: ["role1", "role2"],
      );

      const userInfo = UserInfo(
        sub: "user-sub-123",
        name: "Test User",
        username: "testuser",
        email: "test@example.com",
        avatarUrl: "https://example.com/avatar.png",
        emailVerified: true,
        entitlements: ["premium", "beta"],
        groups: ["group1", "group2"],
        discord: discord,
      );

      expect(userInfo.sub, equals("user-sub-123"));
      expect(userInfo.name, equals("Test User"));
      expect(userInfo.username, equals("testuser"));
      expect(userInfo.email, equals("test@example.com"));
      expect(userInfo.avatarUrl, equals("https://example.com/avatar.png"));
      expect(userInfo.emailVerified, isTrue);
      expect(userInfo.entitlements, equals(["premium", "beta"]));
      expect(userInfo.groups, equals(["group1", "group2"]));
      expect(userInfo.discord, equals(discord));
    });

    test("allows null optional fields", () {
      const userInfo = UserInfo(sub: "minimal-user");

      expect(userInfo.sub, equals("minimal-user"));
      expect(userInfo.name, isNull);
      expect(userInfo.username, isNull);
      expect(userInfo.email, isNull);
      expect(userInfo.avatarUrl, isNull);
      expect(userInfo.emailVerified, isNull);
      expect(userInfo.entitlements, isNull);
      expect(userInfo.groups, isNull);
      expect(userInfo.discord, isNull);
    });
  });

  group("DiscordInfo", () {
    test("holds all provided fields", () {
      const discord = DiscordInfo(
        id: "discord-456",
        username: "discorduser",
        avatarUrl: "https://cdn.discord.com/avatar2.png",
        email: "discord2@example.com",
        roles: ["admin", "moderator"],
      );

      expect(discord.id, equals("discord-456"));
      expect(discord.username, equals("discorduser"));
      expect(discord.avatarUrl, equals("https://cdn.discord.com/avatar2.png"));
      expect(discord.email, equals("discord2@example.com"));
      expect(discord.roles, equals(["admin", "moderator"]));
    });

    test("allows null optional fields", () {
      const discord = DiscordInfo(id: "minimal-discord");

      expect(discord.id, equals("minimal-discord"));
      expect(discord.username, isNull);
      expect(discord.avatarUrl, isNull);
      expect(discord.email, isNull);
      expect(discord.roles, isNull);
    });
  });

  group("AccessToken", () {
    test("holds token and expiry", () {
      final expiresAt = DateTime(2025, 12, 31, 23, 59, 59);
      final token = AccessToken(
        token: "access-token-xyz",
        expiresAt: expiresAt,
      );

      expect(token.token, equals("access-token-xyz"));
      expect(token.expiresAt, equals(expiresAt));
    });

    test("allows null expiry", () {
      const token = AccessToken(token: "no-expiry-token");

      expect(token.token, equals("no-expiry-token"));
      expect(token.expiresAt, isNull);
    });
  });

  group("authUserInfoProvider", () {
    test("provides user info when overridden", () async {
      const testUserInfo = UserInfo(
        sub: "test-user-sub",
        name: "Test User",
        email: "test@example.com",
      );

      final container = ProviderContainer.test(
        overrides: authProviderOverrides(userInfo: testUserInfo),
      );

      final userInfo = await container.read(authUserInfoProvider.future);

      expect(userInfo.sub, equals("test-user-sub"));
      expect(userInfo.name, equals("Test User"));
      expect(userInfo.email, equals("test@example.com"));
    });

    test("uses default mock user when no override specified", () async {
      final container = ProviderContainer.test(
        overrides: authProviderOverrides(),
      );

      final userInfo = await container.read(authUserInfoProvider.future);

      expect(userInfo.sub, equals("1"));
      expect(userInfo.name, equals("John Doe"));
      expect(userInfo.email, equals("john.doe@example.com"));
    });
  });

  group("userIdProvider", () {
    test("returns sub when authenticated", () async {
      const testUserInfo = UserInfo(sub: "unique-user-id-123");

      final container = ProviderContainer.test(
        overrides: [
          ...authProviderOverrides(userInfo: testUserInfo),
          isAuthenticatedProvider.overrideWithValue(
            const AsyncValue.data(true),
          ),
        ],
      );

      final userId = await container.read(userIdProvider.future);

      expect(userId, equals("unique-user-id-123"));
    });

    test("returns null when not authenticated", () async {
      final container = ProviderContainer.test(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(
            const AsyncValue.data(false),
          ),
        ],
      );

      final userId = await container.read(userIdProvider.future);

      expect(userId, isNull);
    });
  });

  group("isAuthenticatedProvider", () {
    test("returns true when overridden as authenticated", () async {
      final container = ProviderContainer.test(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(
            const AsyncValue.data(true),
          ),
        ],
      );

      final isAuthenticated = await container.read(
        isAuthenticatedProvider.future,
      );

      expect(isAuthenticated, isTrue);
    });

    test("returns false when overridden as not authenticated", () async {
      final container = ProviderContainer.test(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(
            const AsyncValue.data(false),
          ),
        ],
      );

      final isAuthenticated = await container.read(
        isAuthenticatedProvider.future,
      );

      expect(isAuthenticated, isFalse);
    });
  });

  group("accessTokenProvider", () {
    test("returns token when overridden", () async {
      final expiresAt = DateTime(2025, 6, 15, 12, 0, 0);
      final testToken = AccessToken(
        token: "test-access-token",
        expiresAt: expiresAt,
      );

      final container = ProviderContainer.test(
        overrides: [
          accessTokenProvider.overrideWithValue(AsyncValue.data(testToken)),
        ],
      );

      final token = await container.read(accessTokenProvider.future);

      expect(token, isNotNull);
      expect(token!.token, equals("test-access-token"));
      expect(token.expiresAt, equals(expiresAt));
    });

    test("returns null when no token available", () async {
      final container = ProviderContainer.test(
        overrides: [
          accessTokenProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      );

      final token = await container.read(accessTokenProvider.future);

      expect(token, isNull);
    });
  });
}
