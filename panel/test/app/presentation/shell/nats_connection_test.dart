import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  const token = AsyncData(AccessToken(token: "access-token"));

  for (final (kind, title, action) in [
    (NatsFailureKind.authentication, "Access denied", "Sign out"),
    (NatsFailureKind.permission, "Access denied", "Sign out"),
    (NatsFailureKind.protocol, "Connection incompatible", "Retry"),
    (NatsFailureKind.unavailable, "Server unavailable", "Retry"),
    (NatsFailureKind.timeout, "Server unavailable", "Retry"),
    (NatsFailureKind.noResponders, "Server unavailable", "Retry"),
    (NatsFailureKind.closed, "Connection failed", "Retry"),
    (NatsFailureKind.unknown, "Connection failed", "Retry"),
  ]) {
    testWidgets("$kind shows its actionable failure category", (tester) async {
      await tester.pumpTestApp(
        child: const RequiredNatsConnection(child: Text("connected")),
        overrides: [
          accessTokenProvider.overrideWithValue(token),
          natsLifecycleProvider.overrideWithValue(
            NatsFailed(
              NatsClientException(kind: kind, message: "safe message"),
            ),
          ),
        ],
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(action), findsOneWidget);
    });
  }

  testWidgets("unknown failure never renders secret cause", (tester) async {
    const secret = "super-secret-token";
    await tester.pumpTestApp(
      child: const RequiredNatsConnection(child: Text("connected")),
      overrides: [
        accessTokenProvider.overrideWithValue(token),
        natsLifecycleProvider.overrideWithValue(
          NatsFailed(
            NatsClientException(
              kind: NatsFailureKind.unknown,
              message: secret,
              cause: secret,
            ),
          ),
        ),
      ],
    );

    expect(find.text("Connection failed"), findsOneWidget);
    expect(find.text("Retry"), findsOneWidget);
    expect(find.textContaining(secret), findsNothing);
  });

  testWidgets("connected state renders protected content", (tester) async {
    await tester.pumpTestApp(
      child: const RequiredNatsConnection(child: Text("connected")),
      overrides: [
        accessTokenProvider.overrideWithValue(token),
        natsLifecycleProvider.overrideWithValue(const NatsConnected()),
      ],
    );

    expect(find.text("connected"), findsOneWidget);
  });
}
