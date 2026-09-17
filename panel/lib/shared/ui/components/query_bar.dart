import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "query_bar_controller.dart";
part "query_bar_shortcuts.dart";
part "query_bar_suggestions.dart";
part "query_bar_text_controller.dart";
part "query_bar_view.dart";

/// Provides the panel's controlled query editor, parser feedback, and
/// completion workflow.
///
/// [query] is the source of truth owned by the caller. Every edit, including a
/// completion, is reported through [onQueryChanged]; callers must feed the
/// accepted value back into [query]. [selectors] define the query language and
/// drive both highlighting and suggestions. While the popup is visible,
/// keyboard navigation changes its active suggestion without moving focus out
/// of the editor. Submission accepts the active suggestion first, then calls
/// [onSubmitted] with the resulting query when no suggestion handled it.
class QueryBar extends HookWidget {
  const QueryBar({
    required this.query,
    required this.onQueryChanged,
    required this.selectors,
    this.completeSelector,
    this.validationIssues = const [],
    this.inputFieldController,
    this.inputDecoration = const InputDecoration(hintText: "Search"),
    this.autofocus = EditorTextFieldAutoFocus.none,
    this.onSubmitted,
    this.onEditingComplete,
    this.onDone,
    this.onInputFocus,
    this.onDismiss,
    this.onCancel,
    this.textFieldActions,
    this.selectAllOnFocus = false,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  /// Optional owner for the editor's input and surrounding focus lifecycle.
  ///
  /// Omit this to let the component create and dispose its local controller.
  final InputFieldController? inputFieldController;
  final String query;

  /// Receives every edited query, including text inserted from a suggestion.
  final void Function(String) onQueryChanged;
  final List<QuerySelectorDefinition> selectors;
  final Future<SearchSelectorCompletionResult> Function(
    SearchSelectorCompletionRequest request,
  )?
  completeSelector;
  final List<QueryParseIssue> validationIssues;
  final InputDecoration inputDecoration;
  final EditorTextFieldAutoFocus autofocus;

  /// Receives the query after suggestion handling declines the submission.
  ///
  /// When a suggestion is accepted, [onQueryChanged] receives the replacement
  /// and this callback is not invoked for that same submission.
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onDone;
  final VoidCallback? onInputFocus;
  final VoidCallback? onDismiss;
  final VoidCallback? onCancel;
  final List<ActionShortcut>? textFieldActions;
  final bool selectAllOnFocus;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final controller = _useQueryBarController(this);
    return _QueryBarView(bar: this, controller: controller);
  }
}
