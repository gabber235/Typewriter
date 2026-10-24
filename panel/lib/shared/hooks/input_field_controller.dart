import "package:typewriter_panel/typewriter_panel.dart";

/// Creates an [InputFieldController] and disposes its owned focus nodes.
///
/// If [inputFocusNode] is supplied, the controller uses it without taking
/// ownership, while it always owns the surrounding focus node. The controller
/// is recreated when the supplied focus node or [keys] change, and the prior
/// controller is disposed as part of that hook transition. Keep the returned
/// controller paired with the [InputFieldContainer] that consumes it.
InputFieldController useInputFieldController({
  FocusNode? inputFocusNode,
  String? inputDebugLabel,
  String? surroundingDebugLabel,
  List<Object?>? keys,
}) {
  return use(
    _InputFieldControllerHook(
      inputFocusNode: inputFocusNode,
      inputDebugLabel: inputDebugLabel,
      surroundingDebugLabel: surroundingDebugLabel,
      keys: [inputFocusNode, ...?keys],
    ),
  );
}

class _InputFieldControllerHook extends Hook<InputFieldController> {
  const _InputFieldControllerHook({
    this.inputFocusNode,
    this.inputDebugLabel,
    this.surroundingDebugLabel,
    super.keys,
  });

  final FocusNode? inputFocusNode;
  final String? inputDebugLabel;
  final String? surroundingDebugLabel;

  @override
  _InputFieldControllerHookState createState() =>
      _InputFieldControllerHookState();
}

class _InputFieldControllerHookState
    extends HookState<InputFieldController, _InputFieldControllerHook> {
  late final InputFieldController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = hook.inputFocusNode == null
        ? InputFieldController(
            inputDebugLabel: hook.inputDebugLabel,
            surroundingDebugLabel: hook.surroundingDebugLabel,
          )
        : InputFieldController.fromInputFocusNode(
            hook.inputFocusNode!,
            surroundingDebugLabel: hook.surroundingDebugLabel,
          );
  }

  @override
  InputFieldController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => "useInputFieldController";
}
