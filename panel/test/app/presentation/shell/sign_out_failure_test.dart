import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:oidc/oidc.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

const _failureMessage = "Could not sign out. Please try again.";

class _FailingAuth extends Auth {
  @override
  Future<OidcUserManager?> build() async => null;

  @override
  Future<void> signOut() async => throw StateError("sign out failed");
}

class _TestAppearance extends Appearance {
  @override
  ThemeMode build() => ThemeMode.light;
}

void main() {
  testWidgets("SignOutButton surfaces one sign out failure", (tester) async {
    await tester.pumpTestApp(
      child: const Scaffold(body: SignOutButton()),
      overrides: [authProvider.overrideWith(_FailingAuth.new)],
    );

    await tester.tap(find.text("Sign out"));
    await tester.pumpAndSettle();

    expect(find.text(_failureMessage), findsOneWidget);
  });

  testWidgets("UserMenu surfaces one sign out failure", (tester) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    await tester.pumpTestApp(
      child: const Scaffold(body: UserMenu()),
      overrides: [
        authProvider.overrideWith(_FailingAuth.new),
        appearanceProvider.overrideWith(_TestAppearance.new),
        authUserInfoProvider.overrideWithValue(
          const AsyncData(
            UserInfo(
              sub: "user1",
              name: "Test User",
              avatarUrl: "https://example.com/avatar.png",
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.text("Test User"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Logout"));
    await tester.pumpAndSettle();

    expect(find.text(_failureMessage), findsOneWidget);
  });
}
