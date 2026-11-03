/// The scenario runner: every scenario boots the real panel against the
/// target's backend (the worktree stack or the CI cluster), acts through the
/// [Panel] driver and reports what it proves.
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
import "reported_run.dart";
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
final ReportedRun _run = ReportedRun(
  kIsWeb ? results.Runner.panelWeb : results.Runner.panel,
);
final Map<String, String> _captures = {};

/// What first failed each test. The binding keeps only the last report, and one
/// error can set off many.
final Map<String, FlutterErrorDetails> _firstFailures = {};

/// Registers every scenario group in [groups] and reports their results.
///
/// `flutter drive` accepts one target per run, so `integration_test/all_test.dart`
/// passes every group's `main` here.
void runScenarios(List<void Function()> groups) {
  _publish();
  final report = reportTestException;
  reportTestException = (details, id) {
    _firstFailures.putIfAbsent(id, () => details);
    // An error after a scenario's body fails that scenario in the binding
    // alone. Recorded now, it stays a result of the scenario.
    _run.failLate(id, _firstFailures[id]!.exceptionAsString());
    _publish();
    report(details, id);
  };
  for (final group in groups) {
    group();
  }
}

/// A user scenario proving [requirement], a plan requirement ID such as
/// `REALM-1` or its edge case `REALM-1.E1`, on a freshly launched panel.
///
/// The scenario's outcome, its span in Unix milliseconds and its captures land
/// in the `TestRun`; a failing scenario also captures the screen it failed on
/// and keeps the panel's log, which `cargo xtask e2e` copies into the
/// attempt's failure folder.
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
  final id = ReportedRun.id(requirement, title);
  final skip = !_selected(id, requirement);
  if (!skip) {
    _run.expectCase(
      requirement: requirement,
      title: title,
      demonstrates: demonstrates,
    );
  }
  testWidgets(id, skip: skip, (tester) async {
    final artifacts = <results.Artifact>[];
    // The panel logs through debugPrint; a failure keeps what it printed.
    final log = StringBuffer();
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      log.writeln("${_now()} $message");
      original(message, wrapWidth: wrapWidth);
    };
    // The binding reports several caught errors as one "Multiple exceptions"
    // message; each is logged here, so the failure shows what was thrown.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      log.writeln("${_now()} ${details.exceptionAsString()}\n${details.stack}");
      reportError?.call(details);
    };
    final Panel panel;
    try {
      panel = await Panel.launch(
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
    } on Object catch (error) {
      debugPrint = original;
      FlutterError.onError = reportError;
      final now = DateTime.now().millisecondsSinceEpoch;
      _run.add(
        requirement: requirement,
        title: title,
        demonstrates: demonstrates,
        outcome: failedWith(error, firstBroken: "launching the panel"),
        start: now,
        end: now,
        artifacts: artifacts,
      );
      _publish();
      rethrow;
    }
    final start = DateTime.now().millisecondsSinceEpoch;
    results.Outcome outcome = results.Outcome.passed;
    int? bodyEnded;
    try {
      await body(panel);
      await panel.holdResult();
      // The recording ends on what the body proved, not on the panel closing.
      bodyEnded = DateTime.now().millisecondsSinceEpoch;
      await panel.close();
      // An exception the framework caught during a frame fails the test only
      // after the body returns; surfacing it here records it as the failure.
      final pending = tester.takeException();
      if (pending != null) {
        Error.throwWithStackTrace(pending as Object, StackTrace.current);
      }
    } on Object catch (error, stackTrace) {
      // The body's own error reports only after this rethrow, so a failure
      // already reported came first and ended the test under the body. What
      // the body then hit is a consequence.
      final cause = _firstFailures[id];
      outcome = failedWith(
        cause?.exceptionAsString() ?? error,
        firstBroken: panel.steps.lastOrNull?.says,
      );
      if (cause != null) log.writeln("${_now()} $cause");
      log.writeln("${_now()} $error\n$stackTrace");
      // A framework error the failure left pending is logged too. A reported
      // failure ended the test, and the binding only answers during one.
      if (cause == null) {
        final pending = tester.takeException();
        if (pending != null) log.writeln("${_now()} $pending");
      }
      try {
        await panel.capture("failure");
      } on Object catch (captureError) {
        log.writeln("${_now()} no failure screenshot: $captureError");
      }
      final path = "logs/$requirement/panel.log";
      _captures[path] = base64Encode(utf8.encode(log.toString()));
      artifacts.add(
        results.Artifact(kind: results.ArtifactKind.logExcerpt, path: path),
      );
      rethrow;
    } finally {
      // Restored before the test ends, since the binding checks they were.
      debugPrint = original;
      FlutterError.onError = reportError;
      final end = bodyEnded ?? DateTime.now().millisecondsSinceEpoch;
      // An error can end the test while its body runs on and returns normally.
      final failure = _firstFailures[id];
      if (failure != null && outcome == results.Outcome.passed) {
        outcome = failedWith(
          failure.exceptionAsString(),
          firstBroken: panel.steps.lastOrNull?.says,
        );
      }
      _run.add(
        requirement: requirement,
        title: title,
        demonstrates: demonstrates,
        outcome: outcome,
        start: start,
        end: end,
        artifacts: artifacts,
        steps: panel.steps,
        taps: panel.taps,
      );
      _publish();
      // The scenario's spans reach the stack's collector while it still runs;
      // the case is recorded first, so a failed export cannot drop it.
      await flushTelemetry();
    }
  });
}

/// A scenario that switches the stack's faults through [stack]. Faults are
/// reset after the scenario, so the next one starts from a healthy stack.
void faultScenario(
  String requirement,
  String title,
  results.Demonstrates demonstrates,
  Future<void> Function(Panel panel) body,
) {
  scenario(requirement, title, demonstrates, (panel) async {
    addTearDown(stack.resetFaults);
    await body(panel);
  });
}

/// The time a panel log line starts with, the RFC 3339 UTC form failure
/// folders cut logs by.
String _now() => DateTime.now().toUtc().toIso8601String();

/// A scenario is selected by its full id or by its requirement id.
bool _selected(String id, String requirement) {
  if (_selection.isEmpty) return true;
  final selection = jsonDecode(_selection) as List;
  return selection.contains(id) || selection.contains(requirement);
}

/// Hands the driver the results so far; it writes them once the run ends.
void _publish() {
  // The binding keeps its own screenshots under "screenshots" in the same map.
  (_binding.reportData ??= {})
    ..["testRun"] = _run.toJson()
    ..["captures"] = _captures;
}
