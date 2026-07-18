import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";
import "package:typewriter_panel/shared/utilities/adaptive_single_activator.dart";

part "search_result_renderers.freezed.dart";

@freezed
abstract class SearchResultRowContext with _$SearchResultRowContext {
  const factory SearchResultRowContext({
    required SearchResult result,
    required bool selected,
    required bool focused,
    required bool loading,
    required VoidCallback onTap,
    ShortcutActivator? shortcutActivator,
  }) = _SearchResultRowContext;
}

@freezed
sealed class SearchResultPreviewContext with _$SearchResultPreviewContext {
  const factory SearchResultPreviewContext.loading({
    required SearchResult result,
  }) = SearchResultPreviewContextLoading;

  const factory SearchResultPreviewContext.data({
    required SearchResult result,
    required Object data,
  }) = SearchResultPreviewContextData;

  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchResultPreviewContext.error({
    required SearchResult result,
    required String message,
  }) = SearchResultPreviewContextError;
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
  return AdaptiveSingleActivator(key, control: true);
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
