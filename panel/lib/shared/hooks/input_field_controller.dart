import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Creates and disposes an [InputFieldController].
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
