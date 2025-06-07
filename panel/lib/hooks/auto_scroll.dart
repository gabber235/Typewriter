import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

enum AutoScrollLoopingMode {
  jumpToMin,
  pingPong,
}

/// Make a [ScrollController] auto scroll after a [delay] with a [velocity].
///
/// [loopingMode] defines how the scroll should loop.
void useAutoScroll(
  ScrollController controller, {
  bool enabled = true,
  Duration delay = const Duration(milliseconds: 2000),
  double velocity = 0.1,
  AutoScrollLoopingMode loopingMode = AutoScrollLoopingMode.jumpToMin,
}) {
  use(
    _AutoScrollHook(
      controller,
      enabled: enabled,
      delay: delay,
      velocity: velocity,
      loopingMode: loopingMode,
    ),
  );
}

class _AutoScrollHook extends Hook<void> {
  const _AutoScrollHook(
    this.controller, {
    required this.enabled,
    required this.delay,
    required this.velocity,
    required this.loopingMode,
  });

  final bool enabled;
  final ScrollController controller;
  final Duration delay;
  final double velocity;
  final AutoScrollLoopingMode loopingMode;

  @override
  _AutoScrollHookState createState() => _AutoScrollHookState();
}

class _AutoScrollHookState extends HookState<void, _AutoScrollHook> {
  int displayingVersion = 0;

  Future<void> scrollToEnd(int version) async {
    while (displayingVersion == version) {
      await Future.delayed(hook.delay);
      if (displayingVersion != version) return;

      final scroll = hook.controller.position.maxScrollExtent -
          hook.controller.position.minScrollExtent;
      final duration = Duration(milliseconds: (scroll / hook.velocity).round());
      await hook.controller.animateTo(
        hook.controller.position.maxScrollExtent,
        duration: duration,
        curve: Curves.linear,
      );
      if (displayingVersion != version) return;

      await Future.delayed(hook.delay);
      if (displayingVersion != version) return;

      switch (hook.loopingMode) {
        case AutoScrollLoopingMode.jumpToMin:
          hook.controller.jumpTo(hook.controller.position.minScrollExtent);
        case AutoScrollLoopingMode.pingPong:
          await hook.controller.animateTo(
            hook.controller.position.minScrollExtent,
            duration: duration,
            curve: Curves.linear,
          );
      }
    }
  }

  void refresh() {
    if (hook.enabled) {
      displayingVersion++;
      scrollToEnd(displayingVersion);
    } else {
      displayingVersion++;
      if (hook.controller.hasClients) {
        hook.controller.jumpTo(hook.controller.position.minScrollExtent);
      }
    }
  }

  @override
  void initHook() {
    super.initHook();
    refresh();
  }

  @override
  void didUpdateHook(_AutoScrollHook oldHook) {
    if (oldHook.enabled != hook.enabled) {
      refresh();
    }
  }

  @override
  void build(BuildContext context) {
    // Do nothing
  }

  @override
  void dispose() {
    displayingVersion = 0;
    if (hook.controller.hasClients) {
      hook.controller.jumpTo(hook.controller.position.minScrollExtent);
    }
    super.dispose();
  }
}
