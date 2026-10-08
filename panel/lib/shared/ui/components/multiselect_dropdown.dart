import "package:typewriter_panel/typewriter_panel.dart";

part "multiselect_dropdown_controller.dart";
part "multiselect_dropdown_intents.dart";
part "multiselect_dropdown_view.dart";
part "multiselect_text_controller.dart";
part "multiselect_text_controller_hook.dart";

/// The minimum menu width used when the input has not been laid out yet.
const double _kMinimumWidth = 112.0;

/// Coordinates controlled multi selection with text search and keyboard
/// navigation.
///
/// [selectedItems] is authoritative. This widget derives its displayed labels
/// and menu state from that value, then proposes replacements through
/// [onSelectionChanged]. It does not mutate the caller's list. Editing the
/// input removes or adds enabled entries by their labels, while selected
/// disabled entries are retained.
///
/// The input keeps focus while arrow keys move a separate highlighted menu
/// index. Enter toggles that entry, and Escape returns focus to the surrounding
/// field through [inputFieldController] when one is supplied. Use
/// [inputFieldController] when another control owns the input and surrounding
/// focus lifecycle; [focusNode] is retained for callers using the older input
/// only contract.
class MultiselectDropdown<T extends Object> extends HookWidget {
  const MultiselectDropdown({
    required this.dropdownMenuEntries,
    this.focusNode,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.enabled = true,
    this.inputFieldController,
    this.actions,
    this.menuActions,
    this.surroundingActions,
    this.inputDecorationTheme,
    this.menuStyle,
    this.placeholder,
    this.itemBuilder,
    super.key,
  });

  /// Optional legacy focus node used by the dropdown's input.
  final FocusNode? focusNode;

  /// Optional controller used for input/surrounding focus.
  final InputFieldController? inputFieldController;

  /// All available items to select from.
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  /// Currently selected items.
  final List<T> selectedItems;

  /// Called when the selection changes.
  final ValueChanged<List<T>>? onSelectionChanged;

  /// Whether the dropdown is interactive.
  final bool enabled;

  /// Actions available when either surrounding or input has focus.
  final List<ActionShortcut>? actions;

  /// Actions available when the dropdown input has focus.
  final List<ActionShortcut>? menuActions;

  /// Actions available when the surrounding has focus.
  final List<ActionShortcut>? surroundingActions;

  /// Legacy input decoration configuration retained for source compatibility.
  ///
  /// The component currently uses its own input decoration and does not apply
  /// this value.
  final InputDecorationTheme? inputDecorationTheme;

  /// Style of the dropdown menu.
  final MenuStyle? menuStyle;

  /// Placeholder text for the dropdown's input.
  final String? placeholder;

  /// Optional builder to create a widget for each selected item.
  /// If not provided, falls back to the entry's labelWidget, then to default styled text.
  final Widget Function(T item)? itemBuilder;

  double? getWidth(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject()! as RenderBox;
    return box.hasSize ? box.size.width : null;
  }

  static final RegExp _tagResolver = RegExp(r"\s*\[[^\]]*\]");

  /// Returns a selector that reads only the free text from the input.
  ///
  /// Selected labels are encoded as bracketed tokens in the editing value.
  /// Consumers that filter entries should use this parser rather than treating
  /// those display tokens as search text.
  static String Function() searchTextParser(TextEditingController controller) =>
      () => controller.text.replaceAll(_tagResolver, "").trim();

  @override
  Widget build(BuildContext context) {
    final controller = _useMultiselectDropdownController(context, this);
    return _MultiselectDropdownView(dropdown: this, controller: controller);
  }
}

/// Displays one selected value for use inside a controlled multiselect field.
///
/// The chip does not own selection or remove itself. [onDelete] is the caller's
/// opportunity to propose a new selection when its delete action is activated;
/// pass null when the value must remain present.
class SmallChip extends HookWidget {
  const SmallChip({
    required this.label,
    required this.color,
    required this.onDelete,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: onDelete != null
          ? EdgeInsets.only(left: context.spacing.space2)
          : EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space1,
            ),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: color)),
        color: color.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: color,
              fontSize: 12,
              fontVariations: [FontVariation.weight(500)],
              height: 1.2,
            ),
          ),
          if (onDelete != null)
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                  vertical: context.spacing.space1,
                ),
                child: Icon(Icons.close, size: 13, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

// `DropdownMenu` dispatches these private intents on arrow up/down keys.
// They are needed instead of the typical `DirectionalFocusIntent`s because
// `DropdownMenu` does not really navigate the focus tree upon arrow up/down
// keys: the focus stays on the text field and the menu items are given fake
// highlights as if they are focused. Using `DirectionalFocusIntent`s will cause
// the action to be processed by `EditableText`.
