import "dart:collection";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/shared/ui/components/focus_highlight.dart";
import "package:typewriter_panel/shared/utilities/shortcut.dart";

class _PaneRegistration {
  _PaneRegistration({required this.scope});

  final FocusScopeNode scope;
  late int sequence;
  String id = "";
  bool enabled = true;
  bool primary = false;
  bool routeCurrent = true;
  _RenderPaneGeometry? renderObject;
  _PaneCoordinator? coordinator;

  Rect? readGlobalBounds() {
    final object = renderObject;
    if (object == null || !object.attached || !object.hasSize) return null;
    final rect = MatrixUtils.transformRect(
      object.getTransformTo(null),
      object.paintBounds,
    );
    if (!rect.left.isFinite ||
        !rect.top.isFinite ||
        !rect.right.isFinite ||
        !rect.bottom.isFinite ||
        rect.width <= 0 ||
        rect.height <= 0) {
      return null;
    }
    return rect;
  }
}

class _PaneSnapshot {
  const _PaneSnapshot(this.registration, this.bounds);
  final _PaneRegistration registration;
  final Rect bounds;
}

class _PaneCoordinator extends ChangeNotifier {
  final LinkedHashSet<_PaneRegistration> _registrations =
      LinkedHashSet<_PaneRegistration>.identity();
  final List<AxisDirection> _pendingDirections = [];
  _PaneRegistration? _lastActive;
  bool _disposed = false;
  bool _navigationScheduled = false;
  bool _notificationScheduled = false;
  int _eligibleCount = 0;
  int _nextSequence = 0;

  int get eligibleCount => _eligibleCount;

  void register(_PaneRegistration pane) {
    if (!_registrations.add(pane)) return;
    pane
      ..sequence = _nextSequence++
      ..coordinator = this;
    scheduleNotification();
  }

  void unregister(_PaneRegistration pane) {
    if (!_registrations.remove(pane)) return;
    if (identical(pane.coordinator, this)) pane.coordinator = null;
    if (identical(_lastActive, pane)) _lastActive = null;
    scheduleNotification();
  }

  void paneUpdated(_PaneRegistration pane) {
    if (_registrations.contains(pane)) scheduleNotification();
  }

  void markActive(_PaneRegistration pane) {
    if (_registrations.contains(pane)) _lastActive = pane;
  }

  void scheduleNotification() {
    if (_disposed || _notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _notificationScheduled = false;
      _eligibleCount = _snapshotEligiblePanes().length;
      if (hasListeners) notifyListeners();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void queueNavigation(AxisDirection direction) {
    if (_disposed) return;
    _pendingDirections.add(direction);
    if (_navigationScheduled) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _navigationScheduled = false;
      _processPendingNavigation();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _processPendingNavigation() {
    final directions = List<AxisDirection>.of(_pendingDirections);
    _pendingDirections.clear();
    for (final direction in directions) {
      final panes = _snapshotEligiblePanes();
      assert(
        panes.where((pane) => pane.registration.primary).length <= 1,
        "Only one eligible Pane may be primary.",
      );
      final source = _origin(panes);
      if (source == null) continue;
      final target = _nearestCandidate(source, panes, direction);
      if (target == null) continue;
      _lastActive = target.registration;
      target.registration.scope.requestFocus();
    }
    if (_pendingDirections.isNotEmpty && !_navigationScheduled) {
      queueNavigation(_pendingDirections.removeAt(0));
    }
  }

  List<_PaneSnapshot> _snapshotEligiblePanes() => _registrations
      .where((pane) => pane.enabled && pane.routeCurrent)
      .map((pane) {
        final bounds = pane.readGlobalBounds();
        return bounds == null ? null : _PaneSnapshot(pane, bounds);
      })
      .whereType<_PaneSnapshot>()
      .toList();

  _PaneSnapshot? _origin(List<_PaneSnapshot> panes) {
    for (final pane in panes) {
      if (pane.registration.scope.hasFocus) return pane;
    }
    for (final pane in panes) {
      if (identical(pane.registration, _lastActive)) return pane;
    }
    final primaries = panes.where((pane) => pane.registration.primary).toList();
    return primaries.isEmpty ? null : primaries.first;
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingDirections.clear();
    _registrations.clear();
    super.dispose();
  }
}

_PaneSnapshot? _nearestCandidate(
  _PaneSnapshot source,
  Iterable<_PaneSnapshot> panes,
  AxisDirection direction,
) {
  _PaneSnapshot? best;
  var bestDistance = double.infinity;
  for (final candidate in panes) {
    if (identical(candidate.registration, source.registration) ||
        !_isInDirection(source.bounds, candidate.bounds, direction)) {
      continue;
    }
    final distance = _distanceSquared(source.bounds, candidate.bounds);
    if (distance < bestDistance ||
        (distance == bestDistance &&
            candidate.registration.sequence < best!.registration.sequence)) {
      best = candidate;
      bestDistance = distance;
    }
  }
  return best;
}

bool _isInDirection(Rect source, Rect candidate, AxisDirection direction) {
  final displacement = _edgeDisplacement(source, candidate);
  return switch (direction) {
    AxisDirection.left =>
      displacement.dx < 0 && -displacement.dx >= displacement.dy.abs(),
    AxisDirection.right =>
      displacement.dx > 0 && displacement.dx >= displacement.dy.abs(),
    AxisDirection.up =>
      displacement.dy < 0 && -displacement.dy >= displacement.dx.abs(),
    AxisDirection.down =>
      displacement.dy > 0 && displacement.dy >= displacement.dx.abs(),
  };
}

double _distanceSquared(Rect a, Rect b) =>
    _edgeDisplacement(a, b).distanceSquared;

Offset _edgeDisplacement(Rect source, Rect candidate) {
  final dx = candidate.right < source.left
      ? candidate.right - source.left
      : candidate.left > source.right
      ? candidate.left - source.right
      : 0.0;
  final dy = candidate.bottom < source.top
      ? candidate.bottom - source.top
      : candidate.top > source.bottom
      ? candidate.top - source.bottom
      : 0.0;
  return Offset(dx, dy);
}

class _PaneCoordinatorScope extends InheritedWidget {
  const _PaneCoordinatorScope({
    required this.coordinator,
    required super.child,
  });
  final _PaneCoordinator coordinator;

  @override
  bool updateShouldNotify(_PaneCoordinatorScope oldWidget) =>
      coordinator != oldWidget.coordinator;
}

class Pane extends StatefulWidget {
  const Pane({
    required this.id,
    required this.child,
    this.primary = false,
    this.enabled = true,
    this.highlightOnFocus = true,
    this.trapFocus = true,
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });
  final String id;
  final Widget child;
  final bool primary;
  final bool enabled;
  final bool highlightOnFocus;
  final bool trapFocus;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<Pane> createState() => _PaneState();
}

class _PaneState extends State<Pane> {
  late final FocusScopeNode _scope;
  late final _PaneRegistration _registration;
  _PaneCoordinator? _coordinator;
  FocusType _focusType = FocusType.none;

  @override
  void initState() {
    super.initState();
    _scope = FocusScopeNode(debugLabel: "Pane-${widget.id}");
    _registration = _PaneRegistration(scope: _scope);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = context
        .dependOnInheritedWidgetOfExactType<_PaneCoordinatorScope>()
        ?.coordinator;
    assert(
      coordinator != null,
      "Pane must be placed below GlobalPaneNavigator.",
    );
    if (!identical(coordinator, _coordinator)) {
      _coordinator?.unregister(_registration);
      _coordinator = coordinator;
      coordinator?.register(_registration);
    }
    _updateRegistration();
  }

  @override
  void didUpdateWidget(Pane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRegistration();
  }

  void _updateRegistration() {
    _registration
      ..id = widget.id
      ..enabled = widget.enabled
      ..primary = widget.primary
      ..routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _scope
      ..debugLabel = "Pane-${widget.id}"
      ..traversalEdgeBehavior = widget.trapFocus
          ? TraversalEdgeBehavior.closedLoop
          : TraversalEdgeBehavior.parentScope
      ..directionalTraversalEdgeBehavior = TraversalEdgeBehavior.stop;
    _coordinator?.paneUpdated(_registration);
  }

  @override
  void dispose() {
    _coordinator?.unregister(_registration);
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = FocusScope(
      node: _scope,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (focused) _coordinator?.markActive(_registration);
        final type = FocusHighlighting.primaryAndChild(_scope);
        if (mounted && type != _focusType) setState(() => _focusType = type);
      },
      child: widget.child,
    );
    if (widget.highlightOnFocus) {
      result = FocusHighlight(
        type: _focusType,
        borderRadius: widget.borderRadius,
        size: widget.enabled ? 2 : 0,
        child: result,
      );
    } else if (widget.borderRadius != null) {
      result = DecoratedBox(
        decoration: BoxDecoration(borderRadius: widget.borderRadius),
        child: result,
      );
    }
    result = _PaneGeometryMarker(registration: _registration, child: result);
    if (widget.margin != null) {
      result = Padding(padding: widget.margin!, child: result);
    }
    return result;
  }
}

class _PaneGeometryMarker extends SingleChildRenderObjectWidget {
  const _PaneGeometryMarker({required this.registration, required super.child});
  final _PaneRegistration registration;

  @override
  _RenderPaneGeometry createRenderObject(BuildContext context) =>
      _RenderPaneGeometry(registration);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPaneGeometry renderObject,
  ) {
    renderObject.registration = registration;
  }
}

class _RenderPaneGeometry extends RenderProxyBox {
  _RenderPaneGeometry(this._registration);
  _PaneRegistration _registration;
  Size? _previousSize;

  _PaneRegistration get registration => _registration;

  set registration(_PaneRegistration value) {
    if (identical(value, _registration)) return;
    if (identical(_registration.renderObject, this)) {
      _registration.renderObject = null;
    }
    _registration = value;
    if (attached) {
      _registration.renderObject = this;
      _registration.coordinator?.scheduleNotification();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registration.renderObject = this;
    _registration.coordinator?.scheduleNotification();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (_previousSize == size) return;
    _previousSize = size;
    _registration.coordinator?.scheduleNotification();
  }

  @override
  void detach() {
    if (identical(_registration.renderObject, this)) {
      _registration.renderObject = null;
      _registration.coordinator?.scheduleNotification();
    }
    _previousSize = null;
    super.detach();
  }
}

class NavigatePaneIntent extends Intent {
  const NavigatePaneIntent(this.direction);
  final AxisDirection direction;
}

class GlobalPaneNavigator extends StatefulWidget {
  const GlobalPaneNavigator({required this.child, super.key});
  final Widget child;

  @override
  State<GlobalPaneNavigator> createState() => _GlobalPaneNavigatorState();
}

class _GlobalPaneNavigatorState extends State<GlobalPaneNavigator> {
  late final _PaneCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = _PaneCoordinator()..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coordinator
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiplePanes = _coordinator.eligibleCount > 1;
    return _PaneCoordinatorScope(
      coordinator: _coordinator,
      child: Actions(
        actions: {
          NavigatePaneIntent: NavigationAction(
            isActionEnabled: multiplePanes,
            callback: _coordinator.queueNavigation,
          ),
        },
        child: ActionSet(
          shortcuts: [
            if (multiplePanes)
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
          child: widget.child,
        ),
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
