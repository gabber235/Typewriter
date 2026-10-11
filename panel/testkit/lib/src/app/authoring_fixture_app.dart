import "package:typewriter_panel/typewriter_panel.dart";

import "authoring_workspace_fixture.dart";
import "fake_app.dart";
import "../shared/testing/testing.dart";

/// Retains a story's external fixture across ordinary rebuilds.
/// A scenario change creates new seed values and deliberately starts a new scope.
final class AuthoringFixtureApp extends StatefulWidget {
  const AuthoringFixtureApp({
    required this.createDocument,
    required this.child,
    this.scenario,
    this.state,
    this.overrides = const [],
    super.key,
  });
  final AuthoringDocument Function() createDocument;
  final Object? scenario;
  final DisplayState? state;
  final List<Override> overrides;
  final Widget child;
  @override
  State<AuthoringFixtureApp> createState() => _AuthoringFixtureAppState();
}

final class _AuthoringFixtureAppState extends State<AuthoringFixtureApp> {
  late ScriptedAuthoringTransport _transport;
  var _revision = 0;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    final document = widget.createDocument();
    _transport = ScriptedAuthoringTransport(switch (widget.state) {
      DisplayState.loading => const AsyncLoading(),
      DisplayState.error => AsyncError(
        StateError("Realm fixture unavailable"),
        StackTrace.current,
      ),
      _ => AsyncData(document),
    });
  }

  @override
  void didUpdateWidget(covariant AuthoringFixtureApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario ||
        oldWidget.state != widget.state) {
      _transport.dispose();
      _create();
      _revision++;
    }
  }

  @override
  void dispose() {
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FakeApp(
    key: ValueKey(_revision),
    overrides: [
      ...widget.overrides,
      ...authoringFixtureOverrides(transport: _transport),
    ],
    child: widget.child,
  );
}
