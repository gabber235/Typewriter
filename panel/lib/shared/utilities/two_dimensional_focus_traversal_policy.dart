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
    final history = _historyByScope[oldScope];
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
    final scope = currentNode.nearestScope!;
    final nodes = _collectGeometry(
      scope.traversalDescendants,
    );
    if (nodes.isEmpty) {
      return null;
    }

    nodes.sort((a, b) {
      final primary = switch (direction) {
        TraversalDirection.up => b.rect.bottom.compareTo(a.rect.bottom),
        TraversalDirection.down => a.rect.top.compareTo(b.rect.top),
        TraversalDirection.left => b.rect.right.compareTo(a.rect.right),
        TraversalDirection.right => a.rect.left.compareTo(b.rect.left),
      };
      if (primary != 0) {
        return primary;
      }

      final cross = switch (direction) {
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
    final scope = currentNode.nearestScope!;
    final focusedChild = scope.focusedChild;
    if (focusedChild == null) {
      final first = findFirstFocusInDirection(
        currentNode,
        direction,
      );
      if (first == null) {
        return false;
      }
      return _requestDirectionalFocus(first, direction);
    }

    final popped = _popHistoryIfNeeded(scope, direction);
    if (popped) {
      return true;
    }

    _clearHistoryForOrthogonalSwitch(scope, direction);

    final next = _findBestDirectionalCandidate(
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
    final nodes = _collectGeometry(descendants);
    if (nodes.length <= 1) {
      return nodes.map((entry) => entry.node);
    }

    nodes.sort((a, b) {
      final crossStart = _crossStart(a.rect).compareTo(_crossStart(b.rect));
      if (crossStart != 0) {
        return crossStart;
      }

      final mainStart = _mainStart(a.rect).compareTo(_mainStart(b.rect));
      if (mainStart != 0) {
        return mainStart;
      }

      return a.index.compareTo(b.index);
    });

    final bands = <_NodeBand>[];
    for (final node in nodes) {
      final band = bands
          .where((candidate) => candidate.accepts(node, crossAxisBandTolerance))
          .firstOrNull;
      if (band == null) {
        bands.add(_NodeBand.initial(node, mainAxis: mainAxis));
        continue;
      }
      band.add(node, mainAxis: mainAxis);
    }

    bands.sort((a, b) {
      final crossStart = a.crossStart.compareTo(b.crossStart);
      if (crossStart != 0) {
        return crossStart;
      }
      return a.firstIndex.compareTo(b.firstIndex);
    });

    final ordered = <FocusNode>[];
    for (final band in bands) {
      band.members.sort((a, b) {
        final mainStart = _mainStart(a.rect).compareTo(_mainStart(b.rect));
        if (mainStart != 0) {
          return mainStart;
        }

        final crossCenter = _crossCenter(
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
    final aVertical =
        a == TraversalDirection.up || a == TraversalDirection.down;
    final bVertical =
        b == TraversalDirection.up || b == TraversalDirection.down;
    return aVertical == bVertical;
  }

  bool _popHistoryIfNeeded(FocusScopeNode scope, TraversalDirection direction) {
    final history = _historyByScope[scope];
    if (history == null || history.isEmpty) {
      return false;
    }

    final last = history.last;
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
    final history = _historyByScope[scope];
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
    _historyByScope
        .putIfAbsent(scope, () => <_DirectionHistoryEntry>[])
        .add(_DirectionHistoryEntry(direction: direction, node: node));
  }

  bool _requestDirectionalFocus(FocusNode node, TraversalDirection direction) {
    final alignmentPolicy =
        direction == TraversalDirection.up ||
            direction == TraversalDirection.left
        ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
        : ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
    final hadPrimaryFocus = node.hasPrimaryFocus;
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
        final wrapTarget = findFirstFocusInDirection(
          currentNode,
          direction,
        );
        if (wrapTarget == null) {
          return false;
        }
        return _requestDirectionalFocus(wrapTarget, direction);
      case TraversalEdgeBehavior.parentScope:
        final parentScope = scope.enclosingScope;
        if (parentScope == null ||
            parentScope == FocusManager.instance.rootScope) {
          final fallback = findFirstFocusInDirection(
            currentNode,
            direction,
          );
          if (fallback == null) {
            return false;
          }
          return _requestDirectionalFocus(fallback, direction);
        }

        final parentCandidate = _findBestDirectionalCandidate(
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
    final currentRect = current.rect;
    final scopeScale = _scopeScale(current.nearestScope!);

    _ScoredCandidate? best;
    for (final node in nodes) {
      if (!node.canRequestFocus || node.skipTraversal) {
        continue;
      }
      final candidateRect = node.rect;
      final metrics = _metricsForDirection(
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

      final score = _scoreMetrics(metrics, scopeScale);
      final candidate = _ScoredCandidate(
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
    final byScore = a.score.compareTo(b.score);
    if (byScore != 0) {
      return byScore;
    }

    final byForward = a.metrics.absoluteForward.compareTo(
      b.metrics.absoluteForward,
    );
    if (byForward != 0) {
      return byForward;
    }

    final byCross = a.metrics.crossDistance.compareTo(
      b.metrics.crossDistance,
    );
    if (byCross != 0) {
      return byCross;
    }

    final aRect = a.node.rect;
    final bRect = b.node.rect;
    final byMainCenter = _mainCenter(aRect).compareTo(_mainCenter(bRect));
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
    final vector = candidate.center - current.center;
    final forward = switch (direction) {
      TraversalDirection.up => -vector.dy,
      TraversalDirection.down => vector.dy,
      TraversalDirection.left => -vector.dx,
      TraversalDirection.right => vector.dx,
    };

    final cross = switch (direction) {
      TraversalDirection.up || TraversalDirection.down => vector.dx.abs(),
      TraversalDirection.left || TraversalDirection.right => vector.dy.abs(),
    };

    final angle = forward <= 0
        ? 1.5707963267948966
        : math.atan(cross / forward);
    final overlap = _overlapRatioOnPerpendicularAxis(
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
    final forwardScale = switch (mainAxis) {
      Axis.horizontal => scopeScale.width > 0 ? scopeScale.width : 1,
      Axis.vertical => scopeScale.height > 0 ? scopeScale.height : 1,
    };

    final crossScale = switch (mainAxis) {
      Axis.horizontal => scopeScale.height > 0 ? scopeScale.height : 1,
      Axis.vertical => scopeScale.width > 0 ? scopeScale.width : 1,
    };

    final normalizedForward = metrics.absoluteForward / forwardScale;
    final normalizedCross = metrics.crossDistance / crossScale;
    final normalizedAngle = metrics.angleRadians / 1.5707963267948966;

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
    final overlapLength = switch (direction) {
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

    final currentLength = switch (direction) {
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
    final start = aStart > bStart ? aStart : bStart;
    final end = aEnd < bEnd ? aEnd : bEnd;
    final overlap = end - start;
    return overlap > 0 ? overlap : 0;
  }

  List<_NodeGeometry> _collectGeometry(Iterable<FocusNode> nodes) {
    final result = <_NodeGeometry>[];
    var index = 0;
    for (final node in nodes) {
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
    final start = members.isEmpty
        ? crossStart
        : (crossStart < crossEnd ? crossStart : crossEnd);
    final end = members.isEmpty
        ? crossEnd
        : (crossEnd > crossStart ? crossEnd : crossStart);
    final nodeStart = switch (mainAxis) {
      Axis.horizontal => node.rect.top,
      Axis.vertical => node.rect.left,
    };
    final nodeEnd = switch (mainAxis) {
      Axis.horizontal => node.rect.bottom,
      Axis.vertical => node.rect.right,
    };
    return nodeStart <= end + tolerance && nodeEnd >= start - tolerance;
  }

  void add(_NodeGeometry node, {required Axis mainAxis}) {
    members.add(node);
    final nodeCrossStart = switch (mainAxis) {
      Axis.horizontal => node.rect.top,
      Axis.vertical => node.rect.left,
    };
    final nodeCrossEnd = switch (mainAxis) {
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
