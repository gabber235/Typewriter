import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredLocalDiagnostic {
  const AuthoredLocalDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    required this.location,
  });

  final String code;
  final String message;
  final skir.DiagnosticSeverity severity;
  final skir.ValueLocation location;
}

final class AuthoredRuleProjection {
  const AuthoredRuleProjection._({
    required this.rules,
    required this.diagnostics,
  });

  factory AuthoredRuleProjection.evaluate({
    required AuthoredDraft draft,
    required CheckedEditorCatalog catalog,
    required skir.ResourceId resource,
    required skir.EvaluationBudget budget,
  }) {
    final record = draft.resource(resource);
    if (record == null) {
      return const AuthoredRuleProjection._(rules: {}, diagnostics: []);
    }
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
    return AuthoredRuleProjection._(
      rules: _freezeRules(builder.rules),
      diagnostics: List.unmodifiable(builder.diagnostics),
    );
  }

  final Map<skir.ValueLocation, List<skir.OwnedRule>> rules;
  final List<AuthoredLocalDiagnostic> diagnostics;

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

Map<skir.ValueLocation, List<skir.OwnedRule>> _freezeRules(
  Map<skir.ValueLocation, List<skir.OwnedRule>> source,
) => Map<skir.ValueLocation, List<skir.OwnedRule>>.unmodifiable({
  for (final entry in source.entries)
    entry.key: List<skir.OwnedRule>.unmodifiable(entry.value),
});

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
  final List<AuthoredLocalDiagnostic> diagnostics = [];

  void visitContext(
    skir.TypeSelection selection,
    skir.DataValue value,
    List<skir.PathSegment> base,
    int depth,
  ) {
    if (depth > 512) return;
    for (final recipe in checkedCatalog.configuration(selection)) {
      for (final match in _expand(
        value,
        recipe.relativePath.segments.toList(growable: false),
        0,
        base,
        depth,
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
    skir.DataValue value,
    skir.ValueLocation location,
  ) {
    final result = PortableExpressionEvaluator.configuredValue(
      value: value,
      location: location,
      budget: budget,
    ).evaluate(rule.descriptor.predicate);
    switch (result) {
      case PortableExpressionAvailable(:final value):
        final payload = value.authoredPayload;
        if (payload is skir.DataValue_booleanWrapper && payload.value) return;
        diagnostics.add(
          AuthoredLocalDiagnostic(
            code: rule.diagnostic.code,
            message: payload is skir.DataValue_booleanWrapper
                ? rule.diagnostic.message
                : "${rule.diagnostic.message}: the rule result is not boolean",
            severity: rule.diagnostic.severity,
            location: location,
          ),
        );
      case PortableExpressionUnavailable():
        return;
      case PortableExpressionFailed(:final code, :final message):
        diagnostics.add(
          AuthoredLocalDiagnostic(
            code: code,
            message: message,
            severity: skir.DiagnosticSeverity.error,
            location: location,
          ),
        );
    }
  }
}

final class _PatternMatch {
  const _PatternMatch(this.value, this.path);

  final skir.DataValue value;
  final List<skir.PathSegment> path;
}

Iterable<_PatternMatch> _expand(
  skir.DataValue current,
  List<skir.FieldPatternSegment> segments,
  int offset,
  List<skir.PathSegment> path,
  int depth,
) sync* {
  if (depth > 512) return;
  if (offset == segments.length) {
    yield _PatternMatch(current, path);
    return;
  }
  final payload = current.authoredPayload;
  final segment = segments[offset];
  switch (segment) {
    case skir.FieldPatternSegment_fieldWrapper(:final value):
      final field = payload.authoredField(value.name);
      if (field == null) return;
      yield* _expand(field, segments, offset + 1, [
        ...path,
        skir.PathSegment.createField(name: value.name),
      ], depth + 1);
    case skir.FieldPatternSegment.items:
      final items = payload.authoredItems;
      if (items == null) return;
      for (final item in items) {
        yield* _expand(item.value, segments, offset + 1, [
          ...path,
          skir.PathSegment.createItem(id: item.id),
        ], depth + 1);
      }
    case skir.FieldPatternSegment.keys:
      if (payload case skir.DataValue_mapValueWrapper(:final value)) {
        for (final row in value.rows) {
          yield* _expand(row.key, segments, offset + 1, [
            ...path,
            skir.PathSegment.createItem(id: row.id),
            skir.PathSegment.mapKey,
          ], depth + 1);
        }
      }
    case skir.FieldPatternSegment.values:
      if (payload case skir.DataValue_mapValueWrapper(:final value)) {
        for (final row in value.rows) {
          yield* _expand(row.value, segments, offset + 1, [
            ...path,
            skir.PathSegment.createItem(id: row.id),
            skir.PathSegment.mapValue,
          ], depth + 1);
        }
      }
    case skir.FieldPatternSegment_unknown():
      return;
  }
}
