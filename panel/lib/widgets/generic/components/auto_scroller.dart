import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/auto_scroll.dart";

class AutoScroller extends HookWidget {
  const AutoScroller({
    required this.child,
    required this.scrollController,
    this.velocity = .1,
    this.delay = const Duration(milliseconds: 2000),
    this.loopingMode = AutoScrollLoopingMode.jumpToMin,
    super.key,
  });
  final Widget child;
  final double velocity;
  final Duration delay;
  final AutoScrollLoopingMode loopingMode;

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    useAutoScroll(
      scrollController,
      delay: delay,
      velocity: velocity,
      loopingMode: loopingMode,
    );
    return child;
  }
}
