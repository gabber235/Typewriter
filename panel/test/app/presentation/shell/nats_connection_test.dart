import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
        natsAuthorizationProvider.overrideWith(
          (ref) => Stream.value(const AsyncData({})),
        ),
      ],
    );

    expect(find.text("connected"), findsOneWidget);
  });

  testWidgets("authorization refresh keeps protected content mounted", (
    tester,
  ) async {
    final authorization = StreamController<AsyncValue<Set<skir.RecordId>>>();
    addTearDown(authorization.close);
    var mounts = 0;
    await tester.pumpTestApp(
      child: RequiredNatsConnection(
        child: _MountProbe(onMount: () => mounts++),
      ),
      overrides: [
        accessTokenProvider.overrideWithValue(token),
        natsLifecycleProvider.overrideWithValue(const NatsConnected()),
        natsAuthorizationProvider.overrideWith((ref) => authorization.stream),
      ],
    );

    await tester.pump();
    authorization.add(const AsyncLoading());
    await tester.pump();
    await tester.pump();
    expect(find.text("protected content"), findsOneWidget);
    expect(find.text("Checking access"), findsOneWidget);
    expect(mounts, 1);

    authorization.add(AsyncError(Exception("secret cause"), StackTrace.empty));
    await tester.pump();
    await tester.pump();
    expect(find.text("protected content"), findsOneWidget);
    expect(find.text("Access update failed"), findsOneWidget);
    expect(find.text("Retry"), findsOneWidget);
    expect(find.textContaining("secret cause"), findsNothing);
    expect(mounts, 1);

    authorization.add(const AsyncData({}));
    await tester.pump();
    await tester.pump();
    expect(find.text("Access update failed"), findsNothing);
    expect(find.text("protected content"), findsOneWidget);
    expect(mounts, 1);
    await tester.pumpAndSettle();
  });
}

final class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

final class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const Text("protected content");
}
