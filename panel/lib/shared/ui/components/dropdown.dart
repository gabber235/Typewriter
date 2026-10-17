import "package:typewriter_panel/typewriter_panel.dart";

/// A decorated wrapper around Material's [DropdownMenu] for editor inputs.
///
/// It keeps focus, selection initialization, action shortcuts, surrounding
/// actions, and key event blocking on the same [InputFieldContainer] boundary,
/// so dropdowns behave like other editor controls.
///
class Dropdown<T extends Object> extends HookWidget {
  const Dropdown({
    required this.dropdownMenuEntries,
    this.selected,
    this.defaultValue,
    this.onSelected,
    this.controller,
    this.inputFieldController,
    this.enabled = true,
    this.initialization = SelectionInitializationPolicy.automatic,
    this.actions,
    this.menuActions,
    this.surroundingActions,
    this.inputDecorationTheme,
    this.menuStyle,
    this.enableFilter = true,
    this.menuHeight,
    this.hintText,
    this.leadingIcon,
    this.trailingIcon,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.onCustomValue,
    super.key,
  });

  /// Optional controller used for input/surrounding focus.
  final InputFieldController? inputFieldController;

  /// The entries shown in the dropdown menu.
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  /// The selected value.
  final T? selected;
  final T? defaultValue;

  /// Called when a new value is selected.
  final ValueChanged<T?>? onSelected;

  /// Optional controller used by the dropdown's input.
  final TextEditingController? controller;

  /// Whether the dropdown is interactive.
  final bool enabled;
  final SelectionInitializationPolicy initialization;

  /// Actions available when either surrounding or input has focus.
  final List<ActionShortcut>? actions;

  /// Actions available when the dropdown input has focus.
  final List<ActionShortcut>? menuActions;

  /// Actions available when the surrounding has focus.
  final List<ActionShortcut>? surroundingActions;

  /// Input decoration theme for the dropdown's input.
  final InputDecorationTheme? inputDecorationTheme;

  /// Style of the dropdown menu.
  final MenuStyle? menuStyle;
  final bool enableFilter;
  final double? menuHeight;
  final String? hintText;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final ValueChanged<String>? onCustomValue;

  @override
  Widget build(BuildContext context) {
    final current = useMemoized(
      () => dropdownMenuEntries
          .where((entry) => entry.value == selected)
          .firstOrNull,
      [selected, dropdownMenuEntries],
    );
    final currentLabel = current?.label;
    final controller =
        this.controller ?? useTextEditingController(text: currentLabel);
    final defaultInputFieldController = useInputFieldController(
      inputDebugLabel: "Dropdown",
      surroundingDebugLabel: "Surrounding focus node",
    );
    final inputFieldController =
        this.inputFieldController ?? defaultInputFieldController;
    final focusNode = inputFieldController.inputFocusNode;

    // When we are not focused, we want to update the controller with the latest.
    // Since other people may update the text and we want that reflected.
    // However, when we are focused, we don't want to update the controller as this causes the cursor to jump.
    useEffect(() {
      if (!focusNode.hasFocus && currentLabel != null) {
        controller.text = currentLabel;
      }
      return null;
    }, [currentLabel]);
    useFocusedChange(focusNode, ({required hasFocus}) {
      if (!hasFocus) {
        controller.text = currentLabel ?? "";
      }
    }, [currentLabel]);
    return SelectionInitialization<T>(
      selected: selected,
      defaultValue: defaultValue,
      choices: dropdownMenuEntries
          .where((entry) => entry.enabled)
          .map((entry) => entry.value),
      enabled: enabled,
      policy: initialization,
      onSelected: onSelected,
      child: InputFieldContainer(
        controller: inputFieldController,
        actions: actions,
        inputActions: [
          ...?menuActions,
          if (onCustomValue != null)
            ActionShortcut(
              id: "choice_custom_value",
              priority: 1002,
              label: "Use typed value",
              description: "Use the current query as a custom value",
              activators: [
                AdaptiveSingleActivator(
                  LogicalKeyboardKey.enter,
                  control: true,
                ),
              ],
              onInvoke: (_) {
                if (enabled && controller.text.isNotEmpty) {
                  onCustomValue!(controller.text);
                }
              },
            ),
        ],
        surroundingActions: surroundingActions,
        child: DropdownMenu<T>(
          focusNode: focusNode,
          controller: controller,
          enabled: enabled,
          enableFilter: enableFilter,
          menuHeight: menuHeight,
          hintText: hintText,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          textStyle: textStyle,
          textAlign: textAlign,
          initialSelection: selected,
          onSelected: (value) {
            if (value == null &&
                onCustomValue != null &&
                controller.text.isNotEmpty) {
              onCustomValue!(controller.text);
            } else {
              onSelected?.call(value);
            }
            if (value != null) {
              inputFieldController.endInteraction();
            }
            if (focusNode.hasFocus) {
              inputFieldController.requestSurroundingFocus();
            }
          },
          dropdownMenuEntries: dropdownMenuEntries,
          inputDecorationTheme: inputDecorationTheme,
          menuStyle: menuStyle,
          expandedInsets: EdgeInsets.zero,
        ),
      ),
    );
  }
}
