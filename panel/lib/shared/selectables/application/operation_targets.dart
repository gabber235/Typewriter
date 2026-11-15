import "package:typewriter_panel/typewriter_panel.dart";

part "operation_targets.g.dart";

/// The items an operation acts on, given the [selection] and the [focused]
/// item: the selection when it holds the focused item, otherwise the focused
/// item alone. Without a focused item, the selection.
///
/// Keys, the context menu and the inspector all take their targets from
/// this one rule; the inspector has no focused item, so it acts on the
/// selection it shows.
List<SelectableIdentifier> operationTargetIds(
  List<SelectableIdentifier> selection, {
  required SelectableIdentifier? focused,
}) {
  if (focused == null || selection.contains(focused)) return selection;
  return [focused];
}

/// The item whose row holds keyboard focus, or null while focus is outside
/// every selectable item, such as in the inspector or a field.
@riverpod
class FocusedSelectable extends _$FocusedSelectable {
  @override
  SelectableIdentifier? build() {
    void follow() {
      final focused = SelectableScope.primaryFocusedId();
      if (focused != state) state = focused;
    }

    FocusManager.instance.addListener(follow);
    ref.onDispose(() => FocusManager.instance.removeListener(follow));
    return SelectableScope.primaryFocusedId();
  }
}

/// The items an operation's key acts on now, resolved: [operationTargetIds]
/// over the selection and the focused item.
///
/// The selection resolves as [Selected] does; a focused item outside it
/// resolves alone, and one its resource no longer holds is no target.
@riverpod
AsyncValue<List<Selectable>> operationTargets(Ref ref) {
  final selection = ref.watch(selectionProvider);
  final focused = ref.watch(focusedSelectableProvider);
  final ids = operationTargetIds(selection, focused: focused);
  // The rule hands the selection back as it is when it acts on it.
  if (identical(ids, selection)) return ref.watch(selectedProvider);
  final resolution = ref.watch(selectableResolutionProvider(ids.single));
  if (resolution.error is SelectableNotFoundException) {
    return const AsyncData([]);
  }
  if (resolution.mapUnready<List<Selectable>>() case final unready?) {
    return unready;
  }
  return AsyncData([resolution.requireValue]);
}
