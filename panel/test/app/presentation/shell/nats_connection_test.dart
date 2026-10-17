import "package:flutter_test/flutter_test.dart";
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

  testWidgets("connection status retains route state and blocks input", (
    tester,
  ) async {
    final lifecycle = _MutableLifecycle();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var initialized = 0;
    var disposed = 0;
    var activations = 0;
    await tester.pumpTestApp(
      child: RequiredNatsConnection(
        child: _RouteProbe(
          focus: focus,
          onInit: () => initialized++,
          onDispose: () => disposed++,
          onActivate: () => activations++,
        ),
      ),
      overrides: [
        accessTokenProvider.overrideWithValue(token),
        natsLifecycleProvider.overrideWith(() => lifecycle),
      ],
    );
    final control = find.text("Route control");
    final position = tester.getCenter(control);
    await tester.tap(control);
    expect(activations, 1);

    for (final status in [
      const NatsConnecting(),
      const NatsReconnecting(
        NatsClientException(
          kind: NatsFailureKind.unavailable,
          message: "Interrupted",
        ),
      ),
      const NatsFailed(
        NatsClientException(
          kind: NatsFailureKind.unavailable,
          message: "Interrupted",
        ),
      ),
      const NatsClosed(),
    ]) {
      focus.requestFocus();
      await tester.pump(const Duration(milliseconds: 1));
      expect(focus.hasFocus, isTrue);
      lifecycle.status = status;
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(control, findsNothing);
      expect(find.text("Route control", skipOffstage: false), findsOneWidget);
      expect(focus.hasFocus, isFalse);
      expect(focus.canRequestFocus, isFalse);
      await tester.tapAt(position);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, 1);
      expect(initialized, 1);
      expect(disposed, 0);

      lifecycle.status = const NatsConnected();
      await tester.pump(const Duration(milliseconds: 1));
      expect(control, findsOneWidget);
      expect(focus.canRequestFocus, isTrue);
    }
    await tester.tap(control);
    expect(activations, 2);
    expect(initialized, 1);
    await tester.pumpWidget(const SizedBox());
    expect(disposed, 1);
  });
}

class _MutableLifecycle extends NatsLifecycle {
  @override
  NatsConnectionState build() => const NatsConnected();

  NatsConnectionState get status => state;

  set status(NatsConnectionState status) => state = status;
}

class _RouteProbe extends StatefulWidget {
  const _RouteProbe({
    required this.focus,
    required this.onInit,
    required this.onDispose,
    required this.onActivate,
  });

  final FocusNode focus;
  final VoidCallback onInit;
  final VoidCallback onDispose;
  final VoidCallback onActivate;

  @override
  State<_RouteProbe> createState() => _RouteProbeState();
}

class _RouteProbeState extends State<_RouteProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Focus(
      focusNode: widget.focus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onActivate,
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Text("Route control"),
        ),
      ),
    ),
  );
}
