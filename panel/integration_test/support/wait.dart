/// The one way scenarios and host driven journeys wait for the real stack.
///
/// It imports nothing but the Dart core libraries, so the scenario runner
/// on the device and the journey drivers on the host share it.
library;

import "dart:async";

/// How long a step waits for what it needs; replies cross the real broker,
/// backend and Realm host. A caller passes a longer patience only with the
/// reason it needs one.
const patience = Duration(seconds: 30);

/// How long a wait lets the app run between two looks.
const _frame = Duration(milliseconds: 100);

/// Waits until [holds] is true, failing after [within] with a message that
/// names [what] it waited for and, when given, what [shows] reports then,
/// such as the screen's labels.
///
/// [between] runs between two looks; it defaults to [_frame] of real time,
/// and a widget driver passes a frame pump. A look that throws an
/// [Exception] has not held yet, since a page may be between redirects; the
/// last such exception is named when the wait fails.
Future<void> until(
  String what,
  FutureOr<bool> Function() holds, {
  Duration within = patience,
  Future<void> Function()? between,
  Object? Function()? shows,
}) async {
  final deadline = DateTime.now().add(within);
  Object? last;
  while (true) {
    try {
      if (await holds()) return;
    } on Exception catch (error) {
      last = error;
    }
    if (DateTime.now().isAfter(deadline)) {
      final seen = shows == null ? "" : "; ${shows()}";
      final error = last == null ? "" : "; the last look failed with $last";
      throw TimeoutException(
        "Waited ${within.inSeconds}s until $what$seen$error",
      );
    }
    await (between ?? () => Future<void>.delayed(_frame))();
  }
}
