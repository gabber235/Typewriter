import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/hooks/delayed_execution.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/shortuct.dart";
import "package:typewriter_panel/widgets/generic/components/shortcut_display.dart";

part "action_shortcuts.freezed.dart";
part "action_shortcuts.g.dart";

typedef ActionInvoke = FutureOr<void> Function(WidgetRef ref);

@freezed
abstract class ActionShortcut with _$ActionShortcut {
  const factory ActionShortcut({
    required String id,
    required String label,
    required String description,
    required List<ShortcutActivator> activators,
    required int priority,
    Widget? icon,
    ActionInvoke? onInvoke,
    GlobalKey? owner,
  }) = _ActionShortcut;
}

@riverpod
class ActionShortcuts extends _$ActionShortcuts {
  @override
  Map<String, ActionShortcut> build() => {};

  void register(GlobalKey key, List<ActionShortcut> shortcuts) {
    final updated = Map<String, ActionShortcut>.from(state)
      // We know every shortcut that was managed by this global key is now invalid.
      ..removeWhere((id, shortcut) => shortcut.owner == key);

    if (shortcuts.isEmpty) {
      state = updated;
      return;
    }

    for (final shortcut in shortcuts) {
      final withOwner = shortcut.copyWith(owner: key);
      final current = updated[withOwner.id];
      if (current == null || withOwner.priority >= current.priority) {
        updated[withOwner.id] = withOwner;
      }
    }

    state = updated;
  }

  void sweep() {
    if (state.isEmpty) return;
    final updated = Map<String, ActionShortcut>.from(state)
      ..removeWhere(
        (id, shortcut) =>
            shortcut.owner != null && shortcut.owner!.currentContext == null,
      );
    state = updated;
  }

  @override
  bool updateShouldNotify(
    Map<String, ActionShortcut> previous,
    Map<String, ActionShortcut> next,
  ) {
    return !mapEquals(previous, next);
  }
}

class GlobalActionsManager extends HookConsumerWidget {
  const GlobalActionsManager({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(actionShortcutsProvider);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(actionShortcutsProvider.notifier).sweep();
      });
      return null;
    });
    return child;
  }
}

class ManagedActionSet extends HookConsumerWidget {
  const ManagedActionSet({
    required this.shortcuts,
    this.child,
    super.key,
  });
  final List<ActionShortcut> shortcuts;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regKey = useGlobalKey(debugLabel: "ShortcutActionSet");
    final callableShortcuts = useMemoized(
      () => shortcuts
          .where((s) => s.onInvoke != null && s.activators.isNotEmpty)
          .toList(),
      [shortcuts],
    );
    final hasFocus = useState(false);
    return CallbackShortcuts(
      key: regKey,
      bindings: {
        if (hasFocus.value)
          for (final action in callableShortcuts)
            for (final activator in action.activators)
              activator: () => action.onInvoke!.call(ref),
      },
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (focus) => hasFocus.value = focus,
        child: ActionSet(
          shortcuts: hasFocus.value ? shortcuts : [],
          child: child,
        ),
      ),
    );
  }
}

class ActionSet extends HookConsumerWidget {
  const ActionSet({
    required this.shortcuts,
    this.child,
    super.key,
  });
  final List<ActionShortcut> shortcuts;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regKey = useGlobalKey(debugLabel: "ActionSet");
    useDelayedExecution(
      () {
        if (!context.mounted) return;
        ref.read(actionShortcutsProvider.notifier).register(regKey, shortcuts);
      },
      [regKey, shortcuts],
    );
    return KeyedSubtree(
      key: regKey,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class ActionRow extends HookConsumerWidget {
  const ActionRow({
    this.spacing = 0,
    super.key,
  });

  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsMap = ref.watch(actionShortcutsProvider);
    if (context.isMobile || actionsMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final actions = useMemoized(
      () {
        final filtered = actionsMap.values
            .where((a) => a.owner == null || a.owner!.currentContext != null)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
        return filtered;
      },
      [actionsMap],
    );

    final ids = actions.map((a) => a.id).toList();
    final keysMap = useRef<Map<String, GlobalKey>>({});
    final widths = useRef<Map<String, double>>({});
    final visibleCountState = useState<int?>(null);

    for (final id in ids) {
      keysMap.value.putIfAbsent(id, () => GlobalKey(debugLabel: "Action-$id"));
    }
    keysMap.value.removeWhere((id, _) => !ids.contains(id));

    void measureAndResolve(BoxConstraints constraints) {
      final maxWidth = constraints.maxWidth.isInfinite
          ? MediaQuery.of(context).size.width - 10
          : constraints.maxWidth - 10;

      for (final id in ids) {
        final key = keysMap.value[id]!;
        final ctx = key.currentContext;
        if (ctx == null) {
          return;
        }
        final renderBox = ctx.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) {
          return;
        }
        widths.value[id] = renderBox.size.width;
      }

      final orderedWidths = ids.map((id) => widths.value[id] ?? 0).toList();
      // Binary search on how many actions we can show (highest priority preserved).
      final n = orderedWidths.length;
      var low = 1;
      var high = n;
      var best = 0;
      double spacingSum(int count) => count <= 1 ? 0 : spacing * (count - 1);

      bool fits(int count) {
        if (count <= 0) return true;
        // Show last count actions (highest priorities)
        final start = n - count;
        var total = spacingSum(count);
        for (var i = start; i < n; i++) {
          total += orderedWidths[i];
          if (total > maxWidth) return false;
        }
        return total <= maxWidth;
      }

      while (low <= high) {
        final mid = (low + high) >> 1;
        if (fits(mid)) {
          best = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }
      visibleCountState.value = best;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) => HookBuilder(
          builder: (context) {
            useEffect(
              () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  measureAndResolve(constraints);
                });
                return null;
              },
              [actionsMap, actions.length, constraints.maxWidth],
            );

            final visibleCount = visibleCountState.value;

            final toShow = visibleCount != null
                ? actions.sublist(max(0, actions.length - visibleCount))
                : <ActionShortcut>[];

            return Column(
              children: [
                // Always-present hidden full row for stable measurement
                Offstage(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: spacing,
                    children: [
                      for (final action in actions)
                        TickerMode(
                          enabled: false,
                          child: KeyedSubtree(
                            key: keysMap.value[action.id],
                            child: _ActionShortcutButton(
                              action: action,
                              forceLargest: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: spacing,
                    alignment: WrapAlignment.end,
                    children: [
                      for (final action in toShow)
                        _ActionShortcutButton(
                          action: action,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionShortcutButton extends HookConsumerWidget {
  const _ActionShortcutButton({
    required this.action,
    this.forceLargest = false,
  });

  final ActionShortcut action;
  final bool forceLargest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);
    final hasInvoke = action.onInvoke != null && !loading.value;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (loading.value)
          const SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (action.icon != null)
          action.icon!,
        Flexible(
          child: Text(
            action.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        RotatingShortcuts(
          shortcuts: forceLargest && action.activators.isNotEmpty
              ? [action.activators.maxByOrNull((a) => a.length)!]
              : action.activators,
          size: 9,
          interval: 5.seconds,
        ),
      ],
    );

    final pill = AnimatedOpacity(
      duration: 150.ms,
      opacity: loading.value ? 0.7 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
          child: IconTheme(
            data: IconThemeData(
              size: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (!hasInvoke) {
      return Tooltip(
        message: action.description,
        child: pill,
      );
    }

    return Material(
      shape: const StadiumBorder(),
      child: Tooltip(
        message: action.description,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            if (loading.value) return;
            loading.value = true;
            try {
              await action.onInvoke!(ref);
            } finally {
              loading.value = false;
            }
          },
          child: pill,
        ),
      ),
    );
  }
}
