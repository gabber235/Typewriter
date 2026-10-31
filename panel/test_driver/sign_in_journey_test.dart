import "dart:convert";
import "dart:io";

import "package:flutter_driver/flutter_driver.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/harness/v1/test_run.dart"
    as results;

/// The host side of the sign in journey against a real identity provider.
///
/// Scenarios sign in with the password grant inside the page, because the web
/// sign in leaves the page a scenario runs in. This driver stands outside it:
/// Flutter Driver works the panel (`test_driver/sign_in_journey.dart`) and the
/// same browser's WebDriver session works the provider's pages. It proves the
/// user signs in through the provider's form, sees the signed in shell, signs
/// out through the provider's end session, and is asked for the password
/// again on the next visit.
///
/// `cargo xtask e2e full` runs it and sets `EVIDENCE_DIR` and the user's
/// provider credentials, `STACK_SIGN_IN_USERNAME` and `STACK_SIGN_IN_PASSWORD`.
/// It writes one `TestRun` case to the evidence folder.
Future<void> main() async {
  final evidence = Directory(Platform.environment["EVIDENCE_DIR"]!);
  final username = Platform.environment["STACK_SIGN_IN_USERNAME"]!;
  final password = Platform.environment["STACK_SIGN_IN_PASSWORD"]!;
  final driver = await FlutterDriver.connect() as WebFlutterDriver;
  final artifacts = <results.Artifact>[];
  final start = DateTime.now().millisecondsSinceEpoch;
  results.Outcome outcome = results.Outcome.passed;
  try {
    await _journey(driver, username, password, (name) async {
      final path = "screenshots/$_requirement/$name.png";
      final file = File("${evidence.path}/$path");
      await file.parent.create(recursive: true);
      await file.writeAsBytes(await driver.webDriver.captureScreenshotAsList());
      artifacts.add(
        results.Artifact(kind: results.ArtifactKind.screenshot, path: path),
      );
    });
  } on Object catch (error, stackTrace) {
    stderr.writeln("$error\n$stackTrace");
    outcome = results.Outcome.createFailed(
      message: error.toString(),
      firstBroken: null,
    );
    exitCode = 1;
  } finally {
    final end = DateTime.now().millisecondsSinceEpoch;
    final run = results.TestRun(
      runner: results.Runner.panelWeb,
      commit: "",
      startedAtMillis: start,
      attemptPolicy: results.AttemptPolicy.wrapExactly(1),
      cases: [
        results.TestCase(
          id: "[$_requirement] $_title",
          requirement: _requirement,
          demonstrates: results.Demonstrates.happyPath,
          attempts: [
            results.Attempt(
              outcome: outcome,
              span: results.Span(startMillis: start, endMillis: end),
              durationMillis: end - start,
              artifacts: artifacts,
            ),
          ],
        ),
      ],
    );
    await evidence.create(recursive: true);
    await File("${evidence.path}/test_run.json").writeAsString(
      jsonEncode(
        results.TestRun.serializer.toJson(run, readableFlavor: true),
      ),
    );
    await driver.close();
  }
}

const _requirement = "AUTH-2";
const _title =
    "a user signs in through the identity provider's form, signs out through "
    "its end session, and is asked to sign in again on the next visit";

/// How long a step waits for the page it needs; the provider's pages and the
/// panel's reload after each redirect take real time.
const _patience = Duration(seconds: 60);

Future<void> _journey(
  WebFlutterDriver driver,
  String username,
  String password,
  Future<void> Function(String name) capture,
) async {
  final browser = driver.webDriver;
  final panel = await browser.currentUrl;
  await _panelReady(driver);

  await driver.tap(find.text("Sign in"), timeout: _patience);
  await _type(driver, "input[name=uidField]", username);
  await capture("provider-sign-in");
  await _type(driver, "input[name=password]", password);
  await _panelReady(driver);
  await driver.waitFor(find.text(username), timeout: _patience);
  await capture("signed-in");

  final windows = (await browser.windows.toList()).length;
  await driver.tap(find.text(username), timeout: _patience);
  await driver.tap(find.text("Logout"), timeout: _patience);
  await driver.waitFor(find.text("Sign in"), timeout: _patience);
  // The panel ends the provider's session in a window of its own, which
  // closes once the provider has redirected back.
  await _until("the provider's end session window opens", () async {
    return (await browser.windows.toList()).length > windows;
  });
  await _until("the provider's end session completes", () async {
    return (await browser.windows.toList()).length == windows;
  });
  await capture("signed-out");

  await browser.get(panel);
  await _panelReady(driver);
  await driver.tap(find.text("Sign in"), timeout: _patience);
  await _until(
    "the provider asks for the user again instead of signing them in",
    () async => await _focus(driver, "input[name=uidField]"),
  );
  await capture("asked-again");
}

/// Waits until the panel runs in the current page and answers Flutter Driver,
/// as it does again after every redirect back from the provider.
Future<void> _panelReady(WebFlutterDriver driver) async {
  await _until("the panel answers Flutter Driver", () async {
    final type = await driver.webDriver.execute(
      r"return typeof window.$flutterDriver;",
      [],
    );
    return type == "function";
  });
  await driver.waitUntilFirstFrameRasterized();
}

/// Types [text] into the provider's field matching [selector], then Enter,
/// the way a user fills in and submits the form.
Future<void> _type(
  WebFlutterDriver driver,
  String selector,
  String text,
) async {
  await _until(
    "the provider shows $selector",
    () => _focus(driver, selector),
  );
  await driver.webDriver.keyboard.sendKeys("$text");
}

/// Focuses the provider's field matching [selector] and tells whether it is
/// on the page. Authentik renders its flow stages in shadow roots below
/// `ak-flow-executor`, which a CSS query does not cross, so the search walks
/// them; starting below the executor skips the hidden fields Authentik adds to
/// the document for password managers.
Future<bool> _focus(WebFlutterDriver driver, String selector) async {
  final focused = await driver.webDriver.execute(
    """
const selector = arguments[0];
const deep = (root) => {
  const hit = root.querySelector(selector);
  if (hit) return hit;
  for (const element of root.querySelectorAll("*")) {
    const inner = element.shadowRoot && deep(element.shadowRoot);
    if (inner) return inner;
  }
  return null;
};
const executor = document.querySelector("ak-flow-executor");
const field = executor && executor.shadowRoot && deep(executor.shadowRoot);
if (!field) return false;
field.focus();
return true;
""",
    [selector],
  );
  return focused == true;
}

/// Polls [done] until it holds, failing with [what] after [_patience]. A
/// check that throws has not held yet: the page may be between redirects.
Future<void> _until(String what, Future<bool> Function() done) async {
  final deadline = DateTime.now().add(_patience);
  Object? last;
  while (true) {
    try {
      if (await done()) return;
    } on Exception catch (error) {
      last = error;
    }
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        "timed out waiting until $what${last == null ? "" : " ($last)"}",
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
