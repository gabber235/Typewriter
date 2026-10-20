import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_appearance.freezed.dart";

/// How one resource names and marks itself on every surface: the evaluated
/// label, accent and icon of the most specific display declared for its type.
@freezed
abstract class ResourceAppearance with _$ResourceAppearance {
  const factory ResourceAppearance({
    required String label,
    required Color accent,
    required skir.Icon icon,
  }) = _ResourceAppearance;
}

/// Binds an appearance as the canonical read model resource presentations
/// read through [presentationSubjectAppearanceBindingId].
extension ResourceAppearanceBinding on ResourceAppearance {
  skir.DataValue toExpressionValue() => skir.DataValue.createNamed(
    actualType: canonicalReadModels.resourceAppearanceUse,
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "label",
          value: skir.DataValue.wrapStringValue(label),
        ),
        skir.FieldValue(name: "accent", value: colorValue(accent.toARGB32())),
        skir.FieldValue(name: "icon", value: iconValue(icon)),
      ],
    ),
  );

  PortableExpressionBinding toExpressionBinding() => PortableExpressionBinding(
    value: toExpressionValue(),
    schema: CompletePortablePresentationBinding(
      skir.TypeUse.wrapNamed(canonicalReadModels.resourceAppearanceUse),
    ),
  );
}

/// The display Realm publishes for a type that declares none: [name] with the
/// framework default icon and color.
skir.TypeDisplay defaultTypeDisplay(String name) => skir.TypeDisplay(
  name: name,
  description: "",
  icon: skir.Icon.wrapIconify("material-symbols:category"),
  color: skir.Color(argb: 0xFF607D8B),
);

/// Display formulas read their subject through the configured value binding.
final _subjectBinding = skir.ExpressionBindingId(value: "configured_value");

/// A display names a resource from a few fields; this bounds a pathological
/// formula rather than a real one.
final _displayBudget = skir.EvaluationBudget(
  maxSteps: 2048,
  maxCollectionItems: 256,
);

extension ResourceAppearanceCatalog on CheckedEditorCatalog {
  /// The formulas of the most specific display declared for [selection]: the
  /// display whose target type is the most specific nominal supertype of the
  /// selected type. When no typed display applies, or two unrelated ones apply
  /// equally, the any resource display applies, as Realm decides. Null only
  /// for a catalog that declares no displays at all.
  skir.ResourceDisplayFormulas? displayFormulasFor(
    skir.TypeSelection selection,
  ) {
    final selected = nominalDefinitions(selection);
    final applicable = [
      for (final display in snapshot.resourceDisplays)
        if (display.targetDefinition case final target?
            when selected.contains(target))
          display,
    ];
    final mostSpecific = applicable
        .where(
          (candidate) => applicable.every(
            (other) =>
                _nominalDefinitionsOf(candidate.targetDefinition!)
                    .contains(other.targetDefinition),
          ),
        )
        .toList(growable: false);
    if (mostSpecific.length == 1) return mostSpecific.single;
    return snapshot.resourceDisplays
        .where((display) => display.target == skir.ResourceTarget.anyResource)
        .firstOrNull;
  }

  /// Name, accent and icon of [record] from its most specific display.
  ///
  /// Display formulas read only their subject, so the record alone names the
  /// resource. A formula that cannot be evaluated, or a catalog without
  /// displays, yields the matching part of the record's type display.
  ResourceAppearance appearanceOf(skir.AuthoringRecord record) {
    final display =
        selectionDisplay(record.configuration) ??
        defaultTypeDisplay(typeSelectionName(record.configuration));
    final formulas = displayFormulasFor(record.configuration);
    final queries = PortableExpressionQueries(catalog: this);
    final bindings = {
      _subjectBinding: PortableExpressionBinding(
        value: _subjectValue(record),
        schema: switch (record.configuration) {
          skir.TypeSelection_completeWrapper(:final value) =>
            CompletePortablePresentationBinding(skir.TypeUse.wrapNamed(value)),
          final selection => PartialPortablePresentationBinding(selection),
        },
      ),
    };
    skir.DataValue? evaluate(skir.ExpressionNode? formula) {
      if (formula == null) return null;
      return switch (evaluateExpression(
        formula,
        bindings: bindings,
        budget: _displayBudget,
        queries: queries,
      )) {
        PortableExpressionAvailable(:final value) => value,
        _ => null,
      };
    }

    final label = evaluate(formulas?.label)?.authoredString;
    final accent = evaluate(formulas?.accent)?.authoredInteger;
    final icon = switch (evaluate(formulas?.icon)) {
      final value? => decodeIconValue(value),
      null => null,
    };
    final name = label ?? display.name;
    return ResourceAppearance(
      label: name.trim().isEmpty
          ? typeSelectionName(record.configuration)
          : name,
      accent: Color(
        (accent ?? BigInt.from(display.color.argb)).toUnsigned(32).toInt(),
      ),
      icon: icon ?? display.icon,
    );
  }

  Set<skir.TypeDefinitionId> _nominalDefinitionsOf(
    skir.TypeDefinitionId definition,
  ) => {
    definition,
    for (final ancestor
        in published(definition)?.ancestorTemplates ??
            const <skir.NamedTypeTemplate>[])
      ancestor.definition,
  };
}

/// The resource [view] holds at [id] with its appearance; null when the
/// resource is absent, so callers render their own missing state.
ResourceAppearance? resourceAppearanceIn(
  CheckedEditorCatalog catalog,
  PortableAuthoringView view,
  skir.ResourceId id,
) => switch (view.resource(id)) {
  final record? => catalog.appearanceOf(record),
  null => null,
};

skir.DataValue _subjectValue(skir.AuthoringRecord record) {
  final payload = skir.DataValue.createRecord(fields: record.fields);
  return switch (record.configuration) {
    skir.TypeSelection_completeWrapper(:final value) =>
      skir.DataValue.createNamed(actualType: value, payload: payload),
    _ => payload,
  };
}

extension on skir.ResourceDisplayFormulas {
  skir.TypeDefinitionId? get targetDefinition => switch (target) {
    skir.ResourceTarget_typeWrapper(
      value: skir.TypeTemplate_namedWrapper(:final value),
    ) =>
      value.definition,
    _ => null,
  };
}
