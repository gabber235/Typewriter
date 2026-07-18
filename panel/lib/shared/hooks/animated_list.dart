import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Builds an item while it is being removed from an animated list or grid.
typedef AnimatedListRemovedItemBuilder<T> =
    Widget Function(BuildContext context, T item, Animation<double> animation);

/// The key and synchronized item snapshot managed by an animated collection hook.
///
/// Assign [key] to the matching animated collection. Use [items] for both its
/// initial item count and item builder so Flutter and the backing data retain
/// matching indices throughout structural animations.
class AnimatedListHookResult<T, S extends State<StatefulWidget>> {
  const AnimatedListHookResult({required this.key, required this.items});

  /// The key to assign to the matching animated list or grid widget.
  final GlobalKey<S> key;

  /// The item snapshot to use in the widget builder and initial item count.
  final List<T> items;
}

/// Synchronizes [items] with an [AnimatedList].
///
/// [identity] must return a stable, unique value for every item.
AnimatedListHookResult<T, AnimatedListState> useAnimatedList<T>({
  required List<T> items,
  required Object Function(T item) identity,
  required AnimatedListRemovedItemBuilder<T> removedItemBuilder,
  Duration insertDuration = const Duration(milliseconds: 750),
  Duration removeDuration = const Duration(milliseconds: 500),
  String? debugLabel,
}) {
  return use(
    _AnimatedListHook<T, AnimatedListState>(
      items: items,
      identity: identity,
      removedItemBuilder: removedItemBuilder,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      debugLabel: debugLabel,
      insertItem: (state, index, duration) {
        state.insertItem(index, duration: duration);
      },
      removeItem: (state, index, builder, duration) {
        state.removeItem(index, builder, duration: duration);
      },
    ),
  );
}

/// Synchronizes [items] with a [SliverAnimatedList].
///
/// [identity] must return a stable, unique value for every item.
AnimatedListHookResult<T, SliverAnimatedListState> useSliverAnimatedList<T>({
  required List<T> items,
  required Object Function(T item) identity,
  required AnimatedListRemovedItemBuilder<T> removedItemBuilder,
  Duration insertDuration = const Duration(milliseconds: 300),
  Duration removeDuration = const Duration(milliseconds: 300),
  String? debugLabel,
}) {
  return use(
    _AnimatedListHook<T, SliverAnimatedListState>(
      items: items,
      identity: identity,
      removedItemBuilder: removedItemBuilder,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      debugLabel: debugLabel,
      insertItem: (state, index, duration) {
        state.insertItem(index, duration: duration);
      },
      removeItem: (state, index, builder, duration) {
        state.removeItem(index, builder, duration: duration);
      },
    ),
  );
}

/// Synchronizes [items] with an [AnimatedGrid].
///
/// [identity] must return a stable, unique value for every item.
AnimatedListHookResult<T, AnimatedGridState> useAnimatedGrid<T>({
  required List<T> items,
  required Object Function(T item) identity,
  required AnimatedListRemovedItemBuilder<T> removedItemBuilder,
  Duration insertDuration = const Duration(milliseconds: 300),
  Duration removeDuration = const Duration(milliseconds: 300),
  String? debugLabel,
}) {
  return use(
    _AnimatedListHook<T, AnimatedGridState>(
      items: items,
      identity: identity,
      removedItemBuilder: removedItemBuilder,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      debugLabel: debugLabel,
      insertItem: (state, index, duration) {
        state.insertItem(index, duration: duration);
      },
      removeItem: (state, index, builder, duration) {
        state.removeItem(index, builder, duration: duration);
      },
    ),
  );
}

/// Synchronizes [items] with a [SliverAnimatedGrid].
///
/// [identity] must return a stable, unique value for every item.
AnimatedListHookResult<T, SliverAnimatedGridState> useSliverAnimatedGrid<T>({
  required List<T> items,
  required Object Function(T item) identity,
  required AnimatedListRemovedItemBuilder<T> removedItemBuilder,
  Duration insertDuration = const Duration(milliseconds: 300),
  Duration removeDuration = const Duration(milliseconds: 300),
  String? debugLabel,
}) {
  return use(
    _AnimatedListHook<T, SliverAnimatedGridState>(
      items: items,
      identity: identity,
      removedItemBuilder: removedItemBuilder,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      debugLabel: debugLabel,
      insertItem: (state, index, duration) {
        state.insertItem(index, duration: duration);
      },
      removeItem: (state, index, builder, duration) {
        state.removeItem(index, builder, duration: duration);
      },
    ),
  );
}

typedef _InsertItem<S extends State<StatefulWidget>> =
    void Function(S state, int index, Duration duration);

typedef _RemoveItem<S extends State<StatefulWidget>> =
    void Function(
      S state,
      int index,
      AnimatedRemovedItemBuilder builder,
      Duration duration,
    );

class _AnimatedListHook<T, S extends State<StatefulWidget>>
    extends Hook<AnimatedListHookResult<T, S>> {
  const _AnimatedListHook({
    required this.items,
    required this.identity,
    required this.removedItemBuilder,
    required this.insertDuration,
    required this.removeDuration,
    required this.insertItem,
    required this.removeItem,
    this.debugLabel,
  });

  final List<T> items;
  final Object Function(T item) identity;
  final AnimatedListRemovedItemBuilder<T> removedItemBuilder;
  final Duration insertDuration;
  final Duration removeDuration;
  final _InsertItem<S> insertItem;
  final _RemoveItem<S> removeItem;
  final String? debugLabel;

  @override
  _AnimatedListHookState<T, S> createState() => _AnimatedListHookState<T, S>();
}

class _AnimatedListHookState<T, S extends State<StatefulWidget>>
    extends HookState<AnimatedListHookResult<T, S>, _AnimatedListHook<T, S>> {
  late final GlobalKey<S> _key;
  late List<T> _items;
  late List<Object> _identities;

  @override
  void initHook() {
    super.initHook();
    final snapshot = _snapshot(hook.items, hook.identity);
    _validateUnique(snapshot.identities);
    _key = GlobalKey<S>(debugLabel: hook.debugLabel);
    _items = snapshot.items;
    _identities = snapshot.identities;
  }

  @override
  void didUpdateHook(_AnimatedListHook<T, S> oldHook) {
    super.didUpdateHook(oldHook);
    _synchronize();
  }

  void _synchronize() {
    final next = _snapshot(hook.items, hook.identity);
    _validateUnique(next.identities);

    final state = _key.currentState;
    if (state == null) {
      _items = next.items;
      _identities = next.identities;
      return;
    }

    final stableIdentities = _longestCommonSubsequence(
      _identities,
      next.identities,
    ).toSet();
    final removedItemBuilder = hook.removedItemBuilder;

    for (var index = _items.length - 1; index >= 0; index--) {
      if (stableIdentities.contains(_identities[index])) continue;

      final removedItem = _items.removeAt(index);
      _identities.removeAt(index);
      hook.removeItem(state, index, (context, animation) {
        return removedItemBuilder(context, removedItem, animation);
      }, hook.removeDuration);
    }

    for (var index = 0; index < next.items.length; index++) {
      if (stableIdentities.contains(next.identities[index])) continue;

      _items.insert(index, next.items[index]);
      _identities.insert(index, next.identities[index]);
      hook.insertItem(state, index, hook.insertDuration);
    }

    _items = next.items;
    _identities = next.identities;
    assert(_items.length == _identities.length);
  }

  @override
  AnimatedListHookResult<T, S> build(BuildContext context) {
    return AnimatedListHookResult(key: _key, items: List.unmodifiable(_items));
  }

  @override
  String get debugLabel => "useAnimatedList";
}

({List<T> items, List<Object> identities}) _snapshot<T>(
  List<T> source,
  Object Function(T item) identity,
) {
  final items = List<T>.of(source);
  return (items: items, identities: items.map(identity).toList());
}

void _validateUnique(List<Object> identities) {
  final seen = <Object>{};
  for (final identity in identities) {
    if (seen.add(identity)) continue;
    throw ArgumentError.value(
      identity,
      "items",
      "Animated list item identities must be unique",
    );
  }
}

List<Object> _longestCommonSubsequence(
  List<Object> previous,
  List<Object> next,
) {
  final lengths = List.generate(
    previous.length + 1,
    (_) => List.filled(next.length + 1, 0),
  );

  for (
    var previousIndex = previous.length - 1;
    previousIndex >= 0;
    previousIndex--
  ) {
    for (var nextIndex = next.length - 1; nextIndex >= 0; nextIndex--) {
      if (previous[previousIndex] == next[nextIndex]) {
        lengths[previousIndex][nextIndex] =
            lengths[previousIndex + 1][nextIndex + 1] + 1;
      } else {
        lengths[previousIndex][nextIndex] =
            lengths[previousIndex + 1][nextIndex] >=
                lengths[previousIndex][nextIndex + 1]
            ? lengths[previousIndex + 1][nextIndex]
            : lengths[previousIndex][nextIndex + 1];
      }
    }
  }

  final stableIdentities = <Object>[];
  var previousIndex = 0;
  var nextIndex = 0;
  while (previousIndex < previous.length && nextIndex < next.length) {
    if (previous[previousIndex] == next[nextIndex]) {
      stableIdentities.add(previous[previousIndex]);
      previousIndex++;
      nextIndex++;
    } else if (lengths[previousIndex + 1][nextIndex] >=
        lengths[previousIndex][nextIndex + 1]) {
      previousIndex++;
    } else {
      nextIndex++;
    }
  }

  return stableIdentities;
}
