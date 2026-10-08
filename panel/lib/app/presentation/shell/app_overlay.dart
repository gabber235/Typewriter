import "package:typewriter_panel/typewriter_panel.dart";

// Hosts the panel body in the app's single opaque overlay entry.
//
// The entry is retained across widget rebuilds so overlay descendants keep
// their route and focus state. Replacing child updates that entry without
// replacing the surrounding Overlay.

class AppOverlay extends StatefulWidget {
  const AppOverlay({required this.child, super.key});

  /// The content rendered by the retained overlay entry.
  final Widget child;

  @override
  State<AppOverlay> createState() => _AppOverlayState();
}

class _AppOverlayState extends State<AppOverlay> {
  late final OverlayEntry _entry = OverlayEntry(
    canSizeOverlay: true,
    opaque: true,
    builder: (context) => widget.child,
  );

  @override
  void didUpdateWidget(AppOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
