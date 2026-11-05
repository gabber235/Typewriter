/// Authentik's sign in and end session pages, as a host driver works them in
/// the browser the panel runs in.
library;

import "package:flutter_driver/flutter_driver.dart";

import "../../integration_test/support/wait.dart";

/// How long a journey step waits: longer than a scenario's [patience],
/// because Authentik's pages load in full and the panel reloads after each
/// redirect back.
const redirectPatience = Duration(seconds: 60);

/// The WebDriver key code of Enter.
const _enter = "";

/// Authentik's pages in the browser [driver] runs the panel in.
final class AuthentikPages {
  AuthentikPages(this._driver);

  final WebFlutterDriver _driver;

  /// Types [username] into the identification stage and submits it.
  Future<void> enterUser(String username) =>
      _submit("input[name=uidField]", username);

  /// Types [password] into the password stage and submits it.
  Future<void> enterPassword(String password) =>
      _submit("input[name=password]", password);

  /// Whether Authentik asks who is signing in, instead of signing a
  /// remembered user straight back in.
  Future<bool> asksForUser() => _focus("input[name=uidField]");

  /// Runs [signOut] and waits until the end session Authentik opens in a
  /// window of its own has opened and, once Authentik redirected back,
  /// closed again. The watch starts first, so a window that opens and closes
  /// while [signOut] runs still counts.
  Future<void> endsSessionDuring(Future<void> Function() signOut) async {
    Future<int> windows() async =>
        (await _driver.webDriver.windows.toList()).length;
    final before = await windows();
    await Future.wait([
      until(
        "Authentik's end session window opens",
        () async => await windows() > before,
        within: redirectPatience,
      ),
      signOut(),
    ]);
    await until(
      "Authentik's end session completes",
      () async => await windows() == before,
      within: redirectPatience,
    );
  }

  Future<void> _submit(String selector, String text) async {
    await until(
      "Authentik shows $selector",
      () => _focus(selector),
      within: redirectPatience,
    );
    await _driver.webDriver.keyboard.sendKeys("$text$_enter");
  }

  /// Focuses the field matching [selector] and tells whether it is on the
  /// page. Authentik renders its flow stages in shadow roots below
  /// `ak-flow-executor`, which a CSS query does not cross, so the search walks
  /// them; starting below the executor skips the hidden fields Authentik adds
  /// to the document for password managers.
  Future<bool> _focus(String selector) async {
    final focused = await _driver.webDriver.execute(
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
}
