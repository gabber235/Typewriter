import "package:typewriter_panel/typewriter_panel.dart";

/// Arranges an optional app bar above a body without imposing scaffold chrome.
///
/// Use this when the surrounding route already owns the page shell and only
/// needs the standard app bar and expanded body relationship.
class SimpleScaffold extends StatelessWidget {
  const SimpleScaffold({required this.child, required this.appBar, super.key});

  /// Body expanded to fill the space below [appBar].
  final Widget child;

  /// Optional header. A null value leaves the header row absent.
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
