import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Hook for creating and managing a LoadingButtonController.
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
