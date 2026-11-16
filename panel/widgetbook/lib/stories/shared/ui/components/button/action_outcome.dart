import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";

/// How the action behind a busy button ends when the story's user presses it.
enum ActionOutcome {
  succeeds("Succeeds"),
  fails("Fails"),
  neverAnswers("Never answers");

  const ActionOutcome(this.label);

  final String label;

  /// The action: it takes a moment, then ends the way this outcome says.
  Future<void> run() async {
    if (this == neverAnswers) return Completer<void>().future;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (this == fails) {
      throw StateError("The server refused the request");
    }
  }
}

/// Knobs of stories whose buttons run an action.
extension ActionOutcomeKnobs on KnobsBuilder {
  /// How the pressed action ends.
  ActionOutcome actionOutcome() => object.segmented(
    label: "Outcome",
    options: ActionOutcome.values,
    labelBuilder: (outcome) => outcome.label,
    initialOption: ActionOutcome.succeeds,
  );
}
