import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_graph.freezed.dart";

/// Selects and applies conversion paths declared by an editor catalog.
///
/// The graph is an immutable snapshot of conversion definitions. Path lookup
/// uses total cost and rejects ties for the cheapest path, while automatic
/// lookup additionally permits only local, lossless, infallible edges. Realm
/// edges can be selected explicitly but remain unavailable to local [apply].
final class ConversionGraph {
  /// Captures the supplied conversion definitions for later path operations.
  ConversionGraph(Iterable<ConversionDefinition> conversions)
    : _conversions = List.unmodifiable(conversions);

  final List<ConversionDefinition> _conversions;

  /// Finds the unique cheapest path suitable for implicit conversion.
  ///
  /// Only local, lossless, infallible edges participate. An identity request
  /// returns an empty path. Missing paths and equally cheap alternatives are
  /// returned as typed diagnostics for the caller to surface or recover from.
  TypeResult<List<ConversionDefinition>> automaticPath(
    ResolvedTypeRef source,
    ResolvedTypeRef target,
  ) => _findPath(source, target, automatic: true);

  /// Finds the unique cheapest path, including explicit and realm edges.
  ///
  /// Selection does not execute the path. A tie at the lowest cost is an
  /// ambiguity rather than an arbitrary choice, so callers can require a
  /// specific conversion or report the catalog defect.
  TypeResult<List<ConversionDefinition>> explicitPath(
    ResolvedTypeRef source,
    ResolvedTypeRef target,
  ) => _findPath(source, target, automatic: false);

  TypeResult<List<ConversionDefinition>> _findPath(
    ResolvedTypeRef source,
    ResolvedTypeRef target, {
    required bool automatic,
  }) {
    if (source == target) return const TypeResult.success([]);
    final queue =
        PriorityQueue<_ConversionPath>(
          (left, right) => left.cost.compareTo(right.cost),
        )..add(
          _ConversionPath(
            type: source,
            edges: const [],
            visited: {source},
            cost: 0,
          ),
        );
    final bestCosts = <ResolvedTypeRef, int>{source: 0};
    final matches = <_ConversionPath>[];
    int? matchCost;

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      if (matchCost != null && path.cost > matchCost) break;
      if (path.type == target) {
        matchCost = path.cost;
        matches.add(path);
        continue;
      }
      for (final edge in _conversions.where(
        (edge) => edge.source == path.type,
      )) {
        if (path.visited.contains(edge.target)) continue;
        if (automatic &&
            (edge.locality != ConversionLocality.local ||
                edge.safety != ConversionSafety.lossless ||
                edge.fallible)) {
          continue;
        }
        final nextCost = path.cost + edge.cost;
        final previousCost = bestCosts[edge.target];

        if (previousCost != null && nextCost > previousCost) continue;

        bestCosts[edge.target] = nextCost;
        queue.add(
          _ConversionPath(
            type: edge.target,
            edges: [...path.edges, edge],
            visited: {...path.visited, edge.target},
            cost: nextCost,
          ),
        );
      }
    }

    if (matches.length == 1) return TypeResult.success(matches.single.edges);
    if (matches.length > 1) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.ambiguousConversion,
          message: "More than one lowest cost conversion path is available",
        ),
      ]);
    }
    return TypeResult.failure([
      TypeDiagnostic(
        code: TypeDiagnosticCode.conversionFailed,
        message: "No conversion path exists from '$source' to '$target'",
      ),
    ]);
  }

  /// Applies an already selected [path] to [value] in order.
  ///
  /// This method does not perform path selection or type lookup. It stops at
  /// the first conversion failure, and returns unavailable when a realm edge
  /// would require execution outside the panel. An empty path returns the
  /// original value as a successful identity conversion.
  ConversionResult apply(DataValue value, Iterable<ConversionDefinition> path) {
    var current = value;
    for (final conversion in path) {
      if (conversion.locality != ConversionLocality.local) {
        return ConversionUnavailable([
          TypeDiagnostic(
            code: TypeDiagnosticCode.conversionFailed,
            message: "Realm conversion execution is unavailable",
          ),
        ]);
      }
      final result = conversion.rule.evaluate(current);
      if (result case ConversionFailure()) return result;
      if (result case ConversionUnavailable()) return result;
      current = (result as ConversionSuccess).value;
    }
    return ConversionResult.success(current);
  }
}

@freezed
abstract class _ConversionPath with _$ConversionPath {
  const factory _ConversionPath({
    required ResolvedTypeRef type,
    required List<ConversionDefinition> edges,
    required Set<ResolvedTypeRef> visited,
    required int cost,
  }) = _ConversionPathValue;
}
