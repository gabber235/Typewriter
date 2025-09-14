import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/hooks/delayed_execution.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/rect.dart";
import "package:typewriter_panel/utils/render_box.dart";
import "package:typewriter_panel/utils/shortuct.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";

part "panes.g.dart";

class PaneInfo {
  const PaneInfo({
    required this.id,
    required this.focusNode,
    required this.key,
    required this.enabled,
  });
  final String id;
  final FocusNode focusNode;
  final GlobalKey key;
  final bool enabled;

  Rect? get bounds {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return null;
    }

    return renderBox.bounds;
  }

  Offset? get center => bounds?.center;
}

@riverpod
class Panes extends _$Panes {
  @override
  Map<String, PaneInfo> build() => {};

  void register(
    String id,
    FocusNode focusNode,
    GlobalKey key, {
    required bool enabled,
  }) {
    state = {
      ...state,
      id: PaneInfo(id: id, focusNode: focusNode, key: key, enabled: enabled),
    };
  }

  void unregister(String id) {
    state = {...state}..remove(id);
    // TODO: Investigate if we need to reassign focus or if flutter will do that for us
  }

  bool navigateInDirection(AxisDirection direction) {
    final panes = state.values
        .map((info) {
          final bounds = info.bounds;
          if (bounds == null) {
            return null;
          }
          return (info, bounds);
        })
        .nonNulls
        .toList();

    if (panes.isEmpty) return false;

    final currentPane =
        state.values.firstWhereOrNull((pane) => pane.focusNode.hasFocus) ??
            panes.maxByOrNull((element) => element.$2.area)?.$1;

    if (currentPane == null) return false;

    final primaryFocusCenter = (FocusManager.instance.primaryFocus?.context
            ?.findRenderObject() as RenderBox?)
        ?.bounds
        .center;
    final rayOrigin = primaryFocusCenter ??
        panes.firstWhere((element) => element.$1 == currentPane).$2.center;

    final nextPane =
        _findNextPaneByRaycast(panes, currentPane, rayOrigin, direction);
    if (nextPane == null) return false;

    nextPane.focusNode.requestFocus();
    return true;
  }

  PaneInfo? _findNextPaneByRaycast(
    List<(PaneInfo, Rect)> panes,
    PaneInfo currentPane,
    Offset rayOrigin,
    AxisDirection direction,
  ) {
    return panes
        .where((element) => element.$1 != currentPane && element.$1.enabled)
        .map((element) {
          final intersectionPoint =
              _rayIntersectsRect(rayOrigin, direction, element.$2);
          if (intersectionPoint == null) return null;
          return (element.$1, intersectionPoint);
        })
        .nonNulls
        .map(
          (element) => (
            element.$1,
            _calculateRayDistance(rayOrigin, element.$2, direction)
          ),
        )
        .minByOrNull((element) => element.$2)
        ?.$1;
  }

  Offset? _rayIntersectsRect(
    Offset origin,
    AxisDirection direction,
    Rect rect,
  ) {
    switch (direction) {
      case AxisDirection.left:
        if (origin.dx <= rect.left) return null;
        if (origin.dy < rect.top || origin.dy > rect.bottom) return null;
        return Offset(rect.right, origin.dy);

      case AxisDirection.right:
        if (origin.dx >= rect.right) return null;
        if (origin.dy < rect.top || origin.dy > rect.bottom) return null;
        return Offset(rect.left, origin.dy);

      case AxisDirection.up:
        if (origin.dy <= rect.top) return null;
        if (origin.dx < rect.left || origin.dx > rect.right) return null;
        return Offset(origin.dx, rect.bottom);

      case AxisDirection.down:
        if (origin.dy >= rect.bottom) return null;
        if (origin.dx < rect.left || origin.dx > rect.right) return null;
        return Offset(origin.dx, rect.top);
    }
  }

  double _calculateRayDistance(
    Offset origin,
    Offset intersection,
    AxisDirection direction,
  ) {
    switch (direction) {
      case AxisDirection.left:
        return origin.dx - intersection.dx;
      case AxisDirection.right:
        return intersection.dx - origin.dx;
      case AxisDirection.up:
        return origin.dy - intersection.dy;
      case AxisDirection.down:
        return intersection.dy - origin.dy;
    }
  }
}

class Pane extends HookConsumerWidget {
  const Pane({
    required this.id,
    required this.child,
    this.enabled = true,
    this.highlightOnFocus = true,
    this.trapFocus = true,
    this.margin = const EdgeInsets.all(8),
    this.borderRadius,
    super.key,
  });
  final String id;
  final Widget child;
  final bool enabled;

  final bool highlightOnFocus;
  final bool trapFocus;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugLabel = "Pane-$id";
    final focusNode = useFocusNode(debugLabel: debugLabel);
    final focusScopeNode = useFocusScopeNode(debugLabel: debugLabel);

    final node = trapFocus ? focusScopeNode : focusNode;

    final key = useGlobalKey(debugLabel: debugLabel);
    final focusType = useState(FocusType.none);

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(panesProvider.notifier)
              .register(id, node, key, enabled: enabled);
        });
        // We can't unregister here, because the widget is no longer mounted so ref.read can't be used
        // However the [GlobalPaneNavigator] will unregister the pane if the global key doesn't have a context
        return null;
      },
      [id, enabled, key, node],
    );

    Widget widget = trapFocus
        ? FocusScope(
            key: key,
            node: focusScopeNode,
            skipTraversal: true,
            debugLabel: debugLabel,
            onFocusChange: (_) =>
                focusType.value = FocusHighlighting.primaryAndChild(node),
            child: child,
          )
        : Focus(
            key: key,
            focusNode: focusNode,
            skipTraversal: true,
            debugLabel: debugLabel,
            onFocusChange: (_) =>
                focusType.value = FocusHighlighting.primaryAndChild(focusNode),
            child: child,
          );

    if (highlightOnFocus) {
      widget = FocusHighlight(
        type: focusType.value,
        borderRadius: borderRadius,
        size: enabled ? 2 : 0,
        child: widget,
      );
    } else if (borderRadius != null) {
      widget = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
        child: widget,
      );
    }

    if (margin != null) {
      widget = Padding(
        padding: margin!,
        child: widget,
      );
    }

    return widget;
  }
}

class NavigatePaneIntent extends Intent {
  const NavigatePaneIntent(this.direction);
  final AxisDirection direction;
}

class GlobalPaneNavigator extends HookConsumerWidget {
  const GlobalPaneNavigator({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panes = ref.watch(panesProvider);

    useDelayedExecution(
      () {
        if (!context.mounted) return;
        panes.values
            .where((pane) => pane.key.currentContext == null)
            .map((pane) => pane.id)
            .forEach((id) => ref.read(panesProvider.notifier).unregister(id));
      },
    );

    return Actions(
      actions: {
        NavigatePaneIntent: NavigationAction(
          isActionEnabled: panes.isNotEmpty,
          callback: (direction) {
            ref.read(panesProvider.notifier).navigateInDirection(direction);
          },
        ),
      },
      child: ActionSet(
        shortcuts: [
          if (panes.length > 1)
            ActionShortcut(
              id: "global_nav_panes",
              label: "Switch Panes",
              description: "Move between panes directionally",
              activators: [
                SortedLogicalKeyActivator.fromList([
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.arrowLeft,
                  LogicalKeyboardKey.arrowDown,
                  LogicalKeyboardKey.arrowUp,
                  LogicalKeyboardKey.arrowRight,
                ]),
                SortedLogicalKeyActivator.fromList([
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.keyH,
                  LogicalKeyboardKey.keyJ,
                  LogicalKeyboardKey.keyK,
                  LogicalKeyboardKey.keyL,
                ]),
              ],
              priority: -1,
            ),
        ],
        child: child,
      ),
    );
  }
}

class NavigationAction extends Action<NavigatePaneIntent> {
  NavigationAction({required this.isActionEnabled, required this.callback});
  @override
  final bool isActionEnabled;
  final void Function(AxisDirection) callback;

  @override
  Object? invoke(NavigatePaneIntent intent) {
    callback(intent.direction);
    return null;
  }
}
