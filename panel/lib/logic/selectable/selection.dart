import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "selection.freezed.dart";
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

// ignore: prefer_mixin
class SelectionMock extends _$Selection with Mock implements Selection {}

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

  void updateFieldValue(String path, dynamic value) {
    final selectables = state.requireValue;
    for (final selectable in selectables) {
      selectable.setFieldValue(path, value);
    }
  }
}

@riverpod
SelectedValue fieldValue(Ref ref, String path) {
  final selected = ref.watch(selectedProvider).value;
  if (selected == null) return SelectedValue.loading();
  if (selected.isEmpty) return SelectedValue.none();
  final values = selected.map((s) => s.fieldValue(path)).toList();
  if (values.length == 1) return SelectedValue.from(values.first);

  for (final i in values.indices) {
    if (values[i] != values.first) return SelectedValue.conflict();
  }
  return SelectedValue.from(values.first);
}

@freezed
sealed class SelectedValue with _$SelectedValue {
  /// When the value is being loaded.
  const factory SelectedValue.loading() = LoadingValue;

  /// When there is one value.
  const factory SelectedValue.value(dynamic value) = Value;

  /// When multiple selections are active, and they have different values.
  const factory SelectedValue.conflict() = ConflictValue;

  /// When there is no value.
  const factory SelectedValue.none() = NoneValue;

  // ignore: prefer_constructors_over_static_methods
  static SelectedValue from(dynamic value) {
    if (value == null) return SelectedValue.none();
    return SelectedValue.value(value);
  }
}

extension SelectedValueExtension on SelectedValue {
  dynamic value(dynamic defaultValue) {
    return switch (this) {
      Value(:final value) => value,
      ConflictValue() => defaultValue,
      NoneValue() => defaultValue,
      LoadingValue() => defaultValue,
    };
  }
}

@riverpod
ObjectBlueprint? selectedDataBlueprint(Ref ref) {
  final selected = ref.watch(selectedProvider).value;
  if (selected == null) return null;
  if (selected.isEmpty) return null;
  return selected.map((s) => s.objectBlueprint).toList().overlap;
}

@riverpod
Widget? selectedHeader(Ref ref) {
  final selected = ref.watch(selectedProvider).value;
  if (selected == null) return null;
  if (selected.isEmpty) return null;
  if (selected.length > 1) return null;
  return selected.first.header();
}

class SelectableNotFoundException implements Exception {
  SelectableNotFoundException(this.id);

  final SelectableIdentifier id;
}
