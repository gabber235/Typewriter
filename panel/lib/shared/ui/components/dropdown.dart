import "package:typewriter_panel/typewriter_panel.dart";

/// A single choice field for editor inputs: a text field that filters its
/// choices, which open in an [AnchoredPopup] below it.
///
/// It keeps focus, selection initialization, action shortcuts, surrounding
/// actions, and menu dismissal on the same [InputFieldContainer] boundary.
/// Activating the field opens its choices in insert mode while focus stays in
/// the field: typing filters and highlights the first match, the arrow keys
/// move the highlight, and Enter takes it. Selecting or dismissing returns to
/// surrounding focus; moving elsewhere closes the menu.
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
    this.popupColor,
    this.popupShape,
    this.popupPadding,
    this.popupConstraints,
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

  /// The choices shown in the dropdown menu.
  final List<MenuChoice<T>> dropdownMenuEntries;

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

  /// The choices' fill, outline, inset and size; the popup's own by default.
  final Color? popupColor;
  final ShapeBorder? popupShape;
  final EdgeInsetsGeometry? popupPadding;
  final BoxConstraints? popupConstraints;

  /// Whether typing narrows the choices; otherwise it only moves the
  /// highlight to the first match.
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
    final popup = useMemoized(AnchoredPopupController.new);
    useEffect(() => popup.dispose, [popup]);
    useListenable(popup);
    final tapGroup = useMemoized(Object.new);
    final fieldKey = useGlobalKey();
    final toggleFocusNode = useFocusNode(
      canRequestFocus: false,
      skipTraversal: true,
    );
    // What the user typed since the choices opened; null shows them all.
    final query = useState<String?>(null);
    final highlighted = useState<int?>(null);

    final shown = useMemoized(() {
      final typed = query.value?.toLowerCase();
      if (!enableFilter || typed == null || typed.isEmpty) {
        return dropdownMenuEntries;
      }
      return dropdownMenuEntries
          .where((entry) => entry.label.toLowerCase().contains(typed))
          .toList();
    }, [dropdownMenuEntries, query.value, enableFilter]);

    void open() {
      if (!enabled) return;
      if (!popup.isOpen) {
        query.value = null;
        final index = dropdownMenuEntries.indexWhere(
          (entry) => entry.value == selected,
        );
        highlighted.value = index < 0 ? null : index;
      }
      popup.preview();
    }

    void close() {
      popup.close();
      query.value = null;
    }

    void typed(String text) {
      query.value = text;
      final lower = text.toLowerCase();
      final entries = enableFilter && lower.isNotEmpty
          ? dropdownMenuEntries
                .where((entry) => entry.label.toLowerCase().contains(lower))
                .toList()
          : dropdownMenuEntries;
      final starts = entries.indexWhere(
        (entry) => entry.enabled && entry.label.toLowerCase().startsWith(lower),
      );
      final first = starts >= 0
          ? starts
          : entries.indexWhere(
              (entry) =>
                  entry.enabled && entry.label.toLowerCase().contains(lower),
            );
      highlighted.value = lower.isEmpty || first < 0 ? null : first;
      popup.preview();
    }

    void move(int step) {
      if (!popup.isOpen || shown.none((entry) => entry.enabled)) return;
      var index = highlighted.value ?? (step > 0 ? -1 : 0);
      do {
        index = (index + step) % shown.length;
      } while (!shown[index].enabled);
      highlighted.value = index;
    }

    void choose(T? value) {
      if (value == null &&
          onCustomValue != null &&
          controller.text.isNotEmpty) {
        onCustomValue!(controller.text);
      } else {
        onSelected?.call(value);
      }
      if (value != null) {
        final label = dropdownMenuEntries
            .firstWhereOrNull((entry) => entry.value == value)
            ?.label;
        if (label != null) controller.text = label;
        inputFieldController.endInteraction();
      }
      close();
      if (focusNode.hasFocus) {
        inputFieldController.requestSurroundingFocus();
      }
    }

    void enter() {
      if (!popup.isOpen) return;
      final index = highlighted.value;
      if (index != null && index < shown.length && shown[index].enabled) {
        choose(shown[index].value);
      } else if (onCustomValue != null && controller.text.isNotEmpty) {
        choose(null);
      }
    }

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
        close();
        controller.text = currentLabel ?? "";
      }
    }, [currentLabel]);

    final width = switch (fieldKey.currentContext?.findRenderObject()) {
      final RenderBox box when box.hasSize => box.size.width,
      _ => 0.0,
    };
    final constraints = popupConstraints;
    Widget field = TextField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      enabled: enabled,
      groupId: tapGroup,
      style: textStyle,
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: leadingIcon,
        suffixIcon: Padding(
          padding: inputDecorationTheme?.data.isCollapsed == true
              ? EdgeInsets.zero
              : EdgeInsets.all(context.spacing.space1),
          child: Button(
            face: ButtonFace.icon,
            focusNode: toggleFocusNode,
            label: popup.isOpen ? "Close choices" : "Open choices",
            tooltip: popup.isOpen ? "Close choices" : "Open choices",
            icon: popup.isOpen
                ? const Icon(Icons.arrow_drop_up)
                : trailingIcon ?? const Icon(Icons.arrow_drop_down),
            onPressed: !enabled
                ? null
                : () {
                    if (popup.isOpen) {
                      close();
                      inputFieldController.endInteraction();
                    } else {
                      inputFieldController.beginInteraction();
                    }
                  },
          ),
        ),
      ),
      onChanged: typed,
      onEditingComplete: enter,
      onTap: enabled ? open : null,
    );
    if (inputDecorationTheme case final theme?) {
      field = Theme(
        data: context.theme.copyWith(inputDecorationTheme: theme.data),
        child: field,
      );
    }

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
        onInputFocus: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && enabled && focusNode.hasPrimaryFocus) {
              open();
            }
          });
        },
        onDismiss: () {
          close();
          if (focusNode.hasFocus) {
            inputFieldController.requestSurroundingFocus();
          }
        },
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
        // The dismiss intent goes to the container from above the popup,
        // whose RawMenuAnchor would only close the menu.
        child: Builder(
          builder: (containerContext) => AnchoredPopup(
            controller: popup,
            // Focus stays in the field, which filters and holds the keys.
            opensOnHover: false,
            minWidth: max(width, constraints?.minWidth ?? 0),
            maxWidth: constraints?.maxWidth ?? max(width, 112),
            maxHeight: menuHeight ?? constraints?.maxHeight ?? 420,
            color: popupColor,
            shape: popupShape,
            popupBuilder: (context, _) => TapRegion(
              groupId: tapGroup,
              child: SingleChildScrollView(
                padding: popupPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, entry) in shown.indexed)
                      PanelMenuItem(
                        label: entry.label,
                        leading: entry.leading,
                        trailing: entry.trailing,
                        enabled: entry.enabled,
                        highlighted: highlighted.value == index,
                        onPressed: () => choose(entry.value),
                        child: entry.content,
                      ),
                  ],
                ),
              ),
            ),
            builder: (context, show) => Actions(
              actions: {
                _MoveIntent: CallbackAction<_MoveIntent>(
                  onInvoke: (intent) {
                    move(intent.step);
                    return null;
                  },
                ),
                _ChooseIntent: CallbackAction<_ChooseIntent>(
                  onInvoke: (_) {
                    enter();
                    return null;
                  },
                ),
              },
              child: Shortcuts(
                shortcuts: {
                  for (final shortcut
                      in shortcutsForIntent<DirectionalFocusIntent>(
                        (intent) => intent.direction == TraversalDirection.up,
                      ))
                    shortcut: const _MoveIntent(-1),
                  for (final shortcut
                      in shortcutsForIntent<DirectionalFocusIntent>(
                        (intent) => intent.direction == TraversalDirection.down,
                      ))
                    shortcut: const _MoveIntent(1),
                  const SingleActivator(LogicalKeyboardKey.enter):
                      const _ChooseIntent(),
                  const SingleActivator(LogicalKeyboardKey.numpadEnter):
                      const _ChooseIntent(),
                },
                child: HookBuilder(
                  builder: (_) {
                    // Dispatch the panel's dismiss intent at the input node so
                    // closing the menu also ends this field's insert interaction.
                    useEffect(() {
                      final previous = focusNode.onKeyEvent;
                      KeyEventResult handleKey(FocusNode node, KeyEvent event) {
                        final result =
                            previous?.call(node, event) ??
                            KeyEventResult.ignored;
                        if (result != KeyEventResult.ignored) return result;
                        if (node.hasPrimaryFocus &&
                            shortcutsFor(DismissIntent).any(
                              (shortcut) => shortcut.accepts(
                                event,
                                HardwareKeyboard.instance,
                              ),
                            )) {
                          Actions.invoke(
                            containerContext,
                            const DismissIntent(),
                          );
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      }

                      focusNode.onKeyEvent = handleKey;
                      return () {
                        if (focusNode.onKeyEvent == handleKey) {
                          focusNode.onKeyEvent = previous;
                        }
                      };
                    }, [focusNode]);
                    return field;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.step);
  final int step;
}

class _ChooseIntent extends Intent {
  const _ChooseIntent();
}
