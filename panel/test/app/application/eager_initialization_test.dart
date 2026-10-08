import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:oidc/oidc.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class _StartupAuth extends Auth {
  _StartupAuth(this.initialize, this.signedOut);
  final Future<OidcUserManager?> Function() initialize;
  final VoidCallback signedOut;

  @override
  Future<OidcUserManager?> build() => initialize();

  @override
  Future<void> signOut() async => signedOut();
}

void main() {
  for (final boundary in [
    "telemetry",
    "sentinel",
    "authentication",
    "token",
    "identity",
  ]) {
    testWidgets("Retry recovers the actual $boundary startup dependency", (
      tester,
    ) async {
      var authBuilds = 0;
      var telemetryBuilds = 0;
      var sentinelBuilds = 0;
      var signOuts = 0;
      final failure = StateError("$boundary unavailable");
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          panelTelemetryProvider.overrideWith((ref) async {
            telemetryBuilds++;
            if (boundary == "telemetry" && telemetryBuilds == 1) throw failure;
            return const NoopPanelTelemetry();
          }),
          sentinelCredentialsProvider.overrideWith((ref) async {
            sentinelBuilds++;
            if (boundary == "sentinel" && sentinelBuilds == 1) throw failure;
            return skir.GetSentinelCredentialsResponse_Success(
              jwt: "fixture",
              seed: "fixture",
            );
          }),
          authProvider.overrideWith(
            () => _StartupAuth(() async {
              authBuilds++;
              if (boundary == "authentication" && authBuilds == 1) {
                throw failure;
              }
              return null;
            }, () => signOuts++),
          ),
          if (boundary == "token" || boundary == "identity")
            isAuthenticatedProvider.overrideWith((ref) async {
              await ref.watch(authProvider.future);
              return true;
            }),
          accessTokenProvider.overrideWith((ref) async {
            await ref.watch(authProvider.future);
            if (boundary == "token" && authBuilds == 1) throw failure;
            return const AccessToken(token: "fixture");
          }),
          authUserInfoProvider.overrideWith((ref) async {
            await ref.watch(authProvider.future);
            if (boundary == "identity" && authBuilds == 1) throw failure;
            return const UserInfo(sub: "fixture");
          }),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EagerInitialization(
            child: MaterialApp(home: Text("Startup ready")),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Startup ready"), findsNothing);
      expect(find.textContaining("$boundary unavailable"), findsOneWidget);
      expect(find.text("Retry"), findsOneWidget);
      await tester.tap(find.text("Retry"));
      await tester.pumpAndSettle();
      expect(find.text("Startup ready"), findsOneWidget);
      expect(signOuts, 0);
      expect(telemetryBuilds, boundary == "telemetry" ? 2 : 1);
      expect(sentinelBuilds, boundary == "sentinel" ? 2 : 1);
      expect(
        authBuilds,
        ["authentication", "token", "identity"].contains(boundary) ? 2 : 1,
      );
    });
  }

  testWidgets("a repeated startup failure remains retryable without sign out", (
    tester,
  ) async {
    var authBuilds = 0;
    var signOuts = 0;
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        sentinelCredentialsProvider.overrideWithValue(
          AsyncData(
            skir.GetSentinelCredentialsResponse_Success(
              jwt: "fixture",
              seed: "fixture",
            ),
          ),
        ),
        authProvider.overrideWith(
          () => _StartupAuth(() async {
            authBuilds++;
            throw StateError("initialization unavailable");
          }, () => signOuts++),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const EagerInitialization(
          child: MaterialApp(home: Text("Startup ready")),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 2; attempt++) {
      expect(find.text("Retry"), findsOneWidget);
      await tester.tap(find.text("Retry"));
      await tester.pumpAndSettle();
      expect(find.textContaining("initialization unavailable"), findsOneWidget);
      expect(find.text("Startup ready"), findsNothing);
      expect(find.text("Could not sign out. Please try again."), findsNothing);
      expect(authBuilds, attempt + 2);
      expect(signOuts, 0);
    }
  });
}
