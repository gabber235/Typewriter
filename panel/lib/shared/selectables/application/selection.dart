import "package:typewriter_panel/typewriter_panel.dart";

part "selection.g.dart";

/// Owns the canonical ordered list of selected identifiers.
///
/// Selection is independent from keyboard focus. Focus identifies the item
/// receiving keyboard input, while this provider represents the items acted on
/// by the inspector and batch operations. Widgets mutate this state through
/// the methods below; resolved selectable objects are derived by [Selected].
@riverpod
class Selection extends _$Selection {
  @override
  List<SelectableIdentifier> build() {
    return [];
  }

  @override
  bool updateShouldNotify(
    List<SelectableIdentifier> previous,
    List<SelectableIdentifier> next,
  ) {
    return true;
  }

  /// Toggles [selectable] using single selection or additive selection rules.
  ///
  /// When [isMultiSelect] is omitted, the current Shift key state chooses the
  /// mode. Repeating a sole item in single selection clears it. Repeating an
  /// item in multi selection removes it. The resulting list preserves the
  /// order in which items were added.
  void select(SelectableIdentifier selectable, {bool? isMultiSelect}) {
    final selected = state.contains(selectable);
    final multiSelect =
        isMultiSelect ?? HardwareKeyboard.instance.isShiftPressed;

    state = switch ((selected, multiSelect)) {
      (true, true) => state.where((s) => s != selectable).toList(),
      (true, false) => state.length > 1 ? [selectable] : [],
      (false, true) => [...state, selectable],
      (false, false) => [selectable],
    };
  }

  /// Replaces the selection with [selectables], or appends them when
  /// [replaceCurrentSelection] is false.
  void selectAll(
    List<SelectableIdentifier> selectables, {
    bool replaceCurrentSelection = true,
  }) {
    state = replaceCurrentSelection ? selectables : [...state, ...selectables];
  }

  /// Removes [selectable] if it is currently selected.
  void unselect(SelectableIdentifier selectable) {
    state = state.where((s) => s != selectable).toList();
  }

  /// Removes every identifier in [selectables] from the current selection.
  void unselectAll(List<SelectableIdentifier> selectables) {
    state = state.where((s) => !selectables.contains(s)).toList();
  }

  /// Clears all selected identifiers without changing focus.
  void clear() {
    state = [];
  }
}

/// Whether at least one identifier is selected.
@riverpod
bool hasSelection(Ref ref) {
  return ref.watch(selectionProvider).isNotEmpty;
}

/// Whether [selectable] is in the canonical selection.
@riverpod
bool isSelected(Ref ref, SelectableIdentifier selectable) {
  return ref.watch(selectionProvider).contains(selectable);
}

/// Resolves the canonical identifier selection into current selectable objects.
///
/// This provider is the boundary between selection state and resource state.
/// It preserves the order of [selectionProvider], returns loading or error
/// state when any identifier cannot resolve, and publishes a complete list
/// only after every identifier has resolved.
@riverpod
class Selected extends _$Selected {
  @override
  AsyncValue<List<Selectable<SelectableIdentifier>>> build() {
    final ids = ref.watch(selectionProvider);

    final values = <Selectable>[];
    for (final id in ids) {
      final value = id.create(ref);
      if (value.mapUnready<List<Selectable<SelectableIdentifier>>>()
          case final v?) {
        return v;
      }
      values.add(value.requireValue);
    }
    return AsyncData(values);
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<Selectable<SelectableIdentifier>>> previous,
    AsyncValue<List<Selectable<SelectableIdentifier>>> next,
  ) {
    return !previous.matches(next, listEquals);
  }
}

/// Failure returned when a selected identifier no longer resolves to an item.
class SelectableNotFoundException implements Exception {
  SelectableNotFoundException(this.id);

  final SelectableIdentifier id;
}
