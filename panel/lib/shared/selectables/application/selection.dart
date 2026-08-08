import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "selection.g.dart";

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

  void selectAll(
    List<SelectableIdentifier> selectables, {
    bool replaceCurrentSelection = true,
  }) {
    state = replaceCurrentSelection ? selectables : [...state, ...selectables];
  }

  void unselect(SelectableIdentifier selectable) {
    state = state.where((s) => s != selectable).toList();
  }

  void unselectAll(List<SelectableIdentifier> selectables) {
    state = state.where((s) => !selectables.contains(s)).toList();
  }

  void clear() {
    state = [];
  }
}

@riverpod
bool hasSelection(Ref ref) {
  return ref.watch(selectionProvider).isNotEmpty;
}

@riverpod
bool isSelected(Ref ref, SelectableIdentifier selectable) {
  return ref.watch(selectionProvider).contains(selectable);
}

@riverpod
class Selected extends _$Selected {
  @override
  AsyncValue<List<Selectable<SelectableIdentifier>>> build() {
    final ids = ref.watch(selectionProvider);

    final values = <Selectable>[];
    for (final id in ids) {
      final value = id.create(ref);
      if (!value.hasValue) {
        return value.whenData((_) => []);
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
    // return true;
    return !previous.matches(next, listEquals);
  }
}

class SelectableNotFoundException implements Exception {
  SelectableNotFoundException(this.id);

  final SelectableIdentifier id;
}
