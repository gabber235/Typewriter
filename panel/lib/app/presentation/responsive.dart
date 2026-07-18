import "package:flutter/material.dart";
import "package:responsive_framework/responsive_framework.dart";

class Responsive extends StatelessWidget {
  const Responsive({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 1000, name: TABLET),
        Breakpoint(start: 1001, end: 1920, name: DESKTOP),
        Breakpoint(start: 1921, end: double.infinity, name: "4K"),
      ],
      child: child,
    );
  }
}
