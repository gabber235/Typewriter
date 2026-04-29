import "package:flutter/material.dart";

class SimpleScaffold extends StatelessWidget {
  const SimpleScaffold({required this.child, required this.appBar, super.key});

  final Widget child;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ?appBar,
        Expanded(child: child),
      ],
    );
  }
}
