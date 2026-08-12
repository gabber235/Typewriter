import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_graph.freezed.dart";

final class ConversionGraph {
  ConversionGraph(Iterable<ConversionDefinition> conversions)
    : _conversions = List.unmodifiable(conversions);

  static TypeResult<ConversionGraph> withInheritance({
    required TypeRegistry registry,
    required Iterable<ResolvedTypeRef> applications,
    Iterable<ConversionDefinition> conversions = const [],
  }) {
    final edges = List<ConversionDefinition>.of(conversions);
    final diagnostics = <TypeDiagnostic>[];
    final pending = applications.toList();
    final resolvedApplications = <ResolvedTypeRef>{};
    final inheritanceEdges = <(ResolvedTypeRef, ResolvedTypeRef)>{};
    while (pending.isNotEmpty) {
      final source = pending.removeLast();
      if (!resolvedApplications.add(source)) continue;
      final resolved = registry.resolveExact(source);
      diagnostics.addAll(resolved.diagnostics);
      final value = resolved.valueOrNull;
      if (value == null) continue;
      for (final target in value.directParents) {
        pending.add(target);
        if (!inheritanceEdges.add((source, target))) continue;
        edges.add(
          ConversionDefinition(
            id: ConversionId(
              namespace: "typewriter/inheritance",
              name: "$source:$target",
            ),
            source: source,
            target: target,
            rule: const InheritanceUpcastRule(),
            cost: 0,
          ),
        );
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(ConversionGraph(edges))
        : TypeResult.failure(diagnostics);
  }

  final List<ConversionDefinition> _conversions;

  TypeResult<List<ConversionDefinition>> automaticPath(
    ResolvedTypeRef source,
    ResolvedTypeRef target,
  ) => _findPath(source, target, automatic: true);

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
