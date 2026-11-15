import "package:typewriter_panel/typewriter_panel.dart";

part "selection.g.dart";

/// Owns the canonical ordered list of selected identifiers.
///
/// Selection is independent from keyboard focus. Focus identifies the item
/// receiving keyboard input, while this provider represents the items acted on
/// by the inspector and batch operations. Widgets mutate this state through
/// the methods below; resolved selectable objects are derived by [Selected],
/// and whether items show their checks by [SelectMode].
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

  /// The item the next range starts from: the last item chosen plainly or
  /// toggled.
  SelectableIdentifier? _anchor;

  /// What stays selected beside a range: the selection when the anchor was
  /// set, without the anchor itself.
  List<SelectableIdentifier> _base = const [];

  /// Selects only [selectable], the way a plain click does to inspect it,
  /// and ends select mode.
  void selectOnly(SelectableIdentifier selectable) {
    _anchor = selectable;
    _base = const [];
    _set([selectable], selecting: false);
  }

  /// Selects only [selectable], as [selectOnly] does, and lands keyboard
  /// focus on its row once a surface shows it, such as a search result
  /// chosen on another page.
  void reveal(SelectableIdentifier selectable) {
    selectOnly(selectable);
    ref.read(selectionLandingProvider.notifier)._target = selectable;
  }

  /// Adds [selectable] when it is not selected and removes it when it is,
  /// keeping the rest, and shows the checks of select mode.
  void toggle(SelectableIdentifier selectable) {
    final next = state.contains(selectable)
        ? state.where((s) => s != selectable).toList()
        : [...state, selectable];
    _anchor = selectable;
    _base = next.where((s) => s != selectable).toList();
    _set(next, selecting: true);
  }

  /// Selects every item of [order] from the anchor to [to], beside what was
  /// selected when the anchor was set, and shows the checks of select mode.
  ///
  /// [order] is the surface's visible order. When the anchor is not on that
  /// surface, the range starts from [from], the item focus left, or else
  /// from [to] itself, and replaces the selection.
  void selectRange(
    SelectableIdentifier to, {
    required List<SelectableIdentifier> order,
    SelectableIdentifier? from,
  }) {
    if (!order.contains(_anchor)) {
      _anchor = from ?? to;
      _base = const [];
    }
    final start = order.indexOf(_anchor!);
    final end = order.indexOf(to);
    final range = start < 0 || end < 0
        ? [to]
        : order.sublist(min(start, end), max(start, end) + 1);
    _set([
      for (final item in _base)
        if (!range.contains(item)) item,
      ...range,
    ], selecting: true);
  }

  /// Selects every item of [order], one surface in its visible order, and
  /// shows the checks of select mode; with all of them selected already it
  /// clears the selection instead.
  void selectEvery(List<SelectableIdentifier> order) {
    if (order.isNotEmpty && order.every(state.contains)) {
      clear();
      return;
    }
    _set(order, selecting: true);
  }

  /// Replaces the selection with [selectables], or appends them when
  /// [replaceCurrentSelection] is false. Replacing ends select mode, as
  /// choosing one item to inspect does.
  void selectAll(
    List<SelectableIdentifier> selectables, {
    bool replaceCurrentSelection = true,
  }) {
    _set(
      replaceCurrentSelection ? selectables : [...state, ...selectables],
      selecting: replaceCurrentSelection ? false : null,
    );
  }

  /// Removes [selectable] if it is currently selected.
  void unselect(SelectableIdentifier selectable) {
    _set(state.where((s) => s != selectable).toList());
  }

  /// Removes every identifier in [selectables] from the current selection.
  void unselectAll(List<SelectableIdentifier> selectables) {
    _set(state.where((s) => !selectables.contains(s)).toList());
  }

  /// Clears all selected identifiers without changing focus.
  void clear() {
    _set(const []);
  }

  /// Every change goes through here, so an empty selection always ends
  /// select mode; [selecting] starts or ends it, and null keeps it.
  void _set(List<SelectableIdentifier> next, {bool? selecting}) {
    state = next;
    if (next.isEmpty) {
      _anchor = null;
      _base = const [];
    }
    ref.read(selectModeProvider.notifier)._follow(next, selecting: selecting);
  }
}

/// Whether the selection is in select mode, so the selectables of every
/// surface holding a selected item show their check.
///
/// An add gesture (Space, a Command or Control click, a Shift click, Shift
/// with an arrow, select all) starts it. A plain click, which selects one
/// item to inspect it, ends it, and so does an empty selection. Only
/// [Selection] changes it.
@riverpod
class SelectMode extends _$SelectMode {
  @override
  bool build() {
    return false;
  }

  /// Follows the selection becoming [selection]: [selecting] starts or ends
  /// select mode, null keeps it, and an empty selection always ends it.
  void _follow(List<SelectableIdentifier> selection, {bool? selecting}) {
    state = selection.isNotEmpty && (selecting ?? state);
  }
}

/// The item whose row takes keyboard focus the next time a surface shows
/// it, or null. [Selection.reveal] requests it; the [Selector] of that item
/// takes it once its route is current, and then it is cleared. Kept alive,
/// as the request outlives the search that made it until the page shows.
@Riverpod(keepAlive: true)
class SelectionLanding extends _$SelectionLanding {
  @override
  SelectableIdentifier? build() {
    return null;
  }

  SelectableIdentifier? get _target => state;
  set _target(SelectableIdentifier? selectable) => state = selectable;

  /// Clears the request when it is still for [selectable], as its row took
  /// focus.
  void take(SelectableIdentifier selectable) {
    if (_target == selectable) _target = null;
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
