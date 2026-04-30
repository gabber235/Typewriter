import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/logic/search/search.dart";

class SearchResultRowContext {
  const SearchResultRowContext({
    required this.result,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.onLongPress,
    this.shortcutActivator,
  });

  final SearchResult result;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ShortcutActivator? shortcutActivator;
}

class SearchResultPreviewContext {
  const SearchResultPreviewContext({required this.result});

  final SearchResult result;
}

typedef SearchResultRowBuilder =
    Widget Function(SearchResultRowContext context);

typedef SearchResultPreviewBuilder =
    Widget Function(SearchResultPreviewContext context);

ShortcutActivator? searchResultShortcutActivator(int? shortcutNumber) {
  if (shortcutNumber == null || shortcutNumber < 1 || shortcutNumber > 9) {
    return null;
  }
  final key = switch (shortcutNumber) {
    1 => LogicalKeyboardKey.digit1,
    2 => LogicalKeyboardKey.digit2,
    3 => LogicalKeyboardKey.digit3,
    4 => LogicalKeyboardKey.digit4,
    5 => LogicalKeyboardKey.digit5,
    6 => LogicalKeyboardKey.digit6,
    7 => LogicalKeyboardKey.digit7,
    8 => LogicalKeyboardKey.digit8,
    9 => LogicalKeyboardKey.digit9,
    _ => throw StateError("Invalid shortcut number"),
  };
  final isMac =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return SingleActivator(key, meta: isMac, control: !isMac);
}

class MissingSearchResultRendererRow extends StatelessWidget {
  const MissingSearchResultRendererRow({required this.result, super.key});

  final SearchResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(result.title ?? result.id),
      subtitle: Text("Missing renderer ${result.type.rowRendererId}"),
    );
  }
}
