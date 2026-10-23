import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_local_rules.freezed.dart";

/// Evaluates portable configuration rules over one resource's working values
/// exactly as Realm checks them (`RealmCheckRuntime`), so draft feedback and
/// saved findings share one contract.
///
/// Every location a recipe pattern reaches is one subject, missing and
/// unfinished values included; each rule of the recipe yields one
/// [AuthoredRuleCheck] there. The projection is independent of Realm check
/// execution and cannot establish saved publication readiness.
@freezed
abstract class AuthoredRuleProjection with _$AuthoredRuleProjection {
  const factory AuthoredRuleProjection({
    @Default([]) List<AuthoredRuleCheck> checks,
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
    return AuthoredRuleProjection(checks: List.unmodifiable(builder.checks));
  }
}

/// One rule evaluated at one subject: Realm's outcome and findings for it.
///
/// A true predicate finishes clean and a false one finishes with the rule's
/// finding. Missing data needs input at its locations. A failure, or a result
/// that is not a boolean, is a failed outcome. Diagnostic ids are
/// deterministic per rule and subject.
@freezed
abstract class AuthoredRuleCheck with _$AuthoredRuleCheck {
  const factory AuthoredRuleCheck({
    required skir.RuleId rule,
    required skir.ValueLocation subject,
    required skir.CheckOutcome outcome,
    @Default([]) List<skir.Diagnostic> findings,
  }) = _AuthoredRuleCheck;
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
  final List<AuthoredRuleCheck> checks = [];

  void visitContext(
    skir.TypeSelection selection,
    skir.DataValue value,
    List<skir.PathSegment> base,
    int depth,
  ) {
    if (depth > 512) return;
    final owner = skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(segments: base),
    );
    for (final recipe in checkedCatalog.configuration(selection)) {
      for (final subject in value.expandPattern(owner, recipe.relativePath)) {
        final relative = skir.ValuePath(
          segments: subject.path.segments.skip(base.length),
        );
        final condition = recipe.representationCondition;
        if (condition != null &&
            checkedCatalog.representationKindAt(
                  selection,
                  relative,
                  value: value,
                ) !=
                condition) {
          continue;
        }
        final subjectValue = switch (value.readAt(relative)) {
          PortablePathValue(:final value) => value,
          PortablePathUnavailable() => skir.DataValue.unfilled,
        };
        for (final rule in recipe.rules) {
          checks.add(
            _evaluate(
              recipe,
              rule,
              subject,
              subjectValue,
              ownerValue: value,
              owner: owner,
            ),
          );
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

  /// Realm's portable rule branch for one subject (`RealmCheckRuntime`).
  /// An absent subject evaluates as unfilled, so it needs input.
  AuthoredRuleCheck _evaluate(
    skir.ConfigurationRecipe recipe,
    skir.OwnedRule rule,
    skir.ValueLocation subject,
    skir.DataValue subjectValue, {
    required skir.DataValue ownerValue,
    required skir.ValueLocation owner,
  }) {
    final id = skir.DiagnosticId(
      value:
          "local:${skir.RuleId.serializer.toJsonCode(rule.id)}:"
          "${skir.ValueLocation.serializer.toJsonCode(subject)}",
    );
    skir.CheckOutcome failed(
      skir.FailureId failure,
      String message,
      List<skir.ValueLocation> locations,
    ) => skir.CheckOutcome.wrapFailed([
      skir.Diagnostic(
        id: id,
        origin: rule.id.origin,
        code: failure.value,
        message: message,
        severity: skir.DiagnosticSeverity.error,
        primary: locations.firstOrNull ?? subject,
        related: locations.skip(1).toList(),
      ),
    ]);
    final result = PortableExpressionEvaluator.configuredValue(
      value: subjectValue,
      location: subject,
      budget: budget,
      catalog: checkedCatalog,
    ).evaluate(rule.descriptor.predicate);
    final (outcome, findings) = switch (result) {
      PortableExpressionAvailable(:final value) =>
        switch (value.authoredPayload) {
          skir.DataValue_booleanWrapper(value: true) => (
            skir.CheckOutcome.finished,
            const <skir.Diagnostic>[],
          ),
          skir.DataValue_booleanWrapper() => (
            skir.CheckOutcome.finished,
            [
              _finding(
                recipe,
                rule,
                id,
                subject,
                ownerValue: ownerValue,
                owner: owner,
              ),
            ],
          ),
          _ => (
            failed(
              skir.PortableFailures.expressionResultNotBoolean,
              "The portable predicate did not produce a boolean value.",
              [subject],
            ),
            const <skir.Diagnostic>[],
          ),
        },
      PortableExpressionUnavailable(:final locations) => (
        skir.CheckOutcome.wrapNeedsInput(locations),
        const <skir.Diagnostic>[],
      ),
      PortableExpressionFailed(
        :final failure,
        :final message,
        :final locations,
      ) =>
        (failed(failure, message, locations), const <skir.Diagnostic>[]),
    };
    return AuthoredRuleCheck(
      rule: rule.id,
      subject: subject,
      outcome: outcome,
      findings: findings,
    );
  }

  /// The rule's own finding. A target equal to the recipe pattern is the
  /// subject; any other expands from [owner]. Targets are distinct, the first
  /// is primary, and without targets the subject is primary.
  skir.Diagnostic _finding(
    skir.ConfigurationRecipe recipe,
    skir.OwnedRule rule,
    skir.DiagnosticId id,
    skir.ValueLocation subject, {
    required skir.DataValue ownerValue,
    required skir.ValueLocation owner,
  }) {
    final targets = {
      for (final target in rule.diagnostic.targets)
        ...(target == recipe.relativePath
            ? [subject]
            : ownerValue.expandPattern(owner, target)),
    };
    return skir.Diagnostic(
      id: id,
      origin: rule.id.origin,
      code: rule.diagnostic.code,
      message: rule.diagnostic.message,
      severity: rule.diagnostic.severity,
      primary: targets.firstOrNull ?? subject,
      related: targets.skip(1).toList(),
    );
  }
}
