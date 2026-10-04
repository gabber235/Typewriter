import "package:typewriter_panel/features/organizations/features/realms/application/authored_draft.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/editors/application/checked_editor_catalog.dart";
import "package:typewriter_panel/shared/editors/application/portable_expression.dart";
import "package:typewriter_panel/shared/editors/application/portable_value_tree.dart";

final class AuthoredLocalDiagnostic {
  const AuthoredLocalDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    required this.location,
  });

  final String code;
  final String message;
  final diagnostic.DiagnosticSeverity severity;
  final types.ValueLocation location;
}

final class AuthoredRuleProjection {
  const AuthoredRuleProjection._({
    required this.rules,
    required this.diagnostics,
  });

  factory AuthoredRuleProjection.evaluate({
    required AuthoredDraft draft,
    required CheckedEditorCatalog catalog,
    required types.ResourceId resource,
    required expression.EvaluationBudget budget,
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
          types.DataValue.createRecord(fields: record.fields),
          const [],
          0,
        );
    return AuthoredRuleProjection._(
      rules: _freezeRules(builder.rules),
      diagnostics: List.unmodifiable(builder.diagnostics),
    );
  }

  final Map<types.ValueLocation, List<catalog.OwnedRule>> rules;
  final List<AuthoredLocalDiagnostic> diagnostics;

  bool hasOperation(types.ValueLocation? location, String operation) {
    if (location == null) return false;
    return rules[location]?.any(
          (rule) => switch (rule.descriptor.predicate) {
            expression.ExpressionNode_callWrapper(:final value) =>
              value.operation.value == operation,
            _ => false,
          },
        ) ??
        false;
  }
}

Map<types.ValueLocation, List<catalog.OwnedRule>> _freezeRules(
  Map<types.ValueLocation, List<catalog.OwnedRule>> source,
) => Map<types.ValueLocation, List<catalog.OwnedRule>>.unmodifiable({
  for (final entry in source.entries)
    entry.key: List<catalog.OwnedRule>.unmodifiable(entry.value),
});

final class _RuleProjectionBuilder {
  _RuleProjectionBuilder({
    required this.checkedCatalog,
    required this.resource,
    required this.budget,
  });

  final CheckedEditorCatalog checkedCatalog;
  final types.ResourceId resource;
  final expression.EvaluationBudget budget;
  final Map<types.ValueLocation, List<catalog.OwnedRule>> rules = {};
  final List<AuthoredLocalDiagnostic> diagnostics = [];

  void visitContext(
    types.TypeSelection selection,
    types.DataValue value,
    List<types.PathSegment> base,
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
        final concretePath = types.ValuePath(
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
        final location = types.ValueLocation(
          resource: resource,
          path: types.ValuePath(segments: match.path),
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
    types.DataValue value,
    List<types.PathSegment> path,
    int depth,
  ) {
    if (depth > 512) return;
    if (value case types.DataValue_namedWrapper(:final value)) {
      visitContext(
        types.TypeSelection.wrapComplete(value.actualType),
        value.payload,
        path,
        depth,
      );
      return;
    }
    switch (value.authoredPayload) {
      case types.DataValue_recordWrapper(:final value):
        for (final field in value.fields) {
          _visitNested(field.value, [
            ...path,
            types.PathSegment.createField(name: field.name),
          ], depth + 1);
        }
      case types.DataValue_listValueWrapper(:final value):
        for (final item in value.items) {
          _visitNested(item.value, [
            ...path,
            types.PathSegment.createItem(id: item.id),
          ], depth + 1);
        }
      case types.DataValue_setValueWrapper(:final value):
        for (final item in value.items) {
          _visitNested(item.value, [
            ...path,
            types.PathSegment.createItem(id: item.id),
          ], depth + 1);
        }
      case types.DataValue_mapValueWrapper(:final value):
        for (final row in value.rows) {
          final rowPath = [...path, types.PathSegment.createItem(id: row.id)];
          _visitNested(row.key, [
            ...rowPath,
            types.PathSegment.mapKey,
          ], depth + 1);
          _visitNested(row.value, [
            ...rowPath,
            types.PathSegment.mapValue,
          ], depth + 1);
        }
      default:
        break;
    }
  }

  void _evaluate(
    catalog.OwnedRule rule,
    types.DataValue value,
    types.ValueLocation location,
  ) {
    final result = PortableExpressionEvaluator.configuredValue(
      value: value,
      location: location,
      budget: budget,
    ).evaluate(rule.descriptor.predicate);
    switch (result) {
      case PortableExpressionAvailable(:final value):
        final payload = value.authoredPayload;
        if (payload is types.DataValue_booleanWrapper && payload.value) return;
        diagnostics.add(
          AuthoredLocalDiagnostic(
            code: rule.diagnostic.code,
            message: payload is types.DataValue_booleanWrapper
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
            severity: diagnostic.DiagnosticSeverity.error,
            location: location,
          ),
        );
    }
  }
}

final class _PatternMatch {
  const _PatternMatch(this.value, this.path);

  final types.DataValue value;
  final List<types.PathSegment> path;
}

Iterable<_PatternMatch> _expand(
  types.DataValue current,
  List<types.FieldPatternSegment> segments,
  int offset,
  List<types.PathSegment> path,
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
    case types.FieldPatternSegment_fieldWrapper(:final value):
      final field = payload.authoredField(value.name);
      if (field == null) return;
      yield* _expand(field, segments, offset + 1, [
        ...path,
        types.PathSegment.createField(name: value.name),
      ], depth + 1);
    case types.FieldPatternSegment.items:
      final items = payload.authoredItems;
      if (items == null) return;
      for (final item in items) {
        yield* _expand(item.value, segments, offset + 1, [
          ...path,
          types.PathSegment.createItem(id: item.id),
        ], depth + 1);
      }
    case types.FieldPatternSegment.keys:
      if (payload case types.DataValue_mapValueWrapper(:final value)) {
        for (final row in value.rows) {
          yield* _expand(row.key, segments, offset + 1, [
            ...path,
            types.PathSegment.createItem(id: row.id),
            types.PathSegment.mapKey,
          ], depth + 1);
        }
      }
    case types.FieldPatternSegment.values:
      if (payload case types.DataValue_mapValueWrapper(:final value)) {
        for (final row in value.rows) {
          yield* _expand(row.value, segments, offset + 1, [
            ...path,
            types.PathSegment.createItem(id: row.id),
            types.PathSegment.mapValue,
          ], depth + 1);
        }
      }
    case types.FieldPatternSegment_unknown():
      return;
  }
}
