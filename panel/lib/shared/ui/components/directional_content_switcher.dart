import "package:flutter/material.dart";

class DirectionalContentSwitcher extends StatefulWidget {
  const DirectionalContentSwitcher({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<DirectionalContentSwitcher> createState() =>
      _DirectionalContentSwitcherState();
}

class _DirectionalContentSwitcherState
    extends State<DirectionalContentSwitcher> {
  int _direction = 0;

  @override
  void didUpdateWidget(DirectionalContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _direction = widget.index.compareTo(oldWidget.index);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.child.key != null);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final sizeDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 300);
    final currentKey = widget.child.key;
    final direction = _direction.toDouble();

    return AnimatedSize(
      duration: sizeDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              for (final child in previousChildren)
                Positioned(top: 0, left: 0, right: 0, child: child),
              ?currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == currentKey;
            final offset = Offset(incoming ? direction : -direction, 0);
            final position = Tween(
              begin: offset,
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: position, child: child),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
