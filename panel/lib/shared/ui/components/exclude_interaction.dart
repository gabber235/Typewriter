import "package:flutter/material.dart";

class ExcludeInteraction extends StatelessWidget {
  const ExcludeInteraction({
    required this.excluding,
    required this.child,
    super.key,
  });

  final bool excluding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: excluding,
      child: ExcludeFocus(
        excluding: excluding,
        child: IgnorePointer(ignoring: excluding, child: child),
      ),
    );
  }
}
