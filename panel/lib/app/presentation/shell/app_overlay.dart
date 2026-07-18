import "package:flutter/material.dart";

class AppOverlay extends StatefulWidget {
  const AppOverlay({required this.child, super.key});

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
