part of "multiselect_dropdown.dart";

class _MultiselectDropdownController<T extends Object> {
  const _MultiselectDropdownController({
    required this.dropdown,
    required this.popupController,
    required this.anchorKey,
    required this.inputFieldController,
    required this.textController,
    required this.filteredEntries,
    required this.fakeFocusIndex,
    required this.isCollapsed,
    required this.tapGroup,
  });

  final MultiselectDropdown<T> dropdown;
  final AnchoredPopupController popupController;
  final GlobalKey anchorKey;
  final InputFieldController inputFieldController;
  final _MultiSelectTextEditingController textController;
  final List<MenuChoice<T>> filteredEntries;
  final ValueNotifier<int?> fakeFocusIndex;
  final bool isCollapsed;

  /// Joins the field and its choices, so a tap on a choice keeps the field.
  final Object tapGroup;

  /// The field's width, which the choices match.
  double get fieldWidth => dropdown.getWidth(anchorKey) ?? _kMinimumWidth;

  /// Shows the choices while focus stays in the field, which filters them.
  void open() => popupController.preview();

  FocusNode get focusNode => inputFieldController.inputFocusNode;
  FocusNode get surroundingFocusNode =>
      inputFieldController.surroundingFocusNode;

  Object? previous() {
    if (!dropdown.enabled ||
        filteredEntries.none((entry) => entry.enabled) ||
        !popupController.isOpen) {
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

  Object? next() {
    if (!dropdown.enabled ||
        filteredEntries.none((entry) => entry.enabled) ||
        !popupController.isOpen) {
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

  void enter() {
    if (!dropdown.enabled ||
        !popupController.isOpen ||
        fakeFocusIndex.value == null) {
      return;
    }
    final entry = filteredEntries[fakeFocusIndex.value!];
    if (entry.enabled) toggle(entry.value);
  }

  void toggle(T item) {
    if (dropdown.selectedItems.contains(item)) {
      dropdown.onSelectionChanged?.call(
        dropdown.selectedItems.where((selected) => selected != item).toList(),
      );
    } else {
      dropdown.onSelectionChanged?.call([...dropdown.selectedItems, item]);
    }
  }

  void openAfterFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.hasPrimaryFocus) open();
    });
  }
}

_MultiselectDropdownController<T> _useMultiselectDropdownController<
  T extends Object
>(BuildContext context, MultiselectDropdown<T> dropdown) {
  final theme = Theme.of(context);
  final popupController = useMemoized(AnchoredPopupController.new);
  useEffect(() => popupController.dispose, [popupController]);
  useListenable(popupController);
  final tapGroup = useMemoized(Object.new);
  final anchorKey = useGlobalKey();
  final randomSeed = useState(random.nextDouble());
  final selected = useMemoized(
    () => dropdown.dropdownMenuEntries
        .where((entry) => dropdown.selectedItems.contains(entry.value))
        .toList(),
    [dropdown.selectedItems],
  );
  final currentLabel = useMemoized(
    () => "${selected.map((entry) => "[${entry.label}]").join()} ",
    [selected],
  );

  Widget buildLabelWidget(BuildContext context, String label) {
    final entry = dropdown.dropdownMenuEntries.firstWhereOrNull(
      (entry) => entry.label == label,
    );
    if (entry != null && dropdown.itemBuilder != null) {
      return dropdown.itemBuilder!(entry.value);
    }
    if (entry?.content != null) return entry!.content!;
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium!
          .copyWith(color: context.colors.brandText),
    );
  }

  void setLabels(List<String> labels) {
    final requiredKeep = dropdown.dropdownMenuEntries
        .where((entry) => dropdown.selectedItems.contains(entry.value))
        .where((entry) => !entry.enabled)
        .map((entry) => entry.value)
        .toList();
    final possibleNew = dropdown.dropdownMenuEntries
        .where((entry) => labels.contains(entry.label))
        .where((entry) => entry.enabled)
        .map((entry) => entry.value)
        .toList();
    dropdown.onSelectionChanged?.call([...requiredKeep, ...possibleNew]);
  }

  final textController = useMultiSelectTextEditingController(
    text: currentLabel,
    labelWidgetBuilder: buildLabelWidget,
    onSetLabels: (labels) {
      setLabels(labels);
      randomSeed.value = random.nextDouble();
    },
  );
  final defaultInputFieldController = useInputFieldController(
    inputDebugLabel: "MultiselectDropdown",
    surroundingDebugLabel: "Surrounding focus node",
  );
  final inputFieldController =
      dropdown.inputFieldController ?? defaultInputFieldController;
  final focusNode = inputFieldController.inputFocusNode;
  // Closing the choices from the field hands focus back to the surrounding
  // field, as leaving the insert interaction does.
  final wasOpen = useRef(false);
  useEffect(() {
    void closed() {
      if (wasOpen.value && !popupController.isOpen && focusNode.hasFocus) {
        inputFieldController.surroundingFocusNode.requestFocus();
      }
      wasOpen.value = popupController.isOpen;
    }

    popupController.addListener(closed);
    return () => popupController.removeListener(closed);
  }, [popupController, focusNode]);

  useEffect(() {
    textController.showLabels(currentLabel);
    return null;
  }, [currentLabel, randomSeed.value]);
  useFocusedChange(focusNode, ({required hasFocus}) {
    if (!hasFocus) textController.text = currentLabel;
  }, [currentLabel]);

  final searchText = useListenableSelector(
    textController,
    MultiselectDropdown.searchTextParser(textController),
  );
  final filteredEntries = useMemoized(
    () => dropdown.dropdownMenuEntries
        .where(
          (item) => item.label.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList(),
    [dropdown.dropdownMenuEntries, searchText],
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

  return _MultiselectDropdownController(
    dropdown: dropdown,
    popupController: popupController,
    anchorKey: anchorKey,
    inputFieldController: inputFieldController,
    textController: textController,
    filteredEntries: filteredEntries,
    fakeFocusIndex: fakeFocusIndex,
    isCollapsed: theme.inputDecorationTheme.isCollapsed,
    tapGroup: tapGroup,
  );
}
