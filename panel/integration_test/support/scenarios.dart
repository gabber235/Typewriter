/// The scenario runner: every scenario boots the real panel against the
/// worktree stack, acts through the [Panel] driver and reports what it proves.
///
/// Each [scenario] names the plan requirement it proves and what kind of
/// behavior it demonstrates. The runner hands the host driver
/// (`test_driver/integration_test.dart`) one `TestRun` with every scenario's
/// outcome and time span, plus the screenshots [Panel.capture] took, so
/// `cargo xtask e2e` can cut one clip per scenario from the recording.
library;

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;
import "package:typewriter_panel/typewriter_panel.dart";

import "panel.dart";
import "stack.dart" as stack;

export "package:flutter_test/flutter_test.dart" show expect, isNot;
export "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    show Demonstrates;

export "panel.dart";

/// The scenarios to run, as a JSON list of scenario or requirement ids; empty
/// runs every scenario. `cargo xtask e2e` sets it for `--only` and to run
/// failed scenarios again.
const _selection = String.fromEnvironment("SCENARIOS");

final _requirementFormat = RegExp(r"^[A-Z]+(-[A-Z]+)*-\d+(\.[EF]\d+)?$");

final IntegrationTestWidgetsFlutterBinding _binding =
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
final int _startedAt = DateTime.now().millisecondsSinceEpoch;
final List<results.TestCase> _cases = [];
final Map<String, String> _captures = {};

/// Registers every scenario group in [groups] and reports their results.
///
/// `flutter drive` accepts one target per run, so `integration_test/all_test.dart`
/// passes every group's `main` here.
void runScenarios(List<void Function()> groups) {
  _publish();
  for (final group in groups) {
    group();
  }
}

/// A user scenario proving [requirement], a plan requirement ID such as
/// `REALM-1` or its edge case `REALM-1.E1`, on a freshly launched panel.
///
/// The scenario's outcome, its span in Unix milliseconds and its captures land
/// in the `TestRun`; a failing scenario also captures the screen it failed on.
void scenario(
  String requirement,
  String title,
  results.Demonstrates demonstrates,
  Future<void> Function(Panel panel) body,
) {
  if (!_requirementFormat.hasMatch(requirement)) {
    throw ArgumentError.value(
      requirement,
      "requirement",
      "not a requirement ID such as REALM-1 or REALM-1.E1",
    );
  }
  final id = "[$requirement] $title";
  testWidgets(id, skip: !_selected(id, requirement), (tester) async {
    final artifacts = <results.Artifact>[];
    final panel = await Panel.launch(
      tester,
      onCapture: (name, png) {
        final path = "screenshots/$requirement/$name.png";
        _captures[path] = base64Encode(png);
        artifacts.add(
          results.Artifact(kind: results.ArtifactKind.screenshot, path: path),
        );
        _publish();
      },
    );
    final start = DateTime.now().millisecondsSinceEpoch;
    results.Outcome outcome = results.Outcome.passed;
    try {
      await body(panel);
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
      await panel.capture("failure");
      rethrow;
    } finally {
      // The scenario's spans reach the stack's collector while it still runs.
      await flushTelemetry();
      final end = DateTime.now().millisecondsSinceEpoch;
      _cases.add(
        results.TestCase(
          id: id,
          requirement: requirement,
          demonstrates: demonstrates,
          attempts: [
            results.Attempt(
              outcome: outcome,
              span: results.Span(startMillis: start, endMillis: end),
              durationMillis: end - start,
              artifacts: artifacts,
            ),
          ],
        ),
      );
      _publish();
    }
  });
}

/// A scenario that switches the stack's faults through [stack].
///
/// Only the worktree stack can switch faults. A stack without them, such as
/// the CI cluster, does not register the scenario at all, so the run never
/// reports a case that did nothing as passed. Faults are reset after the
/// scenario, so the next one starts from a healthy stack.
void faultScenario(
  String requirement,
  String title,
  results.Demonstrates demonstrates,
  Future<void> Function(Panel panel) body,
) {
  if (!stack.controllable) return;
  scenario(requirement, title, demonstrates, (panel) async {
    addTearDown(stack.resetFaults);
    await body(panel);
  });
}

/// A scenario is selected by its full id or by its requirement id.
bool _selected(String id, String requirement) {
  if (_selection.isEmpty) return true;
  final selection = jsonDecode(_selection) as List;
  return selection.contains(id) || selection.contains(requirement);
}

/// Hands the driver the results so far; it writes them once the run ends.
void _publish() {
  final run = results.TestRun(
    runner: kIsWeb ? results.Runner.panelWeb : results.Runner.panel,
    // `cargo xtask e2e` knows the commit; the device does not.
    commit: "",
    startedAtMillis: _startedAt,
    // One attempt of each scenario; `cargo xtask e2e` folds the attempts it
    // made into one run under its own policy.
    attemptPolicy: results.AttemptPolicy.wrapExactly(1),
    cases: _cases,
  );
  // The binding keeps its own screenshots under "screenshots" in the same map.
  (_binding.reportData ??= {})
    ..["testRun"] = results.TestRun.serializer.toJson(run, readableFlavor: true)
    ..["captures"] = _captures;
}
