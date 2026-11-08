import "package:typewriter_panel/typewriter_panel.dart";

part "hold_run.freezed.dart";

/// Refusals by target id. Empty means every target succeeded.
@freezed
abstract class HoldResult with _$HoldResult {
  const factory HoldResult({@Default({}) Map<Object, String> failures}) =
      _HoldResult;
}

/// Runs the work of a completed hold. [ref] answers the ref to run each step
/// with: the one that began the hold while it is mounted.
///
/// Work over every target runs once. Work per target runs in list order and
/// keeps going past a refusal; with rows, every target row is sending for
/// the whole run (one call), and the refused ones are refused on their
/// entries afterwards.
Future<HoldResult> runHold(HoldTry attempt, WidgetRef Function() ref) async {
  if (attempt.all case final all?) {
    await all(ref());
    return const HoldResult();
  }
  final each = attempt.each!;
  final failures = <Object, String>{};
  Future<void> eachTarget() async {
    for (final id in attempt.ids) {
      try {
        await each(ref(), id);
      } on UnconfirmedFailure {
        // Uncertain delivery belongs to the save status.
        continue;
      } on Object catch (error, stack) {
        failures[id] = holdFailureMessage(error, stack);
      }
    }
  }

  final rows = attempt.rows;
  if (rows == null) {
    await eachTarget();
  } else {
    // One send for every target row; the row's look comes from its entry.
    await rows.sending(attempt.ids, eachTarget);
    if (failures.isNotEmpty) rows.refuse(failures);
  }
  return HoldResult(failures: failures);
}

/// The sentence shown for a refusal: the service's own words when it gave
/// any, else a plain sentence. Anything else is logged with its stack, never
/// shown raw.
String holdFailureMessage(Object error, StackTrace stack) {
  if (error is ShownFailure) return error.message;
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: "Typewriter hold",
      context: ErrorDescription("running a held action"),
    ),
  );
  return "This did not go through. Try again.";
}
