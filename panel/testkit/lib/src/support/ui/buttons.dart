import "package:typewriter_panel/typewriter_panel.dart";

/// A filled Save button, the plain button the motion tests press.
Widget saveButton({FutureOr<void> Function()? onPressed}) => Button(
  face: ButtonFace.filled,
  label: "Save",
  onPressed: onPressed ?? () {},
);

/// A button with an Add icon and a busy word, in [face].
Widget busyButton(
  ButtonFace face, {
  required FutureOr<void> Function()? onPressed,
  String label = "Go",
  String busyLabel = "Going",
  ButtonController? controller,
}) => Button(
  face: face,
  icon: const Icon(Icons.add, semanticLabel: "Add"),
  label: label,
  busyLabel: busyLabel,
  onPressed: onPressed,
  controller: controller,
);

/// A run state owned by the test, as CommandRuns owns a command's: bound to
/// [run] with no error report. A Button given it only reads it.
ButtonController ownedRun(FutureOr<void> Function()? run) =>
    ButtonController()..bind(onPressed: run, onError: null);

/// An async action that records step 1 when it starts and step 2 when the
/// test lets it finish through [finish].
final class SteppedAction {
  final steps = <int>[];
  final _gate = Completer<void>();

  Future<void> run() async {
    steps.add(1);
    await _gate.future;
    steps.add(2);
  }

  void finish() => _gate.complete();
}
