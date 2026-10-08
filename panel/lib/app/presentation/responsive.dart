import "package:typewriter_panel/typewriter_panel.dart";

/// Installs the panel's shared responsive breakpoint vocabulary.
///
/// Every descendant reads these breakpoints through the responsive framework
/// and the panel's `BuildContext` helpers. Keeping the ranges here prevents
/// feature layouts from inventing incompatible mobile, tablet, desktop, or
/// 4K thresholds.
class Responsive extends StatelessWidget {
  const Responsive({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        ResponsiveBreakpoint(start: 0, end: 450, name: MOBILE),
        ResponsiveBreakpoint(start: 451, end: 1000, name: TABLET),
        ResponsiveBreakpoint(start: 1001, end: 1920, name: DESKTOP),
        ResponsiveBreakpoint(start: 1921, end: double.infinity, name: "4K"),
      ],
      child: child,
    );
  }
}
