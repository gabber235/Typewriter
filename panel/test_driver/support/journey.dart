/// The runner of host driven journeys: what a scenario inside the app cannot
/// reach, such as the identity provider's own pages, which the web sign in
/// leaves the app's page for.
///
/// Flutter Driver works the panel (`test_driver/sign_in_journey.dart`) and the
/// same browser's WebDriver session works the provider's pages. A journey
/// writes its one case, like a scenario's, to the evidence folder.
library;

import "dart:io";

import "package:flutter_driver/flutter_driver.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

import "../../integration_test/support/reported_run.dart";
import "../../integration_test/support/wait.dart";
import "authentik.dart";
import "evidence.dart";

export "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    show Demonstrates;

export "../../integration_test/support/wait.dart" show until;
export "authentik.dart" show redirectPatience;

/// Runs the journey [title] proving [requirement] and writes its case to the
/// folder `cargo xtask e2e` names in `EVIDENCE_DIR`. A failed journey still
/// writes its case, then exits non zero.
Future<void> journey(
  String requirement,
  String title,
  results.Demonstrates demonstrates,
  Future<void> Function(Journey journey) body,
) async {
  final evidence = EvidenceFolder(
    Directory(Platform.environment["EVIDENCE_DIR"]!),
  );
  final driver = await FlutterDriver.connect() as WebFlutterDriver;
  final run = ReportedRun(results.Runner.panelWeb);
  final user = Journey._(driver, evidence, requirement);
  final start = DateTime.now().millisecondsSinceEpoch;
  results.Outcome outcome = results.Outcome.passed;
  try {
    await body(user);
  } on Object catch (error, stackTrace) {
    stderr.writeln("$error\n$stackTrace");
    outcome = failedWith(error);
    await user.capture("failure");
    exitCode = 1;
  } finally {
    run.add(
      requirement: requirement,
      title: title,
      demonstrates: demonstrates,
      outcome: outcome,
      start: start,
      end: DateTime.now().millisecondsSinceEpoch,
      artifacts: user._artifacts,
    );
    // Every capture is on disk by now, so the run lists only written ones.
    await evidence.writeRun(run.testRun);
    await driver.close();
  }
}

/// The user a journey acts as: the provider credentials `cargo xtask e2e`
/// hands it, the panel and the provider's pages.
final class Journey {
  Journey._(this._driver, this._evidence, this._requirement)
    : provider = AuthentikPages(_driver);

  final WebFlutterDriver _driver;
  final EvidenceFolder _evidence;
  final String _requirement;
  final List<results.Artifact> _artifacts = [];

  /// The user's name and password on the provider's sign in form.
  final String username = Platform.environment["STACK_SIGN_IN_USERNAME"]!;
  final String password = Platform.environment["STACK_SIGN_IN_PASSWORD"]!;

  /// The identity provider's pages.
  final AuthentikPages provider;

  /// Waits until the panel runs in the current page and answers Flutter
  /// Driver, as it does again after every redirect back from the provider.
  Future<void> panelReady() async {
    await until("the panel answers Flutter Driver", () async {
      final type = await _driver.webDriver.execute(
        r"return typeof window.$flutterDriver;",
        [],
      );
      return type == "function";
    }, within: redirectPatience);
    await _driver.waitUntilFirstFrameRasterized();
  }

  /// Activates the panel control that reads [text].
  Future<void> tap(String text) =>
      _driver.tap(find.text(text), timeout: redirectPatience);

  /// Waits until the panel shows [text].
  Future<void> expectVisible(String text) =>
      _driver.waitFor(find.text(text), timeout: redirectPatience);

  /// Opens the panel again in the same browser, the way a user comes back,
  /// and waits until it runs.
  Future<void> revisit(Uri panel) async {
    await _driver.webDriver.get(panel);
    await panelReady();
  }

  /// Where the browser is now.
  Future<Uri> get location async =>
      Uri.parse(await _driver.webDriver.currentUrl);

  /// Saves what the browser shows as the screenshot [name] of the case.
  Future<void> capture(String name) async {
    final path = "screenshots/$_requirement/$name.png";
    await _evidence.write(
      path,
      await _driver.webDriver.captureScreenshotAsList(),
    );
    _artifacts.add(
      results.Artifact(kind: results.ArtifactKind.screenshot, path: path),
    );
  }
}
