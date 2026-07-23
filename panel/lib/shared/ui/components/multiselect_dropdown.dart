import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Ripped straight from Flutter's [DropdownMenu]
const double _kMinimumWidth = 112.0;

/// A generic multiselect dropdown component that allows selecting multiple items
/// from a list.
///
/// This component displays a button that opens a menu with checkboxes for each
/// item. Selected items are tracked and reported via [onSelectionChanged].
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

  /// Input decoration theme for the dropdown's input.
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
    if (context != null) {
      final box = context.findRenderObject()! as RenderBox;
      return box.hasSize ? box.size.width : null;
    }
    return null;
  }

  static final RegExp _tagResolver = RegExp(r"\s*\[[^\]]*\]");
  static String Function() searchTextParser(TextEditingController controller) {
    return () => controller.text.replaceAll(_tagResolver, "").trim();
  }

  Object? _handlePreviousFocus(
    List<DropdownMenuEntry<T>> filteredEntries,
    ValueNotifier<int?> fakeFocusIndex,
    MenuController menuController,
  ) {
    if (!enabled ||
        filteredEntries.none((e) => e.enabled) ||
        !menuController.isOpen) {
      return null;
    }
    fakeFocusIndex.value ??= 0;
    fakeFocusIndex.value = (fakeFocusIndex.value! - 1) % filteredEntries.length;
    while (!filteredEntries[fakeFocusIndex.value!].enabled) {
      fakeFocusIndex.value =
          (fakeFocusIndex.value! - 1) % filteredEntries.length;
    }
    return null;
  }

  Object? _handleNextFakeFocus(
    List<DropdownMenuEntry<T>> filteredEntries,
    ValueNotifier<int?> fakeFocusIndex,
    MenuController menuController,
  ) {
    if (!enabled ||
        filteredEntries.none((e) => e.enabled) ||
        !menuController.isOpen) {
      return null;
    }
    fakeFocusIndex.value ??= -1;
    fakeFocusIndex.value = (fakeFocusIndex.value! + 1) % filteredEntries.length;
    while (!filteredEntries[fakeFocusIndex.value!].enabled) {
      fakeFocusIndex.value =
          (fakeFocusIndex.value! + 1) % filteredEntries.length;
    }
    return null;
  }

  void _handleEnter(
    List<DropdownMenuEntry<T>> filteredEntries,
    ValueNotifier<int?> fakeFocusIndex,
    MenuController menuController,
  ) {
    if (!enabled || !menuController.isOpen || fakeFocusIndex.value == null) {
      return;
    }
    final entry = filteredEntries[fakeFocusIndex.value!];
    if (entry.enabled) {
      _toggleItem(entry.value);
    }
  }

  void _toggleItem(T item) {
    if (selectedItems.contains(item)) {
      onSelectionChanged?.call(selectedItems.where((i) => i != item).toList());
    } else {
      onSelectionChanged?.call([...selectedItems, item]);
    }
  }

  void _onSetLabels(List<String> labels) {
    final requiredKeep = dropdownMenuEntries
        .where((e) => selectedItems.contains(e.value))
        .where((e) => !e.enabled)
        .map((e) => e.value)
        .toList();
    final possibleNew = dropdownMenuEntries
        .where((e) => labels.contains(e.label))
        .where((e) => e.enabled)
        .map((e) => e.value)
        .toList();

    final items = [...requiredKeep, ...possibleNew];
    onSelectionChanged?.call(items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuController = useMenuController();
    final anchorKey = useGlobalKey();
    final randomSeed = useState(random.nextDouble());

    final selected = useMemoized(
      () => dropdownMenuEntries
          .where((entry) => selectedItems.contains(entry.value))
          .toList(),
      [selectedItems],
    );
    final currentLabel = useMemoized(
      () => "${selected.map((entry) => "[${entry.label}]").join()} ",
      [selected],
    );

    Widget buildLabelWidget(BuildContext context, String label) {
      final entry = dropdownMenuEntries.firstWhereOrNull(
        (e) => e.label == label,
      );
      if (entry != null && itemBuilder != null) {
        return itemBuilder!(entry.value);
      }
      if (entry?.labelWidget != null) {
        return entry!.labelWidget!;
      }
      return Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final textController = useMultiSelectTextEditingController(
      text: currentLabel,
      labelWidgetBuilder: buildLabelWidget,
      onSetLabels: (labels) {
        _onSetLabels(labels);
        randomSeed.value = random.nextDouble();
      },
    );

    final defaultInputFieldController = useInputFieldController(
      inputFocusNode: this.focusNode,
      inputDebugLabel: "MultiselectDropdown",
      surroundingDebugLabel: "Surrounding focus node",
    );
    final inputFieldController =
        this.inputFieldController ?? defaultInputFieldController;
    final focusNode = inputFieldController.inputFocusNode;
    final surroundingFocusNode = inputFieldController.surroundingFocusNode;

    useEffect(() {
      textController.value = textController.value.copyWith(text: currentLabel);
      return null;
    }, [currentLabel, randomSeed.value]);

    useFocusedChange(focusNode, ({required hasFocus}) {
      if (!hasFocus) {
        textController.text = currentLabel;
      }
    }, [currentLabel]);

    final searchText = useListenableSelector(
      textController,
      searchTextParser(textController),
    );

    final filteredEntries = useMemoized(
      () => dropdownMenuEntries
          .where(
            (item) =>
                item.label.toLowerCase().contains(searchText.toLowerCase()),
          )
          .toList(),
      [dropdownMenuEntries, searchText],
    );

    final fakeFocusIndex = useState<int?>(null);

    useEffect(() {
      if (fakeFocusIndex.value != null &&
          fakeFocusIndex.value! >= filteredEntries.length) {
        fakeFocusIndex.value = null;
      }

      if (fakeFocusIndex.value == null && filteredEntries.length == 1) {
        fakeFocusIndex.value = 0;
      }

      return null;
    }, [searchText, filteredEntries]);

    final isCollapsed = theme.inputDecorationTheme.isCollapsed;

    var effectiveMenuStyle =
        menuStyle ?? theme.dropdownMenuTheme.menuStyle ?? MenuStyle();

    effectiveMenuStyle = effectiveMenuStyle.copyWith(
      minimumSize: WidgetStateProperty.resolveWith<Size?>((states) {
        final width = getWidth(anchorKey) ?? _kMinimumWidth;
        final effectiveMaximumWidth = effectiveMenuStyle.maximumSize
            ?.resolve(states)
            ?.width;

        return Size(min(width, effectiveMaximumWidth ?? width), 0.0);
      }),
    );

    return InputFieldContainer(
      controller: inputFieldController,
      actions: actions,
      inputActions: menuActions,
      surroundingActions: surroundingActions,
      onInputFocus: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.hasPrimaryFocus) {
            menuController.open();
          }
        });
      },
      onDismiss: menuController.close,
      child: MenuAnchor(
        controller: menuController,
        style: effectiveMenuStyle,
        menuChildren: filteredEntries.indexed
            .map(
              (e) => _buildMenuItem(
                context,
                e.$2,
                effectiveMenuStyle,
                isFakeFocused: fakeFocusIndex.value == e.$1,
              ),
            )
            .toList(growable: false),
        childFocusNode: focusNode,
        onClose: surroundingFocusNode.requestFocus,
        crossAxisUnconstrained: false,
        child: Actions(
          actions: {
            _NextIntent: CallbackAction<_NextIntent>(
              onInvoke: (_) => _handleNextFakeFocus(
                filteredEntries,
                fakeFocusIndex,
                menuController,
              ),
            ),
            _PreviousIntent: CallbackAction<_PreviousIntent>(
              onInvoke: (_) => _handlePreviousFocus(
                filteredEntries,
                fakeFocusIndex,
                menuController,
              ),
            ),
            _EnterIntent: CallbackAction<_EnterIntent>(
              onInvoke: (_) =>
                  _handleEnter(filteredEntries, fakeFocusIndex, menuController),
            ),
          },
          child: Shortcuts(
            shortcuts: {
              for (final shortcut in shortcutsFor(PreviousFocusIntent))
                shortcut: _PreviousIntent(),
              for (final shortcut in shortcutsFor(NextFocusIntent))
                shortcut: _NextIntent(),
              for (final shortcut in shortcutsForIntent<DirectionalFocusIntent>(
                (intent) => intent.direction == TraversalDirection.up,
              ))
                shortcut: _PreviousIntent(),
              for (final shortcut in shortcutsForIntent<DirectionalFocusIntent>(
                (intent) => intent.direction == TraversalDirection.down,
              ))
                shortcut: _NextIntent(),
              SingleActivator(LogicalKeyboardKey.enter): _EnterIntent(),
              SingleActivator(
                LogicalKeyboardKey.arrowLeft,
              ): ExtendSelectionByCharacterIntent(
                forward: false,
                collapseSelection: true,
              ),
              SingleActivator(
                LogicalKeyboardKey.arrowRight,
              ): ExtendSelectionByCharacterIntent(
                forward: true,
                collapseSelection: true,
              ),
            },
            child: TextField(
              key: anchorKey,
              focusNode: focusNode,
              controller: textController,
              enabled: enabled,
              // Prevent Flutter from selecting all text when focus node
              // is notified during widget rebuilds (focus reparenting)
              selectAllOnFocus: false,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              decoration: InputDecoration(
                hintText: placeholder,
                suffixIcon: Padding(
                  padding: isCollapsed
                      ? EdgeInsets.zero
                      : EdgeInsets.all(context.spacing.space1),
                  child: Icon(
                    menuController.isOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ),
                isCollapsed: false,
                isDense: false,
                visualDensity: VisualDensity.comfortable,
                contentPadding: EdgeInsets.all(12),
              ),
              keyboardType: TextInputType.text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(height: 1.7),
              maxLines: null,
              onEditingComplete: () =>
                  _handleEnter(filteredEntries, fakeFocusIndex, menuController),
              onChanged: (_) => menuController.open(),
              onTap: enabled ? menuController.open : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    DropdownMenuEntry<T> entry,
    MenuStyle effectiveMenuStyle, {
    bool isFakeFocused = false,
  }) {
    final menuPadding = effectiveMenuStyle.padding!.resolve({})!.horizontal;
    final width =
        effectiveMenuStyle.minimumSize!.resolve({})!.width - menuPadding;

    final themeStyle = MenuButtonTheme.of(context).style;

    final effectiveForegroundColor =
        entry.style?.foregroundColor ?? themeStyle?.foregroundColor;
    final effectiveIconColor = entry.style?.iconColor ?? themeStyle?.iconColor;
    final effectiveOverlayColor =
        entry.style?.overlayColor ?? themeStyle?.overlayColor;
    final effectiveBackgroundColor =
        entry.style?.backgroundColor ?? themeStyle?.backgroundColor;

    var effectiveStyle = entry.style ?? MenuItemButton.styleFrom();

    // Simulate the focused state because the text field should always be focused
    // during traversal. Include potential MenuItemButton theme in the focus
    // simulation for all colors in the theme.
    if (entry.enabled && isFakeFocused) {
      final defaultStyle = const MenuItemButton().defaultStyleOf(context);

      Color? resolveFocusedColor(
        WidgetStateProperty<Color?>? colorStateProperty,
      ) {
        return colorStateProperty?.resolve(<WidgetState>{WidgetState.focused});
      }

      final focusedForegroundColor = resolveFocusedColor(
        effectiveForegroundColor ?? defaultStyle.foregroundColor!,
      )!;
      final focusedIconColor = resolveFocusedColor(
        effectiveIconColor ?? defaultStyle.iconColor!,
      )!;
      final focusedOverlayColor = resolveFocusedColor(
        effectiveOverlayColor ?? defaultStyle.overlayColor!,
      )!;
      // For the background color we can't rely on the default style which is transparent.
      // Defaults to onSurface.withOpacity(0.12).
      final focusedBackgroundColor =
          resolveFocusedColor(effectiveBackgroundColor) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

      effectiveStyle = effectiveStyle.copyWith(
        backgroundColor: WidgetStatePropertyAll<Color>(focusedBackgroundColor),
        foregroundColor: WidgetStatePropertyAll<Color>(focusedForegroundColor),
        iconColor: WidgetStatePropertyAll<Color>(focusedIconColor),
        overlayColor: WidgetStatePropertyAll<Color>(focusedOverlayColor),
      );
    } else {
      effectiveStyle = effectiveStyle.copyWith(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
        iconColor: effectiveIconColor,
        overlayColor: effectiveOverlayColor,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: MenuItemButton(
        style: effectiveStyle,
        leadingIcon: entry.leadingIcon,
        trailingIcon: entry.trailingIcon,
        closeOnActivate: false,
        onPressed: entry.enabled ? () => _toggleItem(entry.value) : null,
        requestFocusOnHover: false,
        child: entry.labelWidget ?? Text(entry.label),
      ),
    );
  }
}

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
          ? const EdgeInsets.only(left: 8)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}

typedef ChangeTags = void Function(List<String> tags);
typedef LabelWidgetBuilder =
    Widget Function(BuildContext context, String label);

class _MultiSelectTextEditingController extends TextEditingController {
  _MultiSelectTextEditingController({
    required this.onSetLabels,
    required this.labelWidgetBuilder,
    super.text,
  });
  _MultiSelectTextEditingController.fromValue(
    super.value,
    this.onSetLabels,
    this.labelWidgetBuilder,
  ) : super.fromValue();

  final ChangeTags onSetLabels;
  final LabelWidgetBuilder labelWidgetBuilder;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final ranges = labelRanges(text);
    final children = <InlineSpan>[];

    var currentPosition = 0;

    for (final range in ranges) {
      if (currentPosition < range.start) {
        children.add(
          TextSpan(text: text.substring(currentPosition, range.start)),
        );
      }

      final labelText = text.substring(range.start + 1, range.end - 1);
      children.add(WidgetSpan(child: labelWidgetBuilder(context, labelText)));

      // Add zero-width spaces to account for the remaining characters.
      // WidgetSpan counts as 1 character, but the original text (including brackets)
      // is longer. We need to pad with invisible characters to fix cursor positioning.
      // See: https://github.com/flutter/flutter/issues/107432
      final originalLength = range.end - range.start;
      if (originalLength > 1) {
        children.add(TextSpan(text: "\u200b" * (originalLength - 1)));
      }

      currentPosition = range.end;
    }

    if (currentPosition < text.length) {
      children.add(TextSpan(text: text.substring(currentPosition)));
    }

    return TextSpan(style: style, children: children);
  }

  @override
  set value(TextEditingValue newValue) {
    if (!newValue.selection.isValid) {
      super.value = newValue;
      return;
    }

    final isTextSame = text == newValue.text;

    if (isTextSame) {
      _skipTagMovement(value, newValue);
      return;
    }

    _modifyTags(value, newValue);
  }

  void _skipTagMovement(
    TextEditingValue previousValue,
    TextEditingValue newValue,
  ) {
    assert(newValue.text == value.text);

    final previousSelection = previousValue.selection;
    final newSelection = newValue.selection;

    final previousBase = previousSelection.baseOffset;
    final newBase = newSelection.baseOffset;
    final previousExtent = previousSelection.extentOffset;
    final newExtent = newSelection.extentOffset;

    if (previousExtent == newExtent && previousBase == newBase) {
      super.value = newValue;
      return;
    }
    final ranges = labelRanges(text);

    final correctExtent = expandIndex(previousExtent, newExtent, ranges);

    if (newValue.selection.isCollapsed) {
      super.value = newValue.copyWith(
        selection: newSelection.copyWith(
          baseOffset: correctExtent,
          extentOffset: correctExtent,
        ),
      );
      return;
    }

    final correctedBase = expandIndex(previousBase, newBase, ranges);

    super.value = newValue.copyWith(
      selection: newValue.selection.copyWith(
        baseOffset: correctedBase,
        extentOffset: correctExtent,
      ),
    );
  }

  int expandIndex(int previousIndex, int newIndex, List<TextRange> ranges) {
    final range = ranges.firstWhereOrNull(
      (range) => range.start <= newIndex && newIndex < range.end,
    );
    if (range == null) return newIndex;
    final moveRight = previousIndex < newIndex;
    return moveRight ? range.end : range.start;
  }

  void _modifyTags(TextEditingValue value, TextEditingValue newValue) {
    assert(newValue.text != value.text);

    final oldRanges = labelRanges(value.text);
    final newRanges = labelRanges(newValue.text);

    final allRangesTheSame =
        oldRanges.length == newRanges.length &&
        oldRanges.indexed.every((e) {
          final (index, oldRange) = e;
          final newRange = newRanges[index];
          return oldRange.start == newRange.start &&
              oldRange.end == newRange.end;
        });

    if (allRangesTheSame) {
      super.value = newValue;
      return;
    }

    final newLabels = newRanges.map((range) {
      final rangeText = range.textInside(newValue.text);
      return rangeText.substring(1, rangeText.length - 1);
    }).toList();

    super.value = newValue;
    onSetLabels(newLabels);
  }

  static final tagRegex = RegExp(r"\[[^\]\[]+\]");
  List<TextRange> labelRanges(String text) {
    final ranges = <TextRange>[];
    final Iterable<Match> matches = tagRegex.allMatches(text);

    for (final match in matches) {
      ranges.add(TextRange(start: match.start, end: match.end));
    }

    return ranges;
  }
}

const useMultiSelectTextEditingController =
    _MultiSelectTextEditingControllerHookCreator();

class _MultiSelectTextEditingControllerHookCreator {
  const _MultiSelectTextEditingControllerHookCreator();

  /// Creates a [TextEditingController] that will be disposed automatically.
  ///
  /// The [text] parameter can be used to set the initial value of the
  /// controller.
  _MultiSelectTextEditingController call({
    required ChangeTags onSetLabels,
    required LabelWidgetBuilder labelWidgetBuilder,
    String? text,
    List<Object?>? keys,
  }) {
    return use(
      _MultiSelectTextEditingControllerHook(
        text,
        onSetLabels,
        labelWidgetBuilder,
        keys,
      ),
    );
  }

  /// Creates a [TextEditingController] from the initial [value] that will
  /// be disposed automatically.
  _MultiSelectTextEditingController fromValue(
    TextEditingValue value,
    ChangeTags onSetLabels,
    LabelWidgetBuilder labelWidgetBuilder, [
    List<Object?>? keys,
  ]) {
    return use(
      _MultiSelectTextEditingControllerHook.fromValue(
        value,
        onSetLabels,
        labelWidgetBuilder,
        keys,
      ),
    );
  }
}

class _MultiSelectTextEditingControllerHook
    extends Hook<_MultiSelectTextEditingController> {
  const _MultiSelectTextEditingControllerHook(
    this.initialText,
    this.onSetLabels,
    this.labelWidgetBuilder, [
    List<Object?>? keys,
  ]) : initialValue = null,
       super(keys: keys);

  const _MultiSelectTextEditingControllerHook.fromValue(
    TextEditingValue this.initialValue,
    this.onSetLabels,
    this.labelWidgetBuilder, [
    List<Object?>? keys,
  ]) : initialText = null,
       super(keys: keys);

  final String? initialText;
  final TextEditingValue? initialValue;
  final ChangeTags onSetLabels;
  final LabelWidgetBuilder labelWidgetBuilder;

  @override
  _TextEditingControllerHookState createState() {
    return _TextEditingControllerHookState();
  }
}

class _TextEditingControllerHookState
    extends
        HookState<
          _MultiSelectTextEditingController,
          _MultiSelectTextEditingControllerHook
        > {
  late final _controller = hook.initialValue != null
      ? _MultiSelectTextEditingController.fromValue(
          hook.initialValue,
          hook.onSetLabels,
          hook.labelWidgetBuilder,
        )
      : _MultiSelectTextEditingController(
          text: hook.initialText,
          onSetLabels: hook.onSetLabels,
          labelWidgetBuilder: hook.labelWidgetBuilder,
        );

  @override
  _MultiSelectTextEditingController build(BuildContext context) => _controller;

  @override
  void dispose() => _controller.dispose();

  @override
  String get debugLabel => "useMultiSelectTextEditingController";
}
