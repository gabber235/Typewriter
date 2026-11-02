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
    List<results.Step> steps = const [],
    List<results.Tap> taps = const [],
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
            steps: steps,
            taps: taps,
          ),
        ],
      ),
    );
  }

  /// Fails the passed case [id] for what went wrong after its body ended.
  void failLate(String id, String details) {
    final index = _cases.indexWhere((reported) => reported.id == id);
    if (index < 0) return;
    final reported = _cases[index];
    final attempt = reported.attempts.single;
    if (attempt.outcome != results.Outcome.passed) return;
    _cases[index] = results.TestCase(
      id: reported.id,
      requirement: reported.requirement,
      demonstrates: reported.demonstrates,
      attempts: [
        results.Attempt(
          outcome: failedWith(details, firstBroken: "after the scenario ended"),
          span: attempt.span,
          durationMillis: attempt.durationMillis,
          artifacts: attempt.artifacts,
          folder: attempt.folder,
          steps: attempt.steps,
          taps: attempt.taps,
        ),
      ],
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

/// The outcome of a case that failed with [error] during the step [firstBroken].
results.Outcome failedWith(Object error, {String? firstBroken}) =>
    results.Outcome.createFailed(
      message: error.toString(),
      firstBroken: firstBroken,
    );
