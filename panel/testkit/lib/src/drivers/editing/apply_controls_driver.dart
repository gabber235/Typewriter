import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The actions an editing owner offers for its pending work: Apply, Discard,
/// Retry and Refresh, found as buttons by their labels.
final class ApplyControlsDriver extends ComponentDriver {
  ApplyControlsDriver(super.tester);

  static const _labels = {
    "Apply",
    "Discard",
    "Discard later edits",
    "Retry",
    "Refresh",
  };

  List<SemanticsNode> get _buttons => find.semantics
      .byPredicate((node) => node.isButton && _labels.contains(node.spoken))
      .evaluate()
      .toList();

  /// The editing actions on screen, in reading order.
  List<String> get actions => [for (final button in _buttons) button.spoken];

  SemanticsNode _action(String label) =>
      _buttons.firstWhereOrNull((button) => button.spoken == label) ??
      (throw TestFailure("No editing action $label; there are $actions"));

  /// Whether the action [label] can be pressed.
  bool isEnabled(String label) => _action(label).isEnabled;

  /// Presses the action [label].
  Future<void> press(String label) async {
    await tester.tapAt(_action(label).screenRect.center);
    await settle();
  }
}

/// The editing actions of the panel.
extension ApplyControlsOnPanel on PanelDriver {
  /// The actions the panel offers for pending edits.
  ApplyControlsDriver get applyControls => ApplyControlsDriver(tester);

  /// The inspected editor whose drafts wait for Apply, such as a host's
  /// configuration; fails unless exactly one does.
  ValueEditing get appliedEditor => container
      .read(inspectionSessionProvider)
      .owners
      .labels
      .keys
      .whereType<ValueEditing>()
      .singleWhere(
        (owner) => owner.commitPolicy == EditorCommitPolicy.applyResource,
      );

  /// Applies [owner]'s draft, as Apply does, and lets the panel run until
  /// its outcome arrives.
  Future<TypedMutationResult> apply(ValueEditing owner) async {
    TypedMutationResult? outcome;
    unawaited(owner.flush().then((result) => outcome = result));
    await eventually(
      () => expect(outcome, isNotNull, reason: "The draft was never applied"),
    );
    await settle();
    return outcome!;
  }
}
