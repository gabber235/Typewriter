/// The `TestRun` a panel runner hands `cargo xtask e2e`: one attempt per case,
/// which xtask folds into one run under its own attempt policy.
///
/// Both runners build it here: the scenario runner inside the app
/// (`scenarios.dart`) and the host driven journeys outside it
/// (`test_driver/support/journey.dart`). It imports only the generated
/// harness types, so it compiles on the device and on the host.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

/// The cases one runner reported so far.
final class ReportedRun {
  ReportedRun(this.runner);

  final results.Runner runner;
  final int _startedAt = DateTime.now().millisecondsSinceEpoch;
  final List<results.TestCase> _cases = [];

  /// The case id of [title] proving [requirement], as xtask selects it.
  static String id(String requirement, String title) => "[$requirement] $title";

  /// Records the one attempt of the case [title] proving [requirement], which
  /// ran from [start] to [end] (Unix milliseconds) and ended in [outcome].
  void add({
    required String requirement,
    required String title,
    required results.Demonstrates demonstrates,
    required results.Outcome outcome,
    required int start,
    required int end,
    required List<results.Artifact> artifacts,
  }) {
    _cases.add(
      results.TestCase(
        id: id(requirement, title),
        requirement: requirement,
        demonstrates: demonstrates,
        attempts: [
          results.Attempt(
            outcome: outcome,
            span: results.Span(startMillis: start, endMillis: end),
            durationMillis: end - start,
            artifacts: artifacts,
            // `cargo xtask e2e` sets the drive's folder when it reads the run.
            folder: "",
          ),
        ],
      ),
    );
  }

  /// The cases so far as one run.
  results.TestRun get testRun => results.TestRun(
    runner: runner,
    // `cargo xtask e2e` knows the commit; the runner does not.
    commit: "",
    startedAtMillis: _startedAt,
    attemptPolicy: results.AttemptPolicy.wrapExactly(1),
    cases: _cases,
  );

  /// The run as JSON, the form the app reports it to the host driver in.
  Object? toJson() =>
      results.TestRun.serializer.toJson(testRun, readableFlavor: true);
}

/// The outcome of a case that failed with [error].
results.Outcome failedWith(Object error) =>
    results.Outcome.createFailed(message: error.toString(), firstBroken: null);
