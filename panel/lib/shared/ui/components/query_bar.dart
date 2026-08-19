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

class QueryBar extends HookWidget {
  const QueryBar({
    required this.query,
    required this.onQueryChanged,
    required this.selectors,
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

  final InputFieldController? inputFieldController;
  final String query;
  final void Function(String) onQueryChanged;
  final List<QuerySelectorDefinition> selectors;
  final InputDecoration inputDecoration;
  final EditorTextFieldAutoFocus autofocus;
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
