import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

import "../../integration_test/support/reported_run.dart";
import "../../test_driver/support/evidence.dart";

void main() {
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
      writeReportedEvidence(EvidenceFolder(directory), {
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
