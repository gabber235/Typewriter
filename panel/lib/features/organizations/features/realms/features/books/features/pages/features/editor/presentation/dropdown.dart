import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/input_field_container.dart";
import "package:typewriter_panel/shared/hooks/focused_change.dart";
import "package:typewriter_panel/shared/hooks/input_field_controller.dart";

/// A decorated wrapper around Material's [DropdownMenu] that unifies focus
/// highlighting, surrounding focus behavior, managed action shortcuts, and
/// key-event blocking with [InputFieldContainer].
class Dropdown<T extends Object> extends HookWidget {
  const Dropdown({
    required this.dropdownMenuEntries,
    this.focusNode,
    this.selected,
    this.onSelected,
    this.controller,
    this.inputFieldController,
    this.enabled = true,
    this.actions,
    this.menuActions,
    this.surroundingActions,
    this.inputDecorationTheme,
    this.menuStyle,
    super.key,
  });

  /// Optional legacy focus node for the inner dropdown menu input.
  final FocusNode? focusNode;

  /// Optional controller used for input/surrounding focus.
  final InputFieldController? inputFieldController;

  /// The entries shown in the dropdown menu.
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  /// The selected value.
  final T? selected;

  /// Called when a new value is selected.
  final ValueChanged<T?>? onSelected;

  /// Optional controller used by the dropdown's input.
  final TextEditingController? controller;

  /// Whether the dropdown is interactive.
  final bool enabled;

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

  @override
  Widget build(BuildContext context) {
    final current = useMemoized(
      () => dropdownMenuEntries
          .where((entry) => entry.value == selected)
          .firstOrNull,
      [selected],
    );
    final currentLabel = current?.label;
    final controller =
        this.controller ?? useTextEditingController(text: currentLabel);
    final defaultInputFieldController = useInputFieldController(
      inputFocusNode: this.focusNode,
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
    return InputFieldContainer(
      controller: inputFieldController,
      actions: actions,
      inputActions: menuActions,
      surroundingActions: surroundingActions,
      child: DropdownMenu<T>(
        focusNode: focusNode,
        controller: controller,
        enabled: enabled,
        enableFilter: true,
        initialSelection: selected,
        onSelected: (value) {
          onSelected?.call(value);
          if (focusNode.hasFocus) {
            inputFieldController.requestSurroundingFocus();
          }
        },
        dropdownMenuEntries: dropdownMenuEntries,
        inputDecorationTheme: inputDecorationTheme,
        menuStyle: menuStyle,
      ),
    );
  }
}
