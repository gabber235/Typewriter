import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/hooks/input_field_controller.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/input_field_container.dart";

enum DecoratedTextFieldAutoFocus { none, textField, surroundingField }

class DecoratedTextField extends HookWidget {
  const DecoratedTextField({
    this.focusNode,
    this.inputFieldController,
    this.autofocus = DecoratedTextFieldAutoFocus.none,
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
  final FocusNode? focusNode;
  final InputFieldController? inputFieldController;

  /// Determines if the field auto‑focuses when built.
  final DecoratedTextFieldAutoFocus autofocus;

  /// The initial text to display in the field. If provided, it will be used to
  /// initialise the internal [TextEditingController] when no external controller
  /// is supplied. Subsequent updates are handled via the `text` parameter in the
  /// widget's build method.
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
    final defaultInputFieldController = useInputFieldController(
      inputFocusNode: this.focusNode,
      inputDebugLabel: "DecoratedTextField",
      surroundingDebugLabel: "Surrounding focus node",
    );
    final inputFieldController =
        this.inputFieldController ?? defaultInputFieldController;
    final focusNode = inputFieldController.inputFocusNode;
    final surroundingFocusNode = inputFieldController.surroundingFocusNode;

    // When we are not focused, we want to update the controller with the latest.
    // Since other people may update the text and we want that reflected.
    // However, when we are focused, we don't want to update the controller as this causes the cursor to jump.
    useEffect(() {
      if (!focusNode.hasFocus && text != null) {
        controller.text = text ?? "";
      }
      return null;
    }, [text]);

    final previousFocus = useState(focusNode.hasFocus);
    useFocusedChange(focusNode, ({required hasFocus}) {
      final hadFocus = previousFocus.value;
      if (!hadFocus && hasFocus) {
        if (text != null) {
          controller.text = text!;
        }
      } else if (hadFocus && !hasFocus) {
        onDone?.call(controller.text);
      }
      previousFocus.value = hasFocus;
    }, [text]);

    return InputFieldContainer(
      controller: inputFieldController,
      autofocus: autofocus == DecoratedTextFieldAutoFocus.surroundingField,
      actions: actions,
      inputActions: textFieldActions,
      surroundingActions: surroundingActions,
      child: TextField(
        focusNode: focusNode,
        autofocus: autofocus == DecoratedTextFieldAutoFocus.textField,
        controller: controller,
        onEditingComplete:
            onEditingComplete ?? surroundingFocusNode.requestFocus,
        onSubmitted: (value) {
          onSubmitted?.call(value);
        },
        onChanged: onChanged,
        style: style,
        textCapitalization: TextCapitalization.none,
        textInputAction: maxLines == 1
            ? TextInputAction.done
            : TextInputAction.newline,
        textAlign: textAlign,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? keyboardType : TextInputType.multiline,
        readOnly: readOnly,
        selectAllOnFocus: false,
        inputFormatters: [if (inputFormatters != null) ...inputFormatters!],
        decoration: decoration,
      ),
    );
  }
}
