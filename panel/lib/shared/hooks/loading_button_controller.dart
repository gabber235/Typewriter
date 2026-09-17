import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/ui/components/loading_button/loading_button.dart";

/// Creates a [LoadingButtonController] owned by the current widget.
///
/// The controller is stable across rebuilds and disposed when the hook is
/// removed. Its action rejects overlapping triggers while an earlier action is
/// loading; use the controller's state to render progress and errors.
LoadingButtonController useLoadingButtonController() {
  return use(_LoadingButtonControllerHook());
}

class _LoadingButtonControllerHook extends Hook<LoadingButtonController> {
  @override
  _LoadingButtonControllerHookState createState() =>
      _LoadingButtonControllerHookState();
}

class _LoadingButtonControllerHookState
    extends HookState<LoadingButtonController, _LoadingButtonControllerHook> {
  late final LoadingButtonController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = LoadingButtonController();
  }

  @override
  LoadingButtonController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
