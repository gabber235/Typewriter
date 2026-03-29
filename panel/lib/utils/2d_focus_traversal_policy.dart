import "dart:math" as math;

import "package:flutter/material.dart";

class TwoDFocusTraversalPolicy extends FocusTraversalPolicy {
  TwoDFocusTraversalPolicy({
    this.mainAxis = Axis.horizontal,
    this.crossAxisBandTolerance = 12.0,
    this.forwardEpsilon = 0.01,
    this.primaryDistanceWeight = 1.0,
    this.crossAxisWeight = 1.25,
    this.angleWeight = 0.75,
    this.overlapBonusWeight = 0.6,
  });

  final Axis mainAxis;
  final double crossAxisBandTolerance;
  final double forwardEpsilon;
  final double primaryDistanceWeight;
  final double crossAxisWeight;
  final double angleWeight;
  final double overlapBonusWeight;

  final Map<FocusScopeNode, List<_DirectionHistoryEntry>> _historyByScope =
      <FocusScopeNode, List<_DirectionHistoryEntry>>{};

  @override
  void invalidateScopeData(FocusScopeNode node) {
    super.invalidateScopeData(node);
    _historyByScope.remove(node);
  }

  @override
  void changedScope({FocusNode? node, FocusScopeNode? oldScope}) {
    super.changedScope(node: node, oldScope: oldScope);
    if (node == null || oldScope == null) {
      return;
    }
    final List<_DirectionHistoryEntry>? history = _historyByScope[oldScope];
    if (history == null) {
      return;
    }
    history.removeWhere((entry) => entry.node == node);
    if (history.isEmpty) {
      _historyByScope.remove(oldScope);
    }
  }

  @override
  FocusNode? findFirstFocusInDirection(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    final FocusScopeNode scope = currentNode.nearestScope!;
    final List<_NodeGeometry> nodes = _collectGeometry(
      scope.traversalDescendants,
    );
    if (nodes.isEmpty) {
      return null;
    }

    nodes.sort((a, b) {
      final int primary = switch (direction) {
        TraversalDirection.up => b.rect.bottom.compareTo(a.rect.bottom),
        TraversalDirection.down => a.rect.top.compareTo(b.rect.top),
        TraversalDirection.left => b.rect.right.compareTo(a.rect.right),
        TraversalDirection.right => a.rect.left.compareTo(b.rect.left),
      };
      if (primary != 0) {
        return primary;
      }

      final int cross = switch (direction) {
        TraversalDirection.up ||
        TraversalDirection.down => a.rect.left.compareTo(b.rect.left),
        TraversalDirection.left ||
        TraversalDirection.right => a.rect.top.compareTo(b.rect.top),
      };
      if (cross != 0) {
        return cross;
      }

      return a.index.compareTo(b.index);
    });

    return nodes.first.node;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final FocusScopeNode scope = currentNode.nearestScope!;
    final FocusNode? focusedChild = scope.focusedChild;
    if (focusedChild == null) {
      final FocusNode? first = findFirstFocusInDirection(
        currentNode,
        direction,
      );
      if (first == null) {
        return false;
      }
      return _requestDirectionalFocus(first, direction);
    }

    final bool popped = _popHistoryIfNeeded(scope, direction);
    if (popped) {
      return true;
    }

    _clearHistoryForOrthogonalSwitch(scope, direction);

    final FocusNode? next = _findBestDirectionalCandidate(
      focusedChild,
      scope.traversalDescendants.where((node) => node != focusedChild),
      direction,
      includeForwardCandidates: true,
    );

    if (next != null) {
      _pushHistory(scope, direction, focusedChild);
      return _requestDirectionalFocus(next, direction);
    }

    return _handleDirectionalEdge(currentNode, focusedChild, scope, direction);
  }

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final List<_NodeGeometry> nodes = _collectGeometry(descendants);
    if (nodes.length <= 1) {
      return nodes.map((entry) => entry.node);
    }

    nodes.sort((a, b) {
      final int crossStart = _crossStart(a.rect).compareTo(_crossStart(b.rect));
      if (crossStart != 0) {
        return crossStart;
      }

      final int mainStart = _mainStart(a.rect).compareTo(_mainStart(b.rect));
      if (mainStart != 0) {
        return mainStart;
      }

      return a.index.compareTo(b.index);
    });

    final List<_NodeBand> bands = <_NodeBand>[];
    for (final _NodeGeometry node in nodes) {
      final _NodeBand? band = bands
          .where((candidate) => candidate.accepts(node, crossAxisBandTolerance))
          .firstOrNull;
      if (band == null) {
        bands.add(_NodeBand.initial(node, mainAxis: mainAxis));
        continue;
      }
      band.add(node, mainAxis: mainAxis);
    }

    bands.sort((a, b) {
      final int crossStart = a.crossStart.compareTo(b.crossStart);
      if (crossStart != 0) {
        return crossStart;
      }
      return a.firstIndex.compareTo(b.firstIndex);
    });

    final List<FocusNode> ordered = <FocusNode>[];
    for (final _NodeBand band in bands) {
      band.members.sort((a, b) {
        final int mainStart = _mainStart(a.rect).compareTo(_mainStart(b.rect));
        if (mainStart != 0) {
          return mainStart;
        }

        final int crossCenter = _crossCenter(
          a.rect,
        ).compareTo(_crossCenter(b.rect));
        if (crossCenter != 0) {
          return crossCenter;
        }

        return a.index.compareTo(b.index);
      });
      ordered.addAll(band.members.map((node) => node.node));
    }

    return ordered;
  }

  bool _isOpposite(TraversalDirection a, TraversalDirection b) {
    return switch (a) {
      TraversalDirection.up => b == TraversalDirection.down,
      TraversalDirection.down => b == TraversalDirection.up,
      TraversalDirection.left => b == TraversalDirection.right,
      TraversalDirection.right => b == TraversalDirection.left,
    };
  }

  bool _isSameAxis(TraversalDirection a, TraversalDirection b) {
    final bool aVertical =
        a == TraversalDirection.up || a == TraversalDirection.down;
    final bool bVertical =
        b == TraversalDirection.up || b == TraversalDirection.down;
    return aVertical == bVertical;
  }

  bool _popHistoryIfNeeded(FocusScopeNode scope, TraversalDirection direction) {
    final List<_DirectionHistoryEntry>? history = _historyByScope[scope];
    if (history == null || history.isEmpty) {
      return false;
    }

    final _DirectionHistoryEntry last = history.last;
    if (!_isOpposite(last.direction, direction)) {
      return false;
    }

    if (last.node.parent == null ||
        !scope.traversalDescendants.contains(last.node)) {
      history.clear();
      _historyByScope.remove(scope);
      return false;
    }

    history.removeLast();
    if (history.isEmpty) {
      _historyByScope.remove(scope);
    }

    return _requestDirectionalFocus(last.node, direction);
  }

  void _clearHistoryForOrthogonalSwitch(
    FocusScopeNode scope,
    TraversalDirection direction,
  ) {
    final List<_DirectionHistoryEntry>? history = _historyByScope[scope];
    if (history == null || history.isEmpty) {
      return;
    }

    if (_isSameAxis(history.last.direction, direction)) {
      return;
    }

    history.clear();
    _historyByScope.remove(scope);
  }

  void _pushHistory(
    FocusScopeNode scope,
    TraversalDirection direction,
    FocusNode node,
  ) {
    final List<_DirectionHistoryEntry> history = _historyByScope.putIfAbsent(
      scope,
      () => <_DirectionHistoryEntry>[],
    );
    history.add(_DirectionHistoryEntry(direction: direction, node: node));
  }

  bool _requestDirectionalFocus(FocusNode node, TraversalDirection direction) {
    final ScrollPositionAlignmentPolicy alignmentPolicy =
        direction == TraversalDirection.up ||
            direction == TraversalDirection.left
        ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
        : ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
    final bool hadPrimaryFocus = node.hasPrimaryFocus;
    requestFocusCallback(node, alignmentPolicy: alignmentPolicy);
    return !hadPrimaryFocus;
  }

  bool _handleDirectionalEdge(
    FocusNode currentNode,
    FocusNode focusedChild,
    FocusScopeNode scope,
    TraversalDirection direction,
  ) {
    switch (scope.directionalTraversalEdgeBehavior) {
      case TraversalEdgeBehavior.stop:
        return false;
      case TraversalEdgeBehavior.leaveFlutterView:
        focusedChild.unfocus();
        return false;
      case TraversalEdgeBehavior.closedLoop:
        final FocusNode? wrapTarget = findFirstFocusInDirection(
          currentNode,
          direction,
        );
        if (wrapTarget == null) {
          return false;
        }
        return _requestDirectionalFocus(wrapTarget, direction);
      case TraversalEdgeBehavior.parentScope:
        final FocusScopeNode? parentScope = scope.enclosingScope;
        if (parentScope == null ||
            parentScope == FocusManager.instance.rootScope) {
          final FocusNode? fallback = findFirstFocusInDirection(
            currentNode,
            direction,
          );
          if (fallback == null) {
            return false;
          }
          return _requestDirectionalFocus(fallback, direction);
        }

        final FocusNode? parentCandidate = _findBestDirectionalCandidate(
          focusedChild,
          parentScope.traversalDescendants.where(
            (node) => node != focusedChild,
          ),
          direction,
          includeForwardCandidates: true,
        );

        if (parentCandidate != null) {
          return _requestDirectionalFocus(parentCandidate, direction);
        }

        return _handleDirectionalEdge(
          currentNode,
          focusedChild,
          parentScope,
          direction,
        );
    }
  }

  FocusNode? _findBestDirectionalCandidate(
    FocusNode current,
    Iterable<FocusNode> nodes,
    TraversalDirection direction, {
    required bool includeForwardCandidates,
  }) {
    final Rect currentRect = current.rect;
    final Size scopeScale = _scopeScale(current.nearestScope!);

    _ScoredCandidate? best;
    for (final FocusNode node in nodes) {
      if (!node.canRequestFocus || node.skipTraversal) {
        continue;
      }
      final Rect candidateRect = node.rect;
      final _DirectionalMetrics? metrics = _metricsForDirection(
        currentRect,
        candidateRect,
        direction,
      );
      if (metrics == null) {
        continue;
      }
      if (includeForwardCandidates &&
          metrics.forwardDistance <= forwardEpsilon) {
        continue;
      }
      if (!includeForwardCandidates &&
          metrics.forwardDistance >= -forwardEpsilon) {
        continue;
      }

      final double score = _scoreMetrics(metrics, scopeScale);
      final _ScoredCandidate candidate = _ScoredCandidate(
        node: node,
        score: score,
        metrics: metrics,
      );
      if (best == null ||
          _compareCandidates(candidate, best, currentRect) < 0) {
        best = candidate;
      }
    }

    return best?.node;
  }

  int _compareCandidates(
    _ScoredCandidate a,
    _ScoredCandidate b,
    Rect currentRect,
  ) {
    final int byScore = a.score.compareTo(b.score);
    if (byScore != 0) {
      return byScore;
    }

    final int byForward = a.metrics.absoluteForward.compareTo(
      b.metrics.absoluteForward,
    );
    if (byForward != 0) {
      return byForward;
    }

    final int byCross = a.metrics.crossDistance.compareTo(
      b.metrics.crossDistance,
    );
    if (byCross != 0) {
      return byCross;
    }

    final Rect aRect = a.node.rect;
    final Rect bRect = b.node.rect;
    final int byMainCenter = _mainCenter(aRect).compareTo(_mainCenter(bRect));
    if (byMainCenter != 0) {
      return byMainCenter;
    }

    return _crossCenter(aRect).compareTo(_crossCenter(bRect));
  }

  _DirectionalMetrics? _metricsForDirection(
    Rect current,
    Rect candidate,
    TraversalDirection direction,
  ) {
    final Offset vector = candidate.center - current.center;
    final double forward = switch (direction) {
      TraversalDirection.up => -vector.dy,
      TraversalDirection.down => vector.dy,
      TraversalDirection.left => -vector.dx,
      TraversalDirection.right => vector.dx,
    };

    final double cross = switch (direction) {
      TraversalDirection.up || TraversalDirection.down => vector.dx.abs(),
      TraversalDirection.left || TraversalDirection.right => vector.dy.abs(),
    };

    final double angle = forward <= 0
        ? 1.5707963267948966
        : math.atan(cross / forward);
    final double overlap = _overlapRatioOnPerpendicularAxis(
      current,
      candidate,
      direction,
    );

    return _DirectionalMetrics(
      forwardDistance: forward,
      crossDistance: cross,
      angleRadians: angle,
      overlapRatio: overlap,
    );
  }

  double _scoreMetrics(_DirectionalMetrics metrics, Size scopeScale) {
    final double forwardScale = switch (mainAxis) {
      Axis.horizontal => scopeScale.width > 0 ? scopeScale.width : 1,
      Axis.vertical => scopeScale.height > 0 ? scopeScale.height : 1,
    };

    final double crossScale = switch (mainAxis) {
      Axis.horizontal => scopeScale.height > 0 ? scopeScale.height : 1,
      Axis.vertical => scopeScale.width > 0 ? scopeScale.width : 1,
    };

    final double normalizedForward = metrics.absoluteForward / forwardScale;
    final double normalizedCross = metrics.crossDistance / crossScale;
    final double normalizedAngle = metrics.angleRadians / 1.5707963267948966;

    return (primaryDistanceWeight * normalizedForward) +
        (crossAxisWeight * normalizedCross) +
        (angleWeight * normalizedAngle) -
        (overlapBonusWeight * metrics.overlapRatio);
  }

  Size _scopeScale(FocusScopeNode scope) {
    if (scope.context == null) {
      return const Size(1, 1);
    }
    return Size(scope.rect.width, scope.rect.height);
  }

  double _overlapRatioOnPerpendicularAxis(
    Rect current,
    Rect candidate,
    TraversalDirection direction,
  ) {
    final double overlapLength = switch (direction) {
      TraversalDirection.up || TraversalDirection.down => _intervalOverlap(
        current.left,
        current.right,
        candidate.left,
        candidate.right,
      ),
      TraversalDirection.left || TraversalDirection.right => _intervalOverlap(
        current.top,
        current.bottom,
        candidate.top,
        candidate.bottom,
      ),
    };

    final double currentLength = switch (direction) {
      TraversalDirection.up || TraversalDirection.down => current.width,
      TraversalDirection.left || TraversalDirection.right => current.height,
    };

    if (currentLength <= 0) {
      return 0;
    }

    return (overlapLength / currentLength).clamp(0.0, 1.0);
  }

  double _intervalOverlap(
    double aStart,
    double aEnd,
    double bStart,
    double bEnd,
  ) {
    final double start = aStart > bStart ? aStart : bStart;
    final double end = aEnd < bEnd ? aEnd : bEnd;
    final double overlap = end - start;
    return overlap > 0 ? overlap : 0;
  }

  List<_NodeGeometry> _collectGeometry(Iterable<FocusNode> nodes) {
    final List<_NodeGeometry> result = <_NodeGeometry>[];
    var index = 0;
    for (final FocusNode node in nodes) {
      result.add(_NodeGeometry(node: node, rect: node.rect, index: index));
      index++;
    }
    return result;
  }

  double _mainStart(Rect rect) => switch (mainAxis) {
    Axis.horizontal => rect.left,
    Axis.vertical => rect.top,
  };

  double _mainCenter(Rect rect) => switch (mainAxis) {
    Axis.horizontal => rect.center.dx,
    Axis.vertical => rect.center.dy,
  };

  double _crossStart(Rect rect) => switch (mainAxis) {
    Axis.horizontal => rect.top,
    Axis.vertical => rect.left,
  };

  double _crossCenter(Rect rect) => switch (mainAxis) {
    Axis.horizontal => rect.center.dy,
    Axis.vertical => rect.center.dx,
  };
}

class _NodeGeometry {
  const _NodeGeometry({
    required this.node,
    required this.rect,
    required this.index,
  });

  final FocusNode node;
  final Rect rect;
  final int index;
}

class _NodeBand {
  _NodeBand._({
    required this.mainAxis,
    required this.members,
    required this.crossStart,
    required this.crossEnd,
    required this.firstIndex,
  });

  factory _NodeBand.initial(_NodeGeometry node, {required Axis mainAxis}) {
    return _NodeBand._(
      mainAxis: mainAxis,
      members: <_NodeGeometry>[node],
      crossStart: switch (mainAxis) {
        Axis.horizontal => node.rect.top,
        Axis.vertical => node.rect.left,
      },
      crossEnd: switch (mainAxis) {
        Axis.horizontal => node.rect.bottom,
        Axis.vertical => node.rect.right,
      },
      firstIndex: node.index,
    );
  }

  final Axis mainAxis;
  final List<_NodeGeometry> members;
  double crossStart;
  double crossEnd;
  final int firstIndex;

  bool accepts(_NodeGeometry node, double tolerance) {
    final double start = members.isEmpty
        ? crossStart
        : (crossStart < crossEnd ? crossStart : crossEnd);
    final double end = members.isEmpty
        ? crossEnd
        : (crossEnd > crossStart ? crossEnd : crossStart);
    final double nodeStart = switch (mainAxis) {
      Axis.horizontal => node.rect.top,
      Axis.vertical => node.rect.left,
    };
    final double nodeEnd = switch (mainAxis) {
      Axis.horizontal => node.rect.bottom,
      Axis.vertical => node.rect.right,
    };
    return nodeStart <= end + tolerance && nodeEnd >= start - tolerance;
  }

  void add(_NodeGeometry node, {required Axis mainAxis}) {
    members.add(node);
    final double nodeCrossStart = switch (mainAxis) {
      Axis.horizontal => node.rect.top,
      Axis.vertical => node.rect.left,
    };
    final double nodeCrossEnd = switch (mainAxis) {
      Axis.horizontal => node.rect.bottom,
      Axis.vertical => node.rect.right,
    };
    crossStart = nodeCrossStart < crossStart ? nodeCrossStart : crossStart;
    crossEnd = nodeCrossEnd > crossEnd ? nodeCrossEnd : crossEnd;
  }
}

class _DirectionalMetrics {
  const _DirectionalMetrics({
    required this.forwardDistance,
    required this.crossDistance,
    required this.angleRadians,
    required this.overlapRatio,
  });

  final double forwardDistance;
  final double crossDistance;
  final double angleRadians;
  final double overlapRatio;

  double get absoluteForward => forwardDistance.abs();
}

class _ScoredCandidate {
  const _ScoredCandidate({
    required this.node,
    required this.score,
    required this.metrics,
  });

  final FocusNode node;
  final double score;
  final _DirectionalMetrics metrics;
}

class _DirectionHistoryEntry {
  const _DirectionHistoryEntry({required this.direction, required this.node});

  final TraversalDirection direction;
  final FocusNode node;
}
