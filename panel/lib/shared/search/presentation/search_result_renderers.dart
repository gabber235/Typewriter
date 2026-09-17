import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "search_result_renderers.freezed.dart";

/// Context passed to a result row renderer.
///
/// [selected] reflects controller selection. [focused] includes both keyboard
/// focus and the active preview result. [loading] is true when a command
/// currently affects this result. [onTap] applies the presentation's selection
/// or single selection activation behavior.
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

/// State supplied to a preview renderer while preview data is resolved.
///
/// Renderers should preserve the result identity in every state and provide a
/// useful loading or error representation instead of assuming data is ready.
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

/// Builds one visible result row from its controller supplied context.
typedef SearchResultRowBuilder = Widget Function(
  SearchResultRowContext context,
);

/// Builds the preview for one result and one preview loading state.
typedef SearchResultPreviewBuilder = Widget Function(
  SearchResultPreviewContext context,
);

/// Returns the Control plus digit shortcut for visible result positions one
/// through nine. Other positions have no shortcut.
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

/// Fallback row shown when a source type has no registered row renderer.
///
/// Keeping the source identifier visible makes an incomplete renderer map
/// diagnosable without dropping the result from the tree.
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
