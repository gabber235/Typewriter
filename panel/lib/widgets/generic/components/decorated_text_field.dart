import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/input_field_container.dart";

class DecoratedTextField extends HookWidget {
  const DecoratedTextField({
    required this.focusNode,
    this.controller,
    this.text,
    this.onChanged,
    this.onDone,
    this.onEditingComplete,
    this.onSubmitted,
    this.actions,
    this.textFieldActions,
    this.surroundingActions,
    this.style,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.decoration,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    super.key,
  }) : super();
  final TextEditingController? controller;
  final FocusNode focusNode;
  final String? text;

  /// Called any time the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user is done editing. Either by pressing done, or by losing focus.
  final ValueChanged<String>? onDone;

  /// Called when the users is done editing. It is responsible for what happens with focus.
  /// Prefer [onDone] or [onSubmitted] for handling the completion of editing.
  /// If left null, then the focus will go to the surrounding focus node when done editing.
  final VoidCallback? onEditingComplete;

  /// Called when the user presses done.
  final ValueChanged<String>? onSubmitted;

  /// Actions that can be performed when either the text field or the surrounding is focused.
  final List<ActionShortcut>? actions;

  /// Actions that can be performed when the text field is focused.
  final List<ActionShortcut>? textFieldActions;

  /// Actions that can be performed when the surrounding of the text field is focused.
  final List<ActionShortcut>? surroundingActions;

  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final int? maxLines;
  final TextAlign textAlign;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? useTextEditingController(text: text);

    // When we are not focused, we want to update the controller with the latest.
    // Since other people may update the text and we want that reflected.
    // However, when we are focused, we don't want to update the controller as this causes the cursor to jump.
    useEffect(
      () {
        if (!focusNode.hasFocus && text != null) {
          controller.text = text ?? "";
        }
        return null;
      },
      [text],
    );

    final previousFocus = useState(focusNode.hasFocus);
    useFocusedChange(
      focusNode,
      ({required hasFocus}) {
        final hadFocus = previousFocus.value;
        if (!hadFocus && hasFocus) {
          if (text != null) {
            controller.text = text!;
          }
        } else if (hadFocus && !hasFocus) {
          onDone?.call(controller.text);
        }
        previousFocus.value = hasFocus;
      },
      [text],
    );

    final surroundingFocusNode = useFocusNode(
      debugLabel: "Surrounding focus node",
      descendantsAreTraversable: false,
    );

    return InputFieldContainer(
      inputFocusNode: focusNode,
      surroundingFocusNode: surroundingFocusNode,
      actions: actions,
      inputActions: textFieldActions,
      surroundingActions: surroundingActions,
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        onEditingComplete:
            onEditingComplete ?? surroundingFocusNode.requestFocus,
        onSubmitted: (value) {
          onSubmitted?.call(value);
        },
        onChanged: onChanged,
        style: style,
        textCapitalization: TextCapitalization.none,
        textInputAction:
            maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
        textAlign: textAlign,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? keyboardType : TextInputType.multiline,
        readOnly: readOnly,
        selectAllOnFocus: false,
        inputFormatters: [
          if (inputFormatters != null) ...inputFormatters!,
        ],
        decoration: decoration,
      ),
    );
  }
}
