import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

import "../../integration_test/support/reported_run.dart";
import "../../test_driver/support/evidence.dart";

void main() {
  test("a run keeps a case that never reported as failed", () {
    final run = ReportedRun(results.Runner.panelWeb);
    for (final title in ["finishes", "never reports"]) {
      run.expectCase(
        requirement: "CONN-1",
        title: title,
        demonstrates: results.Demonstrates.happyPath,
      );
    }
    run.add(
      requirement: "CONN-1",
      title: "finishes",
      demonstrates: results.Demonstrates.happyPath,
      outcome: results.Outcome.passed,
      start: 0,
      end: 1,
      artifacts: const [],
    );

    final outcomes = {
      for (final reported in run.testRun.cases)
        reported.id: reported.attempts.single.outcome,
    };

    expect(outcomes.keys, ["[CONN-1] finishes", "[CONN-1] never reports"]);
    expect(outcomes["[CONN-1] finishes"], results.Outcome.passed);
    expect(outcomes["[CONN-1] never reports"], isNot(results.Outcome.passed));
  });

  test("a reported error replaces the wait for a case that never finished", () {
    final run = ReportedRun(results.Runner.panelWeb)
      ..expectCase(
        requirement: "CONN-1",
        title: "stops",
        demonstrates: results.Demonstrates.happyPath,
      )
      ..failLate("[CONN-1] stops", "the real cause");

    final outcome = run.testRun.cases.single.attempts.single.outcome;

    expect(outcome, isA<results.Outcome_failedWrapper>());
    expect(
      (outcome as results.Outcome_failedWrapper).value.message,
      "the real cause",
    );
  });

  test("a run file lists only the captures written to disk", () async {
    final directory = Directory.systemTemp.createTempSync("drive_evidence");
    addTearDown(() => directory.deleteSync(recursive: true));
    const written = "screenshots/CONN-1/connected.png";
    const unwritable = "screenshots/CONN-1/failure.png";
    // A folder where the capture belongs makes its write fail.
    Directory("${directory.path}/$unwritable").createSync(recursive: true);
    final run = ReportedRun(results.Runner.panelWeb)
      ..add(
        requirement: "CONN-1",
        title: "connects",
        demonstrates: results.Demonstrates.happyPath,
        outcome: results.Outcome.passed,
        start: 0,
        end: 1,
        artifacts: [
          for (final path in [written, unwritable])
            results.Artifact(kind: results.ArtifactKind.screenshot, path: path),
        ],
      );

    await expectLater(
      EvidenceFolder(directory).writeReported({
        "testRun": run.toJson(),
        "captures": {
          written: base64Encode([1, 2, 3]),
          unwritable: base64Encode([4, 5, 6]),
        },
      }),
      throwsStateError,
    );

    final listed = results.TestRun.serializer
        .fromJson(
          jsonDecode(
            File("${directory.path}/test_run.json").readAsStringSync(),
          ),
        )
        .cases
        .expand((testCase) => testCase.attempts)
        .expand((attempt) => attempt.artifacts)
        .map((artifact) => artifact.path);
    expect(listed, [written]);
    expect(File("${directory.path}/$written").readAsBytesSync(), [1, 2, 3]);
  });
}
