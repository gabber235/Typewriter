import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_local_rules.freezed.dart";

@freezed
abstract class AuthoredRuleProjection with _$AuthoredRuleProjection {
  const factory AuthoredRuleProjection({
    @Default({}) Map<skir.ValueLocation, List<skir.OwnedRule>> rules,
    @Default([]) List<PortablePresentationDiagnostic> diagnostics,
  }) = _AuthoredRuleProjection;

  const AuthoredRuleProjection._();

  factory AuthoredRuleProjection.evaluate({
    required PortableAuthoringView draft,
    required CheckedEditorCatalog catalog,
    required skir.ResourceId resource,
    required skir.EvaluationBudget budget,
  }) {
    final record = draft.resource(resource);
    if (record == null) return const AuthoredRuleProjection();
    final builder =
        _RuleProjectionBuilder(
          checkedCatalog: catalog,
          resource: resource,
          budget: budget,
        )..visitContext(
          record.configuration,
          skir.DataValue.createRecord(fields: record.fields),
          const [],
          0,
        );
    return AuthoredRuleProjection(
      rules: {
        for (final entry in builder.rules.entries)
          entry.key: List<skir.OwnedRule>.unmodifiable(entry.value),
      },
      diagnostics: List.unmodifiable(builder.diagnostics),
    );
  }

  bool hasOperation(skir.ValueLocation? location, String operation) {
    if (location == null) return false;
    return rules[location]?.any(
          (rule) => switch (rule.descriptor.predicate) {
            skir.ExpressionNode_callWrapper(:final value) =>
              value.operation.value == operation,
            _ => false,
          },
        ) ??
        false;
  }
}

final class _RuleProjectionBuilder {
  _RuleProjectionBuilder({
    required this.checkedCatalog,
    required this.resource,
    required this.budget,
  });

  final CheckedEditorCatalog checkedCatalog;
  final skir.ResourceId resource;
  final skir.EvaluationBudget budget;
  final Map<skir.ValueLocation, List<skir.OwnedRule>> rules = {};
  final List<PortablePresentationDiagnostic> diagnostics = [];

  void visitContext(
    skir.TypeSelection selection,
    skir.DataValue value,
    List<skir.PathSegment> base,
    int depth,
  ) {
    if (depth > 512) return;
    for (final recipe in checkedCatalog.configuration(selection)) {
      for (final match in value.expandPattern(
        segments: recipe.relativePath.segments.toList(growable: false),
        path: base,
        depth: depth,
      )) {
        final concretePath = skir.ValuePath(
          segments: match.path.skip(base.length),
        );
        final condition = recipe.representationCondition;
        if (condition != null &&
            checkedCatalog.representationKindAt(
                  selection,
                  concretePath,
                  value: value,
                ) !=
                condition) {
          continue;
        }
        final location = skir.ValueLocation(
          resource: resource,
          path: skir.ValuePath(segments: match.path),
        );
        (rules[location] ??= []).addAll(recipe.rules);
        for (final rule in recipe.rules) {
          _evaluate(rule, match.value, location);
        }
      }
    }
    _visitNested(value, base, depth + 1);
  }

  void _visitNested(
    skir.DataValue value,
    List<skir.PathSegment> path,
    int depth,
  ) {
    if (depth > 512) return;
    if (value case skir.DataValue_namedWrapper(:final value)) {
      visitContext(
        skir.TypeSelection.wrapComplete(value.actualType),
        value.payload,
        path,
        depth,
      );
      return;
    }
    switch (value.authoredPayload) {
      case skir.DataValue_recordWrapper(:final value):
        for (final field in value.fields) {
          _visitNested(field.value, [
            ...path,
            skir.PathSegment.createField(name: field.name),
          ], depth + 1);
        }
      case skir.DataValue_listValueWrapper(:final value):
        for (final item in value.items) {
          _visitNested(item.value, [
            ...path,
            skir.PathSegment.createItem(id: item.id),
          ], depth + 1);
        }
      case skir.DataValue_setValueWrapper(:final value):
        for (final item in value.items) {
          _visitNested(item.value, [
            ...path,
            skir.PathSegment.createItem(id: item.id),
          ], depth + 1);
        }
      case skir.DataValue_mapValueWrapper(:final value):
        for (final row in value.rows) {
          final rowPath = [...path, skir.PathSegment.createItem(id: row.id)];
          _visitNested(row.key, [
            ...rowPath,
            skir.PathSegment.mapKey,
          ], depth + 1);
          _visitNested(row.value, [
            ...rowPath,
            skir.PathSegment.mapValue,
          ], depth + 1);
        }
      default:
        break;
    }
  }

  void _evaluate(
    skir.OwnedRule rule,
    skir.DataValue subject,
    skir.ValueLocation location,
  ) {
    final result = PortableExpressionEvaluator.configuredValue(
      value: subject,
      location: location,
      budget: budget,
    ).evaluate(rule.descriptor.predicate);
    switch (result) {
      case PortableExpressionAvailable(:final value):
        final payload = value.authoredPayload;
        if (payload is skir.DataValue_booleanWrapper && payload.value) return;
        diagnostics.add(
          PortablePresentationDiagnostic(
            code: rule.diagnostic.code,
            origin: rule.id.origin,
            message: payload is skir.DataValue_booleanWrapper
                ? rule.diagnostic.message
                : "${rule.diagnostic.message}: the rule result is not boolean",
            severity: rule.diagnostic.severity,
            targets: rule.diagnostic.resolveTargets(
              value: subject,
              origin: location,
            ),
          ),
        );
      case PortableExpressionUnavailable():
        return;
      case PortableExpressionFailed(:final code, :final message):
        diagnostics.add(
          PortablePresentationDiagnostic(
            code: code,
            origin: rule.id.origin,
            message: message,
            severity: skir.DiagnosticSeverity.error,
            targets: [PortableDiagnosticTarget.value(location)],
          ),
        );
    }
  }
}

@freezed
abstract class _PatternMatch with _$PatternMatch {
  const factory _PatternMatch({
    required skir.DataValue value,
    required List<skir.PathSegment> path,
  }) = _PatternMatchValue;
}

extension _AuthoredValuePatternExpansion on skir.DataValue {
  Iterable<_PatternMatch> expandPattern({
    required List<skir.FieldPatternSegment> segments,
    required List<skir.PathSegment> path,
    int offset = 0,
    int depth = 0,
    bool preserveTargets = false,
  }) sync* {
    if (depth > 512) return;
    if (offset == segments.length) {
      yield _PatternMatch(value: this, path: path);
      return;
    }
    final payload = authoredPayload;
    final segment = segments[offset];
    switch (segment) {
      case skir.FieldPatternSegment_fieldWrapper(:final value):
        final field = payload.authoredField(value.name);
        final address = [
          ...path,
          skir.PathSegment.createField(name: value.name),
        ];
        if (field == null) {
          if (!preserveTargets) return;
          for (final remaining in segments.skip(offset + 1)) {
            if (remaining is! skir.FieldPatternSegment_fieldWrapper) break;
            address.add(
              skir.PathSegment.createField(name: remaining.value.name),
            );
          }
          yield _PatternMatch(value: skir.DataValue.unfilled, path: address);
          return;
        }
        yield* field.expandPattern(
          segments: segments,
          path: address,
          offset: offset + 1,
          depth: depth + 1,
          preserveTargets: preserveTargets,
        );
      case skir.FieldPatternSegment.items:
        final items = payload.authoredItems;
        if (items == null || items.isEmpty) {
          if (preserveTargets) yield _PatternMatch(value: payload, path: path);
          return;
        }
        for (final item in items) {
          yield* item.value.expandPattern(
            segments: segments,
            path: [
              ...path,
              skir.PathSegment.createItem(id: item.id),
            ],
            offset: offset + 1,
            depth: depth + 1,
            preserveTargets: preserveTargets,
          );
        }
      case skir.FieldPatternSegment.keys:
      case skir.FieldPatternSegment.values:
        if (payload case skir.DataValue_mapValueWrapper(:final value)) {
          if (value.rows.isEmpty && preserveTargets) {
            yield _PatternMatch(value: payload, path: path);
          }
          for (final row in value.rows) {
            final isKey = segment == skir.FieldPatternSegment.keys;
            yield* (isKey ? row.key : row.value).expandPattern(
              segments: segments,
              path: [
                ...path,
                skir.PathSegment.createItem(id: row.id),
                if (isKey)
                  skir.PathSegment.mapKey
                else
                  skir.PathSegment.mapValue,
              ],
              offset: offset + 1,
              depth: depth + 1,
              preserveTargets: preserveTargets,
            );
          }
        } else if (preserveTargets) {
          yield _PatternMatch(value: payload, path: path);
        }
      case skir.FieldPatternSegment_unknown():
        return;
    }
  }
}

extension AuthoredDiagnosticTargetResolution on skir.DiagnosticTemplate {
  List<PortableDiagnosticTarget> resolveTargets({
    required skir.DataValue value,
    required skir.ValueLocation origin,
  }) {
    if (targets.isEmpty) return [PortableDiagnosticTarget.value(origin)];
    final resolved = <PortableDiagnosticTarget>{};
    for (final pattern in targets) {
      final matches = value.expandPattern(
        segments: pattern.segments.toList(growable: false),
        path: origin.path.segments.toList(growable: false),
        preserveTargets: true,
      );
      for (final match in matches) {
        resolved.add(
          PortableDiagnosticTarget.value(
            skir.ValueLocation(
              resource: origin.resource,
              path: skir.ValuePath(segments: match.path),
            ),
          ),
        );
      }
    }
    return resolved.isEmpty
        ? [PortableDiagnosticTarget.value(origin)]
        : List.unmodifiable(resolved);
  }
}
