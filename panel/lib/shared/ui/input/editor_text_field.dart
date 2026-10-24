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
    this.statesController,
    this.autofocus = EditorTextFieldAutoFocus.none,
    this.controller,
    this.text,
    this.validator,
    this.onChanged,
    this.onDone,
    this.onCommittedDone,
    this.onEditingComplete,
    this.onSubmitted,
    this.actions,
    this.textFieldActions,
    this.surroundingActions,
    this.style,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.decoration,
    this.displayText,
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
  final WidgetStatesController? statesController;

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

  /// Receives the exact editor buffer once focus leaves and composition ends.
  /// Display text is never passed to this callback.
  final ValueChanged<TextEditingValue>? onCommittedDone;

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
  final TextCapitalization textCapitalization;
  final bool enableSuggestions;
  final bool obscureText;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final String? displayText;
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
    final ownTextChanges = useRef(<String>[]);
    final observedText = useRef(text);
    var ownTextEcho = false;
    if (text != observedText.value && text != null) {
      final acknowledged = ownTextChanges.value.indexOf(text!);
      ownTextEcho = acknowledged >= 0;
      if (acknowledged >= 0) {
        ownTextChanges.value.removeRange(0, acknowledged + 1);
      } else {
        ownTextChanges.value.clear();
      }
      observedText.value = text;
    }
    final pendingCompletion = useRef(false);
    final active = useRef(true);
    useEffect(() {
      active.value = true;
      return () => active.value = false;
    }, const []);
    void completeCommittedInput() {
      if (!active.value || !pendingCompletion.value || focusNode.hasFocus) {
        return;
      }
      final value = controller.value;
      if (value.composing.isValid && !value.composing.isCollapsed) return;
      pendingCompletion.value = false;
      onCommittedDone?.call(value);
    }

    useEffect(() {
      controller.addListener(completeCommittedInput);
      return () => controller.removeListener(completeCommittedInput);
    }, [controller, focusNode, onCommittedDone]);

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

    // Own edits already match the controller. Shared changes replace bound text
    // while preserving the selection, including when this field has focus.
    useEffect(() {
      final composing = controller.value.composing;
      final editing =
          focusNode.hasFocus || (composing.isValid && !composing.isCollapsed);
      final pendingOwnDraft = ownTextChanges.value.isNotEmpty;
      final visibleText = pendingOwnDraft || ownTextEcho && editing
          ? null
          : editing
          ? text
          : displayText ?? text;
      if (visibleText != null && controller.text != visibleText) {
        final selection = controller.selection;
        controller.value = TextEditingValue(
          text: visibleText,
          selection: selection.isValid
              ? TextSelection(
                  baseOffset: selection.baseOffset.clamp(0, visibleText.length),
                  extentOffset: selection.extentOffset.clamp(
                    0,
                    visibleText.length,
                  ),
                )
              : TextSelection.collapsed(offset: visibleText.length),
        );
      }
      return null;
    }, [text, displayText, focusNode.hasFocus]);

    final previousFocus = useState(focusNode.hasFocus);
    useFocusedChange(focusNode, ({required hasFocus}) {
      final hadFocus = previousFocus.value;
      if (!hadFocus && hasFocus) {
        pendingCompletion.value = false;
        if (text != null && ownTextChanges.value.isEmpty) {
          controller.text = text!;
        }
      } else if (hadFocus && !hasFocus) {
        if (active.value) {
          onDone?.call(controller.text);
          pendingCompletion.value = true;
          completeCommittedInput();
        }
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
        statesController: statesController,
        focusNode: focusNode,
        autofocus: autofocus == EditorTextFieldAutoFocus.textField,
        controller: controller,
        validator: validator,
        onEditingComplete:
            onEditingComplete ?? surroundingFocusNode.requestFocus,
        onFieldSubmitted: onSubmitted,
        onChanged: (draft) {
          ownTextChanges.value.add(draft);
          onChanged?.call(draft);
        },
        style: style,
        textCapitalization: textCapitalization,
        enableSuggestions: enableSuggestions,
        obscureText: obscureText,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
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
