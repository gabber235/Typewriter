/// The end to end harness: scenarios boot the real panel against a stack, act
/// through its UI and report what they prove.
///
/// Each [scenario] names the plan requirement it proves and what kind of
/// behavior it demonstrates. The harness hands the host driver
/// (`test_driver/integration_test.dart`) one `TestRun` with every scenario's
/// outcome and time span, plus the screenshots [capture] took, so
/// `cargo xtask e2e` can cut one clip per scenario from the recording.
library;

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;
import "package:typewriter_panel/typewriter_panel.dart";

import "stack.dart" as stack;

export "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    show Demonstrates;

/// The scenario ids to run, as a JSON list; empty runs every scenario.
/// `cargo xtask e2e` sets it to rerun failed scenarios once.
const _selection = String.fromEnvironment("SCENARIOS");

final _requirementFormat = RegExp(r"^[A-Z]+(-[A-Z]+)*-\d+(\.[EF]\d+)?$");

final IntegrationTestWidgetsFlutterBinding _binding =
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
final int _startedAt = DateTime.now().millisecondsSinceEpoch;
final List<results.TestCase> _cases = [];
final Map<String, String> _captures = {};
List<results.Artifact> _artifacts = [];

/// Platform services initialize once per run, however many scenarios launch.
final Future<void> _platform = initializePanel();

/// Registers every scenario suite in [suites] and reports their results.
///
/// `flutter drive` accepts one target per run, so `integration_test/all_test.dart`
/// passes every suite's `main` here. A run with no suites still reports an
/// empty `TestRun`, which `cargo xtask e2e` shows as "no scenarios".
void runScenarios(List<void Function()> suites) {
  _publish();
  for (final suite in suites) {
    suite();
  }
  if (suites.isEmpty) {
    // The binding reports to the driver once the declared tests finished, and
    // a run without tests never finishes. This placeholder lets an empty run
    // end; it is not a scenario and stays out of the TestRun.
    testWidgets("no scenarios", (tester) async {});
  }
}

/// A user scenario proving [requirement], a plan requirement ID such as
/// `QUEST-1` or its edge case `QUEST-1.E1`.
///
/// The scenario's outcome and its span in Unix milliseconds land in the
/// `TestRun`. Faults a scenario switches on are reset afterwards, so the next
/// scenario starts from a healthy stack.
void scenario(
  String requirement,
  String title,
  results.Demonstrates demonstrates,
  Future<void> Function(WidgetTester tester) body,
) {
  if (!_requirementFormat.hasMatch(requirement)) {
    throw ArgumentError.value(
      requirement,
      "requirement",
      "not a requirement ID such as QUEST-1 or QUEST-1.E1",
    );
  }
  final id = "[$requirement] $title";
  testWidgets(id, skip: !_selected(id), (tester) async {
    if (stack.controllable) {
      addTearDown(stack.resetFaults);
    }
    _artifacts = [];
    final start = DateTime.now().millisecondsSinceEpoch;
    results.Outcome outcome = results.Outcome.passed;
    try {
      await body(tester);
      // An exception the framework caught during a frame fails the test only
      // after the body returns; surfacing it here records it as the failure.
      final pending = tester.takeException();
      if (pending != null) {
        Error.throwWithStackTrace(pending as Object, StackTrace.current);
      }
    } on Object catch (error) {
      outcome = results.Outcome.createFailed(
        message: error.toString(),
        firstBroken: null,
      );
      rethrow;
    } finally {
      final end = DateTime.now().millisecondsSinceEpoch;
      _cases.add(
        results.TestCase(
          id: id,
          requirement: requirement,
          demonstrates: demonstrates,
          outcome: outcome,
          span: results.Span(startMillis: start, endMillis: end),
          durationMillis: end - start,
          artifacts: _artifacts,
        ),
      );
      _publish();
    }
  });
}

/// Boots the real panel with an in memory OIDC store, so no keychain or
/// keyring is involved.
Future<ProviderContainer> launch(WidgetTester tester) async {
  await _platform;
  final container = ProviderContainer(
    retry: panelRetry,
    overrides: [
      ...appOverrides(),
      oidcStoreProvider.overrideWithValue(OidcMemoryStore()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TypewriterPanel(),
    ),
  );
  return container;
}

/// Signs in the fixture user [username] through the real OIDC client with the
/// password grant, which the stack's identity stand in accepts.
Future<void> signIn(
  WidgetTester tester,
  ProviderContainer container,
  String username,
) async {
  final user = stack.user(username);
  final manager = await container.read(authProvider.future);
  if (manager == null) {
    throw StateError("the panel has no OIDC client");
  }
  await manager.loginPassword(username: user.username, password: user.password);
  container.invalidate(authProvider);
  await tester.pumpAndSettle();
}

/// Captures the whole panel as `screenshots/<name>.png` in the evidence folder
/// and attaches it to the running scenario.
Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(TypewriterPanel.screenshotKey),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      return await image.toByteData(format: ImageByteFormat.png);
    } finally {
      image.dispose();
    }
  });
  if (bytes == null) {
    throw StateError("the panel could not be encoded as PNG");
  }
  final path = "screenshots/$name.png";
  _captures[path] = base64Encode(bytes.buffer.asUint8List());
  _artifacts.add(
    results.Artifact(kind: results.ArtifactKind.screenshot, path: path),
  );
  _publish();
}

bool _selected(String id) =>
    _selection.isEmpty || (jsonDecode(_selection) as List).contains(id);

/// Hands the driver the results so far; it writes them once the run ends.
void _publish() {
  final run = results.TestRun(
    runner: kIsWeb ? results.Runner.panelWeb : results.Runner.panel,
    // `cargo xtask e2e` knows the commit; the device does not.
    commit: "",
    startedAtMillis: _startedAt,
    cases: _cases,
  );
  // The binding keeps its own screenshots under "screenshots" in the same map.
  (_binding.reportData ??= {})
    ..["testRun"] = results.TestRun.serializer.toJson(run, readableFlavor: true)
    ..["captures"] = _captures;
}
