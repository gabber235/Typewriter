/// The one way a host driver waits.
library;

/// How long a host step waits for the page it needs; the identity provider's
/// pages and the panel's reload after each redirect take real time.
const patience = Duration(seconds: 60);

/// Polls [holds] until it is true, failing with [what] after [patience].
///
/// A check that throws has not held yet, since the page may be between
/// redirects; the last such error is named when the wait fails.
Future<void> until(String what, Future<bool> Function() holds) async {
  final deadline = DateTime.now().add(patience);
  Object? last;
  while (true) {
    try {
      if (await holds()) return;
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
