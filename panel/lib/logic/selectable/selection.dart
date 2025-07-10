import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/collection.dart";

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
    return !listEquals(previous, next);
  }

  void select(SelectableIdentifier selectable) {
    final selected = state.contains(selectable);
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    state = switch ((selected, isShiftPressed)) {
      (true, true) => state.where((s) => s != selectable).toList(),
      (true, false) => state.length > 1 ? [selectable] : [],
      (false, true) => [...state, selectable],
      (false, false) => [selectable],
    };
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
  Future<List<Selectable>> build() async {
    final ids = ref.watch(selectionProvider);
    return Future.wait(ids.map((id) async => id.create(ref)));
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<Selectable>> previous,
    AsyncValue<List<Selectable>> next,
  ) {
    if (previous.runtimeType != next.runtimeType) return true;
    if (previous.hasValue && next.hasValue) {
      return !listEquals(previous.value, next.value);
    }
    if (previous.hasError && next.hasError) {
      return previous.error != next.error;
    }
    return false;
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
