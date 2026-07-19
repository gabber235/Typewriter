import "dart:math" as math;

import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";
import "package:flutter_hooks/flutter_hooks.dart";

const _defaultDuration = Duration(milliseconds: 300);
const _defaultInterval = Duration(milliseconds: 60);
const _defaultMaxLaunchDuration = Duration(milliseconds: 700);
const _defaultCurve = Curves.easeOutCubic;
const _defaultSlideOffset = 0.05;

/// Coordinates a one-shot entrance animation for the [StaggerEntrance]
/// widgets in [child].
///
/// The descendants present during the scope's first completed layout are
/// ordered by their rendered position (top-to-bottom, then left-to-right).
/// Descendants mounted after that initial snapshot appear immediately.
///
/// A nested scope is treated as one contiguous group in its parent's schedule.
/// Omitted settings inherit from the nearest parent scope.
class StaggerScope extends HookWidget {
  const StaggerScope({
    required this.child,
    this.duration,
    this.interval,
    this.maxLaunchDuration,
    this.curve,
    this.slideOffset,
    super.key,
  }) : assert(slideOffset == null || slideOffset >= 0);

  final Widget child;

  /// Duration of each descendant's fade and slide.
  final Duration? duration;

  /// Preferred delay between consecutive descendants.
  final Duration? interval;

  /// Maximum time before the final descendant starts.
  ///
  /// The outermost scope's value caps the complete nested schedule.
  final Duration? maxLaunchDuration;

  /// Curve used by each descendant's fade and slide.
  final Curve? curve;

  /// Initial downward translation as a fraction of the child's height.
  final double? slideOffset;

  @override
  Widget build(BuildContext context) {
    return _buildScope(
      context,
      child: child,
      duration: duration,
      interval: interval,
      maxLaunchDuration: maxLaunchDuration,
      curve: curve,
      slideOffset: slideOffset,
      sliver: false,
    );
  }
}

/// Coordinates a one-shot entrance animation for slivers in [sliver].
///
/// The descendants present during the scope's first completed layout are
/// ordered by their rendered position. Descendants mounted after that initial
/// snapshot appear immediately. A scope without a parent starts its own
/// schedule, so data slivers can be mounted as a new standalone cohort.
///
/// Wrap multiple sibling slivers in a [SliverMainAxisGroup] to expose them as
/// the single [sliver] accepted by this scope. A nested scope is treated as one
/// contiguous group in its parent's schedule. Omitted settings inherit from
/// the nearest parent scope.
class SliverStaggerScope extends HookWidget {
  const SliverStaggerScope({
    required this.sliver,
    this.duration,
    this.interval,
    this.maxLaunchDuration,
    this.curve,
    this.slideOffset,
    super.key,
  }) : assert(slideOffset == null || slideOffset >= 0);

  final Widget sliver;

  /// Duration of each descendant's fade and slide.
  final Duration? duration;

  /// Preferred delay between consecutive descendants.
  final Duration? interval;

  /// Maximum time before the final descendant starts.
  ///
  /// The outermost scope's value caps the complete nested schedule.
  final Duration? maxLaunchDuration;

  /// Curve used by each descendant's fade and slide.
  final Curve? curve;

  /// Initial translation in the effective main axis direction as a fraction
  /// of the sliver's paint extent.
  final double? slideOffset;

  @override
  Widget build(BuildContext context) {
    return _buildScope(
      context,
      child: sliver,
      duration: duration,
      interval: interval,
      maxLaunchDuration: maxLaunchDuration,
      curve: curve,
      slideOffset: slideOffset,
      sliver: true,
    );
  }
}

Widget _buildScope(
  BuildContext context, {
  required Widget child,
  required Duration? duration,
  required Duration? interval,
  required Duration? maxLaunchDuration,
  required Curve? curve,
  required double? slideOffset,
  required bool sliver,
}) {
  assert(duration == null || !duration.isNegative);
  assert(interval == null || !interval.isNegative);
  assert(maxLaunchDuration == null || !maxLaunchDuration.isNegative);

  final parent = context
      .dependOnInheritedWidgetOfExactType<_StaggerScopeMarker>()
      ?.coordinator;
  final inherited = parent?.settings;
  final settings = _StaggerSettings(
    duration: duration ?? inherited?.duration ?? _defaultDuration,
    interval: interval ?? inherited?.interval ?? _defaultInterval,
    maxLaunchDuration:
        maxLaunchDuration ??
        inherited?.maxLaunchDuration ??
        _defaultMaxLaunchDuration,
    curve: curve ?? inherited?.curve ?? _defaultCurve,
    slideOffset: slideOffset ?? inherited?.slideOffset ?? _defaultSlideOffset,
  );
  final localController = useAnimationController(
    duration: const Duration(milliseconds: 1),
  );
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final coordinator = useMemoized(
    () => _StaggerCoordinator(
      parent: parent,
      settings: settings,
      localController: localController,
      animationsDisabled: animationsDisabled,
    ),
    [parent],
  );

  useEffect(() {
    coordinator.mount();
    return coordinator.dispose;
  }, [coordinator]);
  useEffect(() {
    coordinator.setAnimationsDisabled(animationsDisabled);
    return null;
  }, [coordinator, animationsDisabled]);

  final geometryMarker = sliver
      ? _SliverStaggerGeometryMarker(
          owner: coordinator.groupNode,
          sliver: child,
        )
      : _StaggerGeometryMarker(owner: coordinator.groupNode, child: child);
  return _StaggerScopeMarker(coordinator: coordinator, child: geometryMarker);
}

/// Animates [child] as part of the nearest [StaggerScope]'s initial epoch.
class StaggerEntrance extends HookWidget {
  const StaggerEntrance({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final marker = context
        .dependOnInheritedWidgetOfExactType<_StaggerScopeMarker>();
    assert(
      marker != null,
      "StaggerEntrance must be placed below a StaggerScope.",
    );

    // Keep production UI visible even if a caller forgot the scope.
    if (marker == null) return child;

    final coordinator = marker.coordinator;
    final registration = useMemoized(
      () => _StaggerEntranceNode(settings: coordinator.settings),
      [coordinator],
    );

    useEffect(() {
      coordinator.register(registration);
      return () {
        coordinator.unregister(registration);
        registration.dispose();
      };
    }, [coordinator, registration]);

    final state = useValueListenable(registration.state);
    final animatedChild = switch (state) {
      _CollectingEntranceState() => _InitialEntrance(
        slideOffset: registration.settings.slideOffset,
        child: child,
      ),
      _VisibleEntranceState() => child,
      _ScheduledEntranceState(:final schedule) => _ScheduledEntrance(
        schedule: schedule,
        child: child,
      ),
    };

    // Measure outside the translated subtree so entrance motion cannot change
    // the position used to determine ordering.
    return _StaggerGeometryMarker(owner: registration, child: animatedChild);
  }
}

/// Animates [sliver] as part of the nearest stagger scope's initial epoch.
class SliverStaggerEntrance extends HookWidget {
  const SliverStaggerEntrance({required this.sliver, super.key});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final marker = context
        .dependOnInheritedWidgetOfExactType<_StaggerScopeMarker>();
    assert(
      marker != null,
      "SliverStaggerEntrance must be placed below a StaggerScope or SliverStaggerScope.",
    );
    if (marker == null) return sliver;

    final coordinator = marker.coordinator;
    final registration = useMemoized(
      () => _StaggerEntranceNode(settings: coordinator.settings),
      [coordinator],
    );
    useEffect(() {
      coordinator.register(registration);
      return () {
        coordinator.unregister(registration);
        registration.dispose();
      };
    }, [coordinator, registration]);

    final state = useValueListenable(registration.state);
    final animatedSliver = switch (state) {
      _CollectingEntranceState() => _InitialSliverEntrance(
        slideOffset: registration.settings.slideOffset,
        sliver: sliver,
      ),
      _VisibleEntranceState() => sliver,
      _ScheduledEntranceState(:final schedule) => _ScheduledSliverEntrance(
        schedule: schedule,
        sliver: sliver,
      ),
    };
    return _SliverStaggerGeometryMarker(
      owner: registration,
      sliver: animatedSliver,
    );
  }
}

class _InitialEntrance extends StatelessWidget {
  const _InitialEntrance({required this.slideOffset, required this.child});

  final double slideOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0,
      child: FractionalTranslation(
        translation: Offset(0, slideOffset),
        child: child,
      ),
    );
  }
}

class _ScheduledEntrance extends StatelessWidget {
  const _ScheduledEntrance({required this.schedule, required this.child});

  final _EntranceSchedule schedule;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final totalMicroseconds = schedule.timelineDuration.inMicroseconds;
    if (totalMicroseconds <= 0 || schedule.duration == Duration.zero) {
      return child;
    }

    final begin = (schedule.start.inMicroseconds / totalMicroseconds).clamp(
      0.0,
      1.0,
    );
    final end =
        ((schedule.start + schedule.duration).inMicroseconds /
                totalMicroseconds)
            .clamp(begin, 1.0);
    final progress = schedule.timeline.drive(
      CurveTween(curve: Interval(begin, end, curve: schedule.curve)),
    );

    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, schedule.slideOffset),
          end: Offset.zero,
        ).animate(progress),
        child: child,
      ),
    );
  }
}

class _InitialSliverEntrance extends StatelessWidget {
  const _InitialSliverEntrance({
    required this.slideOffset,
    required this.sliver,
  });

  final double slideOffset;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverOpacity(
      opacity: 0,
      sliver: _SliverFractionalTranslation(
        fraction: AlwaysStoppedAnimation(slideOffset),
        sliver: sliver,
      ),
    );
  }
}

class _ScheduledSliverEntrance extends StatelessWidget {
  const _ScheduledSliverEntrance({
    required this.schedule,
    required this.sliver,
  });

  final _EntranceSchedule schedule;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final totalMicroseconds = schedule.timelineDuration.inMicroseconds;
    if (totalMicroseconds <= 0 || schedule.duration == Duration.zero) {
      return sliver;
    }
    final begin = (schedule.start.inMicroseconds / totalMicroseconds).clamp(
      0.0,
      1.0,
    );
    final end =
        ((schedule.start + schedule.duration).inMicroseconds /
                totalMicroseconds)
            .clamp(begin, 1.0);
    final progress = schedule.timeline.drive(
      CurveTween(curve: Interval(begin, end, curve: schedule.curve)),
    );
    final translation = Tween<double>(
      begin: schedule.slideOffset,
      end: 0,
    ).animate(progress);
    return SliverFadeTransition(
      opacity: progress,
      sliver: _SliverFractionalTranslation(
        fraction: translation,
        sliver: sliver,
      ),
    );
  }
}

@immutable
class _StaggerSettings {
  const _StaggerSettings({
    required this.duration,
    required this.interval,
    required this.maxLaunchDuration,
    required this.curve,
    required this.slideOffset,
  });

  final Duration duration;
  final Duration interval;
  final Duration maxLaunchDuration;
  final Curve curve;
  final double slideOffset;
}

class _StaggerScopeMarker extends InheritedWidget {
  const _StaggerScopeMarker({required this.coordinator, required super.child});

  final _StaggerCoordinator coordinator;

  @override
  bool updateShouldNotify(covariant _StaggerScopeMarker oldWidget) {
    return coordinator != oldWidget.coordinator;
  }
}

class _StaggerCoordinator {
  _StaggerCoordinator({
    required this.parent,
    required this.settings,
    required this.localController,
    required bool animationsDisabled,
  }) : groupNode = _StaggerGroupNode(),
       _animationsDisabled = animationsDisabled {
    groupNode.coordinator = this;
  }

  final _StaggerCoordinator? parent;
  final _StaggerSettings settings;
  final AnimationController localController;
  final _StaggerGroupNode groupNode;
  final List<_StaggerNode> _nodes = [];

  bool _animationsDisabled;
  bool _mounted = false;
  bool _sealed = false;
  bool _disposed = false;
  int _nextSequence = 0;

  _StaggerCoordinator get root => parent?.root ?? this;
  AnimationController get timeline => root.localController;

  void mount() {
    if (_mounted || _disposed) return;
    _mounted = true;
    if (parent != null) {
      parent!.register(groupNode);
      if (parent!._sealed) _sealTree();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || _sealed) return;
      _startInitialEpoch();
    });
  }

  void register(_StaggerNode node) {
    if (_disposed) {
      node.revealAll();
      return;
    }
    if (_sealed) {
      node.revealAll();
      if (node case _StaggerGroupNode(:final coordinator)) {
        coordinator._sealTree();
      }
      return;
    }
    if (_nodes.contains(node)) return;
    node.sequence = _nextSequence++;
    _nodes.add(node);
  }

  void unregister(_StaggerNode node) {
    if (_sealed) return;
    _nodes.remove(node);
  }

  void setAnimationsDisabled(bool disabled) {
    root._setRootAnimationsDisabled(disabled);
  }

  void _setRootAnimationsDisabled(bool disabled) {
    if (!disabled || _animationsDisabled) return;
    _animationsDisabled = true;
    if (_sealed) {
      if (localController.isAnimating) {
        localController.value = 1;
      }
      _revealUnscheduledTree();
    }
  }

  void _startInitialEpoch() {
    _sealTree();

    if (_animationsDisabled) {
      revealAll();
      return;
    }

    final assignments = <_PendingAssignment>[];
    _collectAssignments(0, assignments);
    if (assignments.isEmpty) return;

    final finalDesiredStart = assignments.fold<double>(
      0,
      (latest, assignment) => math.max(latest, assignment.desiredStartUs),
    );
    final capUs = settings.maxLaunchDuration.inMicroseconds.toDouble();
    final scale = finalDesiredStart <= 0 || finalDesiredStart <= capUs
        ? 1.0
        : capUs / finalDesiredStart;

    var timelineUs = 0.0;
    for (final assignment in assignments) {
      final startUs = assignment.desiredStartUs * scale;
      final durationUs = assignment.node.settings.duration.inMicroseconds
          .toDouble();
      timelineUs = math.max(timelineUs, startUs + durationUs);
    }

    if (timelineUs <= 0) {
      for (final assignment in assignments) {
        assignment.node.revealAll();
      }
      return;
    }

    final timelineDuration = Duration(
      microseconds: math.max(1, timelineUs.round()),
    );
    localController.duration = timelineDuration;

    for (final assignment in assignments) {
      final node = assignment.node;
      if (node.settings.duration == Duration.zero) {
        node.revealAll();
        continue;
      }
      node.schedule(
        _EntranceSchedule(
          timeline: localController,
          timelineDuration: timelineDuration,
          start: Duration(
            microseconds: (assignment.desiredStartUs * scale).round(),
          ),
          duration: node.settings.duration,
          curve: node.settings.curve,
          slideOffset: node.settings.slideOffset,
        ),
      );
    }

    localController.forward(from: 0);
  }

  double _collectAssignments(
    double cursorUs,
    List<_PendingAssignment> assignments,
  ) {
    var nextStartUs = cursorUs;
    final measurableNodes = <_StaggerNode>[];
    for (final node in _nodes) {
      if (node.globalPosition == null) {
        node.revealAll();
      } else {
        measurableNodes.add(node);
      }
    }

    measurableNodes.sort((a, b) {
      final aPosition = a.globalPosition!;
      final bPosition = b.globalPosition!;
      final vertical = aPosition.dy.compareTo(bPosition.dy);
      if (vertical != 0) return vertical;
      final horizontal = aPosition.dx.compareTo(bPosition.dx);
      if (horizontal != 0) return horizontal;
      return a.sequence.compareTo(b.sequence);
    });

    for (final node in measurableNodes) {
      switch (node) {
        case _StaggerEntranceNode():
          assignments.add(
            _PendingAssignment(node: node, desiredStartUs: nextStartUs),
          );
          nextStartUs += settings.interval.inMicroseconds;
        case _StaggerGroupNode(:final coordinator):
          nextStartUs = coordinator._collectAssignments(
            nextStartUs,
            assignments,
          );
      }
    }
    return nextStartUs;
  }

  void _sealTree() {
    if (_sealed) return;
    _sealed = true;
    for (final node in _nodes) {
      if (node case _StaggerGroupNode(:final coordinator)) {
        coordinator._sealTree();
      }
    }
  }

  void _revealUnscheduledTree() {
    for (final node in _nodes) {
      switch (node) {
        case _StaggerEntranceNode():
          if (node.state.value is _CollectingEntranceState) {
            node.revealAll();
          }
        case _StaggerGroupNode(:final coordinator):
          coordinator._revealUnscheduledTree();
      }
    }
  }

  void revealAll() {
    _sealed = true;
    for (final node in _nodes) {
      node.revealAll();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    parent?.unregister(groupNode);
    _nodes.clear();
  }
}

class _PendingAssignment {
  const _PendingAssignment({required this.node, required this.desiredStartUs});

  final _StaggerEntranceNode node;
  final double desiredStartUs;
}

class _EntranceSchedule {
  const _EntranceSchedule({
    required this.timeline,
    required this.timelineDuration,
    required this.start,
    required this.duration,
    required this.curve,
    required this.slideOffset,
  });

  final AnimationController timeline;
  final Duration timelineDuration;
  final Duration start;
  final Duration duration;
  final Curve curve;
  final double slideOffset;
}

sealed class _EntranceState {
  const _EntranceState();
}

class _CollectingEntranceState extends _EntranceState {
  const _CollectingEntranceState();
}

class _VisibleEntranceState extends _EntranceState {
  const _VisibleEntranceState();
}

class _ScheduledEntranceState extends _EntranceState {
  const _ScheduledEntranceState(this.schedule);

  final _EntranceSchedule schedule;
}

abstract class _StaggerNode extends _StaggerGeometryOwner {
  int sequence = -1;

  void revealAll();
}

class _StaggerEntranceNode extends _StaggerNode {
  _StaggerEntranceNode({required this.settings});

  final _StaggerSettings settings;
  final ValueNotifier<_EntranceState> state = ValueNotifier(
    const _CollectingEntranceState(),
  );

  void schedule(_EntranceSchedule schedule) {
    state.value = _ScheduledEntranceState(schedule);
  }

  @override
  void revealAll() {
    state.value = const _VisibleEntranceState();
  }

  void dispose() {
    state.dispose();
  }
}

class _StaggerGroupNode extends _StaggerNode {
  late _StaggerCoordinator coordinator;

  @override
  void revealAll() {
    coordinator.revealAll();
  }
}

abstract class _StaggerGeometryOwner {
  RenderObject? renderObject;

  Offset? get globalPosition {
    final renderObject = this.renderObject;
    if (renderObject == null || !renderObject.attached) return null;
    if (renderObject case RenderBox(:final hasSize)) {
      if (!hasSize) return null;
    } else if (renderObject case RenderSliver(:final geometry)) {
      if (geometry == null) return null;
    } else {
      return null;
    }
    final position = MatrixUtils.transformPoint(
      renderObject.getTransformTo(null),
      Offset.zero,
    );
    if (!position.dx.isFinite || !position.dy.isFinite) return null;
    return position;
  }
}

class _StaggerGeometryMarker extends SingleChildRenderObjectWidget {
  const _StaggerGeometryMarker({required this.owner, required super.child});

  final _StaggerGeometryOwner owner;

  @override
  _RenderStaggerGeometry createRenderObject(BuildContext context) {
    return _RenderStaggerGeometry(owner);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStaggerGeometry renderObject,
  ) {
    renderObject.owner = owner;
  }
}

class _RenderStaggerGeometry extends RenderProxyBox {
  _RenderStaggerGeometry(_StaggerGeometryOwner owner) : _owner = owner;

  _StaggerGeometryOwner _owner;

  set owner(_StaggerGeometryOwner value) {
    if (identical(value, _owner)) return;
    if (attached && identical(_owner.renderObject, this)) {
      _owner.renderObject = null;
    }
    _owner = value;
    if (attached) _owner.renderObject = this;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _owner.renderObject = this;
  }

  @override
  void detach() {
    if (identical(_owner.renderObject, this)) _owner.renderObject = null;
    super.detach();
  }
}

class _SliverStaggerGeometryMarker extends SingleChildRenderObjectWidget {
  const _SliverStaggerGeometryMarker({
    required this.owner,
    required Widget sliver,
  }) : super(child: sliver);

  final _StaggerGeometryOwner owner;

  @override
  _RenderSliverStaggerGeometry createRenderObject(BuildContext context) =>
      _RenderSliverStaggerGeometry(owner);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverStaggerGeometry renderObject,
  ) {
    renderObject.owner = owner;
  }
}

class _RenderSliverStaggerGeometry extends RenderProxySliver {
  _RenderSliverStaggerGeometry(this._owner);

  _StaggerGeometryOwner _owner;

  set owner(_StaggerGeometryOwner value) {
    if (identical(value, _owner)) return;
    if (attached && identical(_owner.renderObject, this)) {
      _owner.renderObject = null;
    }
    _owner = value;
    if (attached) _owner.renderObject = this;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _owner.renderObject = this;
  }

  @override
  void detach() {
    if (identical(_owner.renderObject, this)) _owner.renderObject = null;
    super.detach();
  }
}

class _SliverFractionalTranslation extends SingleChildRenderObjectWidget {
  const _SliverFractionalTranslation({
    required this.fraction,
    required Widget sliver,
  }) : super(child: sliver);

  final Animation<double> fraction;

  @override
  _RenderSliverFractionalTranslation createRenderObject(BuildContext context) {
    return _RenderSliverFractionalTranslation(fraction);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverFractionalTranslation renderObject,
  ) {
    renderObject.fraction = fraction;
  }
}

class _RenderSliverFractionalTranslation extends RenderProxySliver {
  _RenderSliverFractionalTranslation(Animation<double> fraction)
    : _fraction = fraction;

  Animation<double> _fraction;

  Animation<double> get fraction => _fraction;

  set fraction(Animation<double> value) {
    if (identical(value, _fraction)) return;
    if (attached) _fraction.removeListener(_handleFractionChanged);
    _fraction = value;
    if (attached) _fraction.addListener(_handleFractionChanged);
    _handleFractionChanged();
  }

  void _handleFractionChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  double get _mainAxisTranslation =>
      (geometry?.paintExtent ?? 0) * _fraction.value;

  Offset get _paintTranslation => switch (applyGrowthDirectionToAxisDirection(
    constraints.axisDirection,
    constraints.growthDirection,
  )) {
    AxisDirection.down => Offset(0, _mainAxisTranslation),
    AxisDirection.up => Offset(0, -_mainAxisTranslation),
    AxisDirection.right => Offset(_mainAxisTranslation, 0),
    AxisDirection.left => Offset(-_mainAxisTranslation, 0),
  };

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _fraction.addListener(_handleFractionChanged);
  }

  @override
  void detach() {
    _fraction.removeListener(_handleFractionChanged);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || geometry!.paintExtent == 0) return;
    context.paintChild(child!, offset + _paintTranslation);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    final translation = _paintTranslation;
    transform.translateByDouble(translation.dx, translation.dy, 0, 1);
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    final translation = _mainAxisTranslation;
    if (mainAxisPosition < translation ||
        mainAxisPosition >= geometry!.hitTestExtent + translation ||
        crossAxisPosition < 0 ||
        crossAxisPosition >= constraints.crossAxisExtent) {
      return false;
    }
    if (!hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    )) {
      return false;
    }
    result.add(
      SliverHitTestEntry(
        this,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      ),
    );
    return true;
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (child == null || geometry!.paintExtent == 0) return false;
    return result.addWithAxisOffset(
      paintOffset: _paintTranslation,
      mainAxisOffset: _mainAxisTranslation,
      crossAxisOffset: 0,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
      hitTest: child!.hitTest,
    );
  }
}
