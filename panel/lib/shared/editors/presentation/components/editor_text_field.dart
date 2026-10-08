import "package:typewriter_panel/typewriter_panel.dart";

/// Selects which focus boundary receives focus when the field is built.
enum EditorTextFieldAutoFocus { none, textField, surroundingField }

/// Provides the shared text editing behavior used by presentation controls.
///
/// The optional surrounding focus boundary lets keyboard actions address the
/// field and its container separately. Completion callbacks run when editing
/// ends, while [onEditingComplete] can override the default focus transfer.
class EditorTextField extends HookWidget {
  const EditorTextField({
    this.focusNode,
    this.inputFieldController,
    this.autofocus = EditorTextFieldAutoFocus.none,
    this.controller,
    this.text,
    this.validator,
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
    this.hintText,
    this.prefix,
    this.singleLine = true,
    this.minLines,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.enabled = true,
    this.selectAllOnFocus = false,
    this.onInputFocus,
    this.onDismiss,
    super.key,
  }) : super();
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputFieldController? inputFieldController;

  /// Determines whether the field or its surrounding focus boundary receives
  /// focus automatically when built.
  final EditorTextFieldAutoFocus autofocus;

  /// The initial text to display in the field. If provided, it will be used to
  /// initialise the internal [TextEditingController] when no external controller
  /// is supplied. Subsequent updates are handled via the `text` parameter in the
  /// widget's build method.
  final String? text;

  /// Validates the text field's input.
  final FormFieldValidator<String>? validator;

  /// Called any time the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user is done editing, either by pressing done or losing
  /// focus.
  final ValueChanged<String>? onDone;

  /// Called when editing completes to control the next focus transition.
  /// Prefer [onDone] or [onSubmitted] when only the value needs handling. If
  /// null, focus moves to the surrounding focus node.
  final VoidCallback? onEditingComplete;

  /// Called when the user presses done.
  final ValueChanged<String>? onSubmitted;

  /// Actions available while either focus boundary is active.
  final List<ActionShortcut>? actions;

  /// Actions available while the text field has focus.
  final List<ActionShortcut>? textFieldActions;

  /// Actions available while the surrounding focus boundary has focus.
  final List<ActionShortcut>? surroundingActions;

  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final String? hintText;
  final Widget? prefix;
  final bool singleLine;
  final int? minLines;
  final int? maxLines;
  final TextAlign textAlign;
  final bool enabled;
  final bool readOnly;
  final bool selectAllOnFocus;
  final VoidCallback? onInputFocus;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? useTextEditingController(text: text);
    final defaultInputFieldController = useInputFieldController(
      inputFocusNode: this.focusNode,
      inputDebugLabel: "EditorTextField",
      surroundingDebugLabel: "Surrounding focus node",
    );
    final inputFieldController =
        this.inputFieldController ?? defaultInputFieldController;
    final focusNode = inputFieldController.inputFocusNode;
    final surroundingFocusNode = inputFieldController.surroundingFocusNode;

    useEffect(() {
      if (!selectAllOnFocus || !focusNode.hasPrimaryFocus) return null;
      var active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!active || !focusNode.hasPrimaryFocus) return;
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      });
      return () => active = false;
    }, [controller, focusNode.hasPrimaryFocus, selectAllOnFocus]);

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

    final effectiveMaxLines = maxLines ?? (singleLine ? 1 : null);
    final isSingleLine = effectiveMaxLines == 1;
    final baseDecoration = decoration ?? const InputDecoration();
    final effectiveDecoration = baseDecoration.copyWith(
      prefixIcon: baseDecoration.prefixIcon ?? _prefix(context),
      hintText: baseDecoration.hintText ?? hintText,
      contentPadding:
          baseDecoration.contentPadding ??
          (isSingleLine
              ? null
              : EdgeInsets.only(
                  top: context.spacing.space3,
                  bottom: context.spacing.space3,
                  right: context.spacing.space2,
                )),
    );

    return InputFieldContainer(
      controller: inputFieldController,
      autofocus: autofocus == EditorTextFieldAutoFocus.surroundingField,
      actions: actions,
      inputActions: textFieldActions,
      surroundingActions: surroundingActions,
      onInputFocus: onInputFocus,
      onDismiss: onDismiss,
      child: TextFormField(
        focusNode: focusNode,
        autofocus: autofocus == EditorTextFieldAutoFocus.textField,
        controller: controller,
        validator: validator,
        onEditingComplete:
            onEditingComplete ?? surroundingFocusNode.requestFocus,
        onFieldSubmitted: onSubmitted,
        onChanged: onChanged,
        style: style,
        textCapitalization: TextCapitalization.none,
        textInputAction: isSingleLine
            ? TextInputAction.done
            : TextInputAction.newline,
        textAlign: textAlign,
        minLines: minLines,
        maxLines: effectiveMaxLines,
        keyboardType: isSingleLine ? keyboardType : TextInputType.multiline,
        enabled: enabled,
        readOnly: readOnly,
        selectAllOnFocus: selectAllOnFocus,
        inputFormatters: [
          if (isSingleLine) FilteringTextInputFormatter.singleLineFormatter,
          ...?inputFormatters,
        ],
        decoration: effectiveDecoration,
      ),
    );
  }

  Widget? _prefix(BuildContext context) {
    if (prefix == null) return null;
    return Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: prefix,
    );
  }
}
