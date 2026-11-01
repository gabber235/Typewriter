/// The evidence folder a panel drive writes for `cargo xtask e2e`: the
/// captures first, then the `test_run.json` that lists them, so the run file
/// never lists a capture that is not on disk. A drive killed between the two
/// leaves captures without a run file, which xtask reads as a drive that never
/// reported.
library;

import "dart:convert";
import "dart:io";

import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

/// The folder `cargo xtask e2e` names in `EVIDENCE_DIR`, and the captures
/// written to it so far.
final class EvidenceFolder {
  EvidenceFolder(this.directory);

  final Directory directory;
  final Set<String> _written = {};

  /// Writes [bytes] as the capture at [path], relative to the folder.
  Future<void> write(String path, List<int> bytes) async {
    final file = File("${directory.path}/$path");
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    _written.add(path);
  }

  /// Writes [run] as `test_run.json`, keeping only the artifacts this folder
  /// wrote; call it after every capture the run lists.
  Future<void> writeRun(results.TestRun run) async {
    await directory.create(recursive: true);
    final written = run.toMutable()
      ..cases = [
        for (final testCase in run.cases)
          testCase.toMutable()
            ..attempts = [
              for (final attempt in testCase.attempts)
                attempt.toMutable()
                  ..artifacts = [
                    for (final artifact in attempt.artifacts)
                      if (_written.contains(artifact.path)) artifact,
                  ],
            ],
      ];
    await File("${directory.path}/test_run.json").writeAsString(
      jsonEncode(
        results.TestRun.serializer.toJson(
          written.toFrozen(),
          readableFlavor: true,
        ),
      ),
      flush: true,
    );
  }
}

/// Writes what the scenarios inside the app reported to the driver: every
/// capture in `captures` (path to base64 bytes), then the `TestRun` in
/// `testRun` listing only the captures that were written. A capture that could
/// not be written fails the drive after the run file is down.
Future<void> writeReportedEvidence(
  EvidenceFolder folder,
  Map<String, dynamic>? data,
) async {
  final captures = (data?["captures"] as Map?)?.cast<String, String>() ?? {};
  final failed = <String>[];
  for (final MapEntry(:key, :value) in captures.entries) {
    try {
      await folder.write(key, base64Decode(value));
    } on Object catch (error) {
      stderr.writeln("could not write the capture $key: $error");
      failed.add(key);
    }
  }
  final run = data?["testRun"];
  if (run != null) {
    await folder.writeRun(results.TestRun.serializer.fromJson(run));
  }
  if (failed.isNotEmpty) {
    throw StateError("captures not written: ${failed.join(", ")}");
  }
}
