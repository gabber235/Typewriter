import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/input_field_container.dart";

/// A decorated wrapper around Material's [DropdownMenu] that unifies focus
/// highlighting, surrounding focus behavior, managed action shortcuts, and
/// key-event blocking with [InputFieldContainer].
class Dropdown<T> extends HookWidget {
  const Dropdown({
    required this.focusNode,
    required this.dropdownMenuEntries,
    this.selected,
    this.onSelected,
    this.controller,
    this.enabled = true,
    this.actions,
    this.menuActions,
    this.surroundingActions,
    this.inputDecorationTheme,
    this.menuStyle,
    super.key,
  });

  /// Focus node for the inner dropdown menu input.
  final FocusNode focusNode;

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

    // When we are not focused, we want to update the controller with the latest.
    // Since other people may update the text and we want that reflected.
    // However, when we are focused, we don't want to update the controller as this causes the cursor to jump.
    useEffect(
      () {
        if (!focusNode.hasFocus && currentLabel != null) {
          controller.text = currentLabel;
        }
        return null;
      },
      [currentLabel],
    );
    useFocusedChange(
      focusNode,
      ({required hasFocus}) {
        if (!hasFocus) {
          controller.text = currentLabel ?? "";
        }
      },
      [currentLabel],
    );
    final surroundingFocusNode = useFocusNode(
      debugLabel: "Surrounding focus node",
      descendantsAreTraversable: false,
    );

    return InputFieldContainer(
      inputFocusNode: focusNode,
      surroundingFocusNode: surroundingFocusNode,
      actions: actions,
      inputActions: menuActions,
      surroundingActions: surroundingActions,
      child: DropdownMenu<T>(
        focusNode: focusNode,
        controller: controller,
        enabled: enabled,
        initialSelection: selected,
        onSelected: (value) {
          onSelected?.call(value);
          if (focusNode.hasFocus) {
            surroundingFocusNode.requestFocus();
          }
        },
        dropdownMenuEntries: dropdownMenuEntries,
        inputDecorationTheme: inputDecorationTheme,
        menuStyle: menuStyle,
      ),
    );
  }
}
