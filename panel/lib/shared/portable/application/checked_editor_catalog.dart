import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "checked_editor_catalog.freezed.dart";
part "inherited_inspector_catalog.dart";
part "realm_structure.dart";
part "field_presentation_catalog.dart";
part "reference_discovery_catalog.dart";

final class AppliedEditorField {
  const AppliedEditorField({required this.template, required this.type});

  final skir.EffectiveFieldTemplate template;
  final skir.TypeUse? type;

  bool get isAvailable => type != null;
}

final class AppliedEndpointBinding {
  const AppliedEndpointBinding({
    required this.template,
    required this.containingResource,
    required this.target,
  });

  final skir.EndpointBindingTemplate template;
  final skir.NamedTypeUse? containingResource;
  final skir.TypeUse? target;

  bool get isAvailable => containingResource != null && target != null;
}

/// Interprets one published editor catalog snapshot for panel consumers.
///
/// Published types already contain effective fields and ancestor templates.
/// This owner applies their generic arguments, checks readiness and readability,
/// resolves reference contracts and selects presentation material. It also
/// exposes canonical read models from their reserved namespace. It does not
/// fetch catalogs or own editable resource state.
///
/// Presentation selection distinguishes absence, ambiguity and invalid material.
/// Specificity precedes priority, and role fallback advances only when a role
/// has no match. Invalid or conflicting winners stay visible as failures.
/// Cached expression and inheritance checks belong to this snapshot instance.
final class CheckedEditorCatalog {
  CheckedEditorCatalog(this.snapshot)
    : _types = {
        for (final published in snapshot.types)
          published.definition.id: published,
      } {
    for (final id in _types.keys) {
      if (id.typeId case skir.TypeId_qualifiedWrapper(:final value)
          when value.namespace == canonicalReadNamespace) {
        throw const FormatException(
          "Authored declarations cannot use the reserved canonical read namespace",
        );
      }
    }
  }

  final skir.EditorCatalog snapshot;
  final Map<skir.TypeDefinitionId, skir.PublishedType> _types;

  skir.PublishedType? published(skir.TypeDefinitionId id) =>
      _types[id] ?? canonicalReadModels.published(id);

  skir.TypeDisplay? typeDisplay(skir.TypeDefinitionId id) =>
      published(id)?.display;

  skir.TypeDisplay? selectionDisplay(skir.TypeSelection selection) =>
      selected(selection)?.display;

  String typeDefinitionName(skir.TypeDefinitionId definition) {
    final displayName = typeDisplay(definition)?.name.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return switch (definition.typeId) {
      skir.TypeId_qualifiedWrapper(:final value) => value.name,
      skir.TypeId_declaredWrapper(:final value) => value.value,
      _ => "Unknown type",
    };
  }

  String typeUseName(skir.TypeUse type) => switch (type) {
    skir.TypeUse_namedWrapper(:final value) => _namedTypeName(value),
    skir.TypeUse_nullableWrapper(:final value) =>
      "${typeUseName(value.value)}?",
    skir.TypeUse_scalarWrapper(:final value) => _scalarName(value),
    _ => "Unknown type",
  };

  String typeSelectionName(skir.TypeSelection selection) => switch (selection) {
    skir.TypeSelection_completeWrapper(:final value) => _namedTypeName(value),
    skir.TypeSelection_pendingWrapper(:final value) => _pendingTypeName(value),
    _ => "Unknown type",
  };

  String _namedTypeName(skir.NamedTypeUse type) {
    final name = typeDefinitionName(type.definition);
    final arguments = type.arguments.toList(growable: false);
    if (arguments.isEmpty) return name;
    return "$name<${arguments.map(typeUseName).join(", ")}>";
  }

  String _pendingTypeName(skir.PendingTypeSelection type) {
    final name = typeDefinitionName(type.definition);
    final arguments = type.arguments.toList(growable: false);
    if (arguments.isEmpty) return name;
    return "$name<${arguments.map((argument) => switch (argument) {
      skir.ArgumentSelection_chosenWrapper(:final value) => typeUseName(value),
      _ => "Unfilled",
    }).join(", ")}>";
  }

  String _scalarName(skir.ScalarKind scalar) => switch (scalar) {
    skir.ScalarKind.unit => "Unit",
    skir.ScalarKind.boolean => "Boolean",
    skir.ScalarKind.text => "Text",
    skir.ScalarKind.bytes => "Bytes",
    skir.ScalarKind.decimal => "Decimal",
    skir.ScalarKind.timestamp => "Timestamp",
    skir.ScalarKind.duration => "Duration",
    skir.ScalarKind_integerWrapper(:final value) => switch (value.width) {
      skir.IntegerWidth.signedEight => "Signed 8 bit integer",
      skir.IntegerWidth.signedSixteen => "Signed 16 bit integer",
      skir.IntegerWidth.signedThirtyTwo => "Signed 32 bit integer",
      skir.IntegerWidth.signedSixtyFour => "Signed 64 bit integer",
      skir.IntegerWidth.unsignedEight => "Unsigned 8 bit integer",
      skir.IntegerWidth.unsignedSixteen => "Unsigned 16 bit integer",
      skir.IntegerWidth.unsignedThirtyTwo => "Unsigned 32 bit integer",
      skir.IntegerWidth.unsignedSixtyFour => "Unsigned 64 bit integer",
      _ => "Integer",
    },
    skir.ScalarKind_floatWrapper(:final value) => switch (value.width) {
      skir.FloatWidth.thirtyTwo => "32 bit float",
      skir.FloatWidth.sixtyFour => "64 bit float",
      _ => "Float",
    },
    _ => "Unknown type",
  };

  late final Map<skir.PresentationMaterial, CheckedInheritableLayout>
  _inheritableViews = {
    for (final material in snapshot.presentationMaterials)
      material: _checkInheritableLayout(material),
  };

  late final Map<skir.PresentationMaterial, List<_CheckedFieldPresentation>>
  _fieldPresentationIndex = {
    for (final material in snapshot.presentationMaterials)
      material: _checkFieldPresentations(material),
  };

  skir.TypeUse? applyTemplate(
    skir.TypeTemplate template,
    skir.TypeSelection containing,
  ) {
    final definition = selected(containing);
    if (definition == null) return null;
    return _apply(template, _bindings(containing, definition));
  }

  skir.TypeUse? concreteType(skir.TypeTemplate template) =>
      _concreteTemplateType(template);

  /// The type of a binding a presentation declares: [template] closed over
  /// the type arguments of the material [subject], or taken as written when
  /// there is no subject. Null when the catalog cannot apply it, such as for
  /// a pending subject argument.
  skir.TypeUse? declaredBindingType(
    skir.TypeTemplate template,
    skir.TypeSelection? subject,
  ) => subject == null
      ? concreteType(template)
      : applyTemplate(template, subject);

  /// The published placement field of the selected type, or null when the
  /// type declares none. Layout reads and writes go through this path instead
  /// of assuming a field name.
  skir.ValuePath? placementField(skir.TypeSelection selection) =>
      selected(selection)?.placementField;

  skir.PublishedType? selected(skir.TypeSelection selection) =>
      switch (selection.definition) {
        final definition? => published(definition),
        null => null,
      };

  /// Applies effective field templates to the chosen type arguments.
  /// Unfinished arguments leave individual field types unavailable; missing or
  /// unready declarations expose no fields.
  List<AppliedEditorField> fields(skir.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null ||
        definition.status != skir.DeclarationStatus.ready) {
      return const [];
    }
    final bindings = _bindings(selection, definition);
    return [
      for (final field in definition.effectiveFields)
        AppliedEditorField(template: field, type: _apply(field.type, bindings)),
    ];
  }

  /// Resolves a nested value path, using concrete named values when available.
  /// Map rows require an item segment followed by a key or value branch.
  /// Invalid paths or unresolved type applications return null.
  skir.TypeUse? valueTypeAt(
    skir.TypeSelection root,
    skir.ValuePath path, {
    skir.DataValue? value,
  }) {
    var selection = root;
    skir.TypeUse? current;
    var currentValue = value;
    final segments = path.segments.toList(growable: false);
    var index = 0;
    while (index < segments.length) {
      final segment = segments[index];
      switch (segment) {
        case skir.PathSegment_fieldWrapper(:final value):
          final selected = _selectionAtValue(selection, currentValue);
          if (selected == null) return null;
          selection = selected;
          final field = fields(selection)
              .where((candidate) => candidate.template.key == value.name)
              .firstOrNull;
          current = field?.type;
          if (current == null) return null;
          currentValue = _fieldValue(currentValue, value.name);
          index++;
        case skir.PathSegment_itemWrapper():
          final named = _namedValueUse(
            current ??
                (index == 0
                    ? switch (root) {
                        skir.TypeSelection_completeWrapper(:final value) =>
                          skir.TypeUse.wrapNamed(value),
                        _ => null,
                      }
                    : null),
          );
          if (named == null) return null;
          final containing = _selectionForUse(named, currentValue);
          if (containing == null) return null;
          final actual = switch (containing) {
            skir.TypeSelection_completeWrapper(:final value) => value,
            _ => null,
          };
          if (actual == null) return null;
          final representation = published(actual.definition)
              ?.definition
              .representation;
          final payload = _namedPayload(currentValue);
          final itemId = segment.value.id;
          switch (representation) {
            case skir.RepresentationTemplate_sequenceWrapper(:final value):
              current = applyTemplate(value.item, containing);
              currentValue = _collectionItem(payload, itemId);
              index++;
            case skir.RepresentationTemplate_mappingWrapper(:final value):
              if (index + 1 >= segments.length) return null;
              final rowPart = segments[index + 1];
              current = switch (rowPart) {
                skir.PathSegment.mapKey => applyTemplate(value.key, containing),
                skir.PathSegment.mapValue => applyTemplate(
                  value.value,
                  containing,
                ),
                _ => null,
              };
              currentValue = _mapRowValue(payload, itemId, rowPart);
              index += 2;
            default:
              return null;
          }
          if (current == null) return null;
        case skir.PathSegment.mapKey || skir.PathSegment.mapValue:
          return null;
        default:
          return null;
      }
      if (index < segments.length &&
          segments[index] is skir.PathSegment_fieldWrapper) {
        final named = _namedValueUse(current);
        if (named == null) return null;
        final nested = _selectionForUse(named, currentValue);
        if (nested == null) return null;
        selection = nested;
      }
    }
    return current;
  }

  skir.NamedTypeUse? _namedValueUse(skir.TypeUse? type) {
    var current = type;
    while (current is skir.TypeUse_nullableWrapper) {
      current = current.value.value;
    }
    return switch (current) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
  }

  Set<skir.NamedTypeUse> knownApplications(skir.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null ||
        definition.status != skir.DeclarationStatus.ready) {
      return const {};
    }
    final bindings = _bindings(selection, definition);
    final applications = <skir.NamedTypeUse>{};
    final selectedUse = switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (selectedUse != null) applications.add(selectedUse);
    for (final template in definition.ancestorTemplates) {
      final applied = _applyNamed(template, bindings);
      if (applied != null) applications.add(applied);
    }
    return applications;
  }

  List<skir.TypeRecommendation> get recommendations =>
      snapshot.recommendations.toList(growable: false);

  Set<skir.TypeDefinitionId> nominalDefinitions(skir.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null) return const {};
    return {
      definition.definition.id,
      for (final ancestor in definition.ancestorTemplates) ancestor.definition,
    };
  }

  List<AppliedEndpointBinding> endpointBindings(skir.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null) return const [];
    final nominal = nominalDefinitions(selection);
    final bindings = _bindings(selection, definition);
    final known = knownApplications(selection);
    final applied = <AppliedEndpointBinding>[
      for (final template in snapshot.endpointBindings)
        if (nominal.contains(template.containingResource.definition) &&
            _bindingMatchesKnownApplication(
              template.containingResource,
              bindings,
              known,
            ))
          AppliedEndpointBinding(
            template: template,
            containingResource: _applyNamed(
              template.containingResource,
              bindings,
            ),
            target: _apply(template.target, bindings),
          ),
    ];
    // A concrete declaration's binding carries its overridden field type.
    // Ancestor bindings at the same occurrence must not widen that contract.
    return applied
        .where(
          (candidate) => !applied.any(
            (other) =>
                other.template.endpoint == candidate.template.endpoint &&
                other.template.relativePath ==
                    candidate.template.relativePath &&
                other.template.containingResource.definition !=
                    candidate.template.containingResource.definition &&
                isNominalSubtype(
                  other.template.containingResource.definition,
                  candidate.template.containingResource.definition,
                ),
          ),
        )
        .toList(growable: false);
  }

  List<AppliedEndpointBinding> endpointBindingsAt(
    skir.TypeSelection selection,
    skir.ValuePath path,
  ) => endpointBindings(selection)
      .where(
        (binding) => _patternMatchesPath(binding.template.relativePath, path),
      )
      .toList(growable: false);

  skir.NamedTypeUse? namedUse(skir.TypeUse? type) => _namedValueUse(type);

  skir.TypeUse? collectionItemType(skir.TypeUse? type) {
    final named = _namedValueUse(type);
    if (named == null) return null;
    final representation = published(named.definition)
        ?.definition
        .representation;
    if (representation case skir.RepresentationTemplate_sequenceWrapper(
      :final value,
    )) {
      return applyTemplate(value.item, skir.TypeSelection.wrapComplete(named));
    }
    return null;
  }

  List<skir.ConfigurationRecipe> configuration(skir.TypeSelection selection) {
    final owners = nominalDefinitions(selection);
    return [
      for (final recipe in snapshot.configuration)
        if (owners.contains(recipe.origin.owner)) recipe,
    ];
  }

  skir.RepresentationKind? representationKindAt(
    skir.TypeSelection root,
    skir.ValuePath path, {
    skir.DataValue? value,
  }) {
    if (path.segments.isEmpty) return representationKind(root);
    return _representationKindForUse(valueTypeAt(root, path, value: value));
  }

  skir.TypeSelection beginSelection(skir.TypeDefinitionId definition) {
    final published = this.published(definition);
    if (published == null || published.status != skir.DeclarationStatus.ready) {
      return skir.TypeSelection.unknown;
    }
    final count = published.definition.parameters.length;
    if (count == 0) {
      return skir.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      );
    }
    return skir.TypeSelection.createPending(
      definition: definition,
      arguments: List.filled(count, skir.ArgumentSelection.unfilled),
    );
  }

  bool isAbstractRecordSelection(skir.TypeSelection selection) =>
      switch (selected(selection)?.definition.representation) {
        skir.RepresentationTemplate_recordWrapper(:final value) =>
          value.abstract_,
        _ => false,
      };

  List<skir.TypeSelection> concreteRecordSelections(
    skir.TypeSelection expected,
  ) {
    final root = selected(expected)?.definition.id;
    if (root == null) return const [];
    final selections = <skir.TypeSelection>[];
    for (final published in snapshot.types) {
      final representation = published.definition.representation;
      if (published.status != skir.DeclarationStatus.ready ||
          representation is! skir.RepresentationTemplate_recordWrapper ||
          representation.value.abstract_ ||
          !isNominalSubtype(published.definition.id, root)) {
        continue;
      }
      selections.add(beginSelection(published.definition.id));
    }
    return selections;
  }

  TypeArgumentChoice chooseArgument(
    skir.TypeSelection selection,
    int index,
    skir.TypeUse argument,
  ) {
    final published = selected(selection);
    if (published == null || published.status != skir.DeclarationStatus.ready) {
      return const TypeArgumentChoice.rejected(
        "The selected type is unavailable",
      );
    }
    final parameters = published.definition.parameters.toList();
    if (index < 0 || index >= parameters.length) {
      return const TypeArgumentChoice.rejected(
        "The type argument position is invalid",
      );
    }
    final arguments = argumentSelections(selection, parameters.length);
    arguments[index] = skir.ArgumentSelection.wrapChosen(argument);
    final pending = skir.TypeSelection.createPending(
      definition: published.definition.id,
      arguments: arguments,
    );
    final bindings = _bindings(pending, published);
    var complete = true;
    for (var position = 0; position < parameters.length; position++) {
      final chosenArgument = switch (arguments[position]) {
        skir.ArgumentSelection_chosenWrapper(:final value) => value,
        _ => null,
      };
      if (chosenArgument == null) {
        complete = false;
        continue;
      }
      for (final bound in parameters[position].bounds) {
        final expected = _apply(bound, bindings);
        if (expected == null) {
          complete = false;
          continue;
        }
        if (!isReadableAs(chosenArgument, expected)) {
          return const TypeArgumentChoice.rejected(
            "The type argument does not satisfy its bound",
          );
        }
      }
    }
    if (!complete) return TypeArgumentChoice.accepted(pending);
    final chosen = <skir.TypeUse>[];
    for (final selection in arguments) {
      chosen.add((selection as skir.ArgumentSelection_chosenWrapper).value);
    }
    return TypeArgumentChoice.accepted(
      skir.TypeSelection.createComplete(
        definition: published.definition.id,
        arguments: chosen,
      ),
    );
  }

  skir.TypeSelection clearArgument(skir.TypeSelection selection, int index) {
    final published = selected(selection);
    if (published == null) return skir.TypeSelection.unknown;
    final arguments = argumentSelections(
      selection,
      published.definition.parameters.length,
    );
    if (index < 0 || index >= arguments.length) return selection;
    arguments[index] = skir.ArgumentSelection.unfilled;
    return skir.TypeSelection.createPending(
      definition: published.definition.id,
      arguments: arguments,
    );
  }

  bool selectionMatches(skir.TypeSelection actual, skir.TypeUse? expected) =>
      switch (actual) {
        skir.TypeSelection_completeWrapper(:final value)
            when expected != null =>
          isReadableAs(skir.TypeUse.wrapNamed(value), expected),
        _ => false,
      };

  /// Checks nominal readability and nullable widening for valid type uses.
  /// This relation does not prove declaration readiness or argument bounds;
  /// callers admitting external types must use [isReadyApplication] as well.
  bool isReadableAs(skir.TypeUse actual, skir.TypeUse expected) =>
      _isReadableAs(actual, expected, 0);

  bool isReadyApplication(skir.NamedTypeUse application) =>
      _isReadyApplication(application, 0);

  bool _isReadyApplication(skir.NamedTypeUse application, int depth) {
    if (depth > _maximumCheckedTypeDepth) return false;
    final published = this.published(application.definition);
    if (published == null || published.status != skir.DeclarationStatus.ready) {
      return false;
    }
    final parameters = published.definition.parameters.toList(growable: false);
    final arguments = application.arguments.toList(growable: false);
    if (parameters.length != arguments.length) return false;
    for (final argument in arguments) {
      if (!_isReadyTypeUse(argument, depth + 1)) return false;
    }
    final selection = skir.TypeSelection.wrapComplete(application);
    final bindings = _bindings(selection, published);
    for (var index = 0; index < parameters.length; index++) {
      for (final bound in parameters[index].bounds) {
        final expected = _apply(bound, bindings);
        if (expected == null || !isReadableAs(arguments[index], expected)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isReadyTypeUse(skir.TypeUse use, int depth) {
    if (depth > _maximumCheckedTypeDepth) return false;
    return switch (use) {
      skir.TypeUse_scalarWrapper(:final value) => _isReadyScalar(value),
      skir.TypeUse_nullableWrapper(:final value) => _isReadyTypeUse(
        value.value,
        depth + 1,
      ),
      skir.TypeUse_namedWrapper(:final value) => _isReadyApplication(
        value,
        depth + 1,
      ),
      _ => false,
    };
  }

  bool _isReadyScalar(skir.ScalarKind scalar) {
    if (scalar case skir.ScalarKind_integerWrapper(:final value)) {
      return value.width != skir.IntegerWidth.unknown;
    }
    if (scalar case skir.ScalarKind_floatWrapper(:final value)) {
      return value.width != skir.FloatWidth.unknown;
    }
    return scalar == skir.ScalarKind.unit ||
        scalar == skir.ScalarKind.boolean ||
        scalar == skir.ScalarKind.text ||
        scalar == skir.ScalarKind.bytes ||
        scalar == skir.ScalarKind.decimal ||
        scalar == skir.ScalarKind.timestamp ||
        scalar == skir.ScalarKind.duration;
  }

  bool _isReadableAs(skir.TypeUse actual, skir.TypeUse expected, int depth) {
    if (depth > 64) return false;
    if (actual == expected) return true;
    if (expected case skir.TypeUse_nullableWrapper(:final value)) {
      final expectedValue = value.value;
      if (actual case skir.TypeUse_nullableWrapper(:final value)) {
        return _isReadableAs(value.value, expectedValue, depth + 1);
      }
      return _isReadableAs(actual, expectedValue, depth + 1);
    }
    if (actual case skir.TypeUse_namedWrapper(:final value)) {
      if (expected case skir.TypeUse_namedWrapper(value: final expectedUse)) {
        final selection = skir.TypeSelection.wrapComplete(value);
        return knownApplications(selection).any(
          (application) =>
              application.definition == expectedUse.definition &&
              application.arguments.length == expectedUse.arguments.length &&
              _argumentsReadableAs(
                application.arguments,
                expectedUse.arguments,
                depth + 1,
              ),
        );
      }
    }
    return false;
  }

  bool _argumentsReadableAs(
    Iterable<skir.TypeUse> actual,
    Iterable<skir.TypeUse> expected,
    int depth,
  ) {
    final actualArguments = actual.toList(growable: false);
    final expectedArguments = expected.toList(growable: false);
    for (var index = 0; index < actualArguments.length; index++) {
      if (!_isReadableAs(
        actualArguments[index],
        expectedArguments[index],
        depth + 1,
      )) {
        return false;
      }
    }
    return true;
  }

  bool matchesNamedTemplate(
    skir.TypeSelection actual,
    skir.NamedTypeTemplate expected,
  ) => _namedPresentationTargetMatches(expected, actual);

  bool _templateMatchesUse(
    skir.NamedTypeTemplate expected,
    skir.NamedTypeUse actual,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
  ) =>
      expected.definition == actual.definition &&
      expected.arguments.length == actual.arguments.length &&
      _templatesMatchUses(expected.arguments, actual.arguments, bindings);

  bool _templatesMatchUses(
    Iterable<skir.TypeTemplate> expected,
    Iterable<skir.TypeUse> actual,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
  ) {
    final expectedList = expected.toList();
    final actualList = actual.toList();
    for (var index = 0; index < expectedList.length; index++) {
      if (!_templateMatches(expectedList[index], actualList[index], bindings)) {
        return false;
      }
    }
    return true;
  }

  bool _templateMatches(
    skir.TypeTemplate expected,
    skir.TypeUse actual,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
  ) => switch (expected) {
    skir.TypeTemplate_parameterWrapper(:final value) =>
      bindings[value] == null
          ? (bindings[value] = actual) == actual
          : bindings[value] == actual,
    skir.TypeTemplate_scalarWrapper(:final value) =>
      actual == skir.TypeUse.wrapScalar(value),
    skir.TypeTemplate_nullableWrapper(:final value) =>
      actual is skir.TypeUse_nullableWrapper &&
          _templateMatches(value.value, actual.value.value, bindings),
    skir.TypeTemplate_namedWrapper(:final value) =>
      actual is skir.TypeUse_namedWrapper &&
          (_templateMatchesUse(value, actual.value, bindings) ||
              knownApplications(skir.TypeSelection.wrapComplete(actual.value))
                  .any(
                    (application) =>
                        _templateMatchesUse(value, application, bindings),
                  )),
    _ => false,
  };

  /// Whether [actual] is [expected] or declares it among its ancestors.
  /// Unavailable declarations break the chain.
  bool isNominalSubtype(
    skir.TypeDefinitionId actual,
    skir.TypeDefinitionId expected,
  ) {
    if (actual == expected) return true;
    final pending = <skir.TypeDefinitionId>[actual];
    final visited = <skir.TypeDefinitionId>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) continue;
      final published = this.published(current);
      if (published == null ||
          published.status != skir.DeclarationStatus.ready) {
        continue;
      }
      for (final parent in published.ancestorTemplates) {
        if (parent.definition == expected) return true;
        pending.add(parent.definition);
      }
    }
    return false;
  }

  bool _namedTemplateSubsumes(
    skir.NamedTypeTemplate broader,
    skir.NamedTypeTemplate narrower,
  ) => _namedTemplateSubsumesWithBindings(
    broader,
    narrower,
    <skir.ParameterKey, skir.TypeTemplate>{},
  );

  bool _namedTemplateSubsumesWithBindings(
    skir.NamedTypeTemplate broader,
    skir.NamedTypeTemplate narrower,
    Map<skir.ParameterKey, skir.TypeTemplate> bindings,
  ) {
    if (broader.definition != narrower.definition ||
        broader.arguments.length != narrower.arguments.length) {
      return false;
    }
    final broaderArguments = broader.arguments.toList();
    final narrowerArguments = narrower.arguments.toList();
    for (var index = 0; index < broaderArguments.length; index++) {
      if (!_templateSubsumes(
        broaderArguments[index],
        narrowerArguments[index],
        bindings,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _templateSubsumes(
    skir.TypeTemplate broader,
    skir.TypeTemplate narrower,
    Map<skir.ParameterKey, skir.TypeTemplate> bindings,
  ) => switch (broader) {
    skir.TypeTemplate_parameterWrapper(:final value) =>
      bindings[value] == null
          ? (bindings[value] = narrower) == narrower
          : bindings[value] == narrower,
    skir.TypeTemplate_scalarWrapper(:final value) =>
      narrower is skir.TypeTemplate_scalarWrapper && narrower.value == value,
    skir.TypeTemplate_nullableWrapper(:final value) =>
      narrower is skir.TypeTemplate_nullableWrapper &&
          _templateSubsumes(value.value, narrower.value.value, bindings),
    skir.TypeTemplate_namedWrapper(:final value) =>
      narrower is skir.TypeTemplate_namedWrapper &&
          (_namedTemplateSubsumesWithBindings(
                value,
                narrower.value,
                bindings,
              ) ||
              _concreteTemplateReadableAs(narrower.value, value)),
    _ => false,
  };

  bool _concreteTemplateReadableAs(
    skir.NamedTypeTemplate actual,
    skir.NamedTypeTemplate expected,
  ) {
    final actualUse = _concreteTemplateUse(actual);
    final expectedUse = _concreteTemplateUse(expected);
    return actualUse != null &&
        expectedUse != null &&
        isReadableAs(
          skir.TypeUse.wrapNamed(actualUse),
          skir.TypeUse.wrapNamed(expectedUse),
        );
  }

  skir.NamedTypeUse? _concreteTemplateUse(skir.NamedTypeTemplate template) {
    final arguments = <skir.TypeUse>[];
    for (final argument in template.arguments) {
      final applied = switch (argument) {
        skir.TypeTemplate_scalarWrapper(:final value) =>
          skir.TypeUse.wrapScalar(value),
        skir.TypeTemplate_nullableWrapper(:final value) =>
          _concreteTemplateType(value.value, nullable: true),
        skir.TypeTemplate_namedWrapper() => _concreteTemplateType(argument),
        _ => null,
      };
      if (applied == null) return null;
      arguments.add(applied);
    }
    return skir.NamedTypeUse(
      definition: template.definition,
      arguments: arguments,
    );
  }

  skir.TypeUse? _concreteTemplateType(
    skir.TypeTemplate template, {
    bool nullable = false,
  }) {
    final use = switch (template) {
      skir.TypeTemplate_scalarWrapper(:final value) => skir.TypeUse.wrapScalar(
        value,
      ),
      skir.TypeTemplate_namedWrapper(:final value) =>
        switch (_concreteTemplateUse(value)) {
          final named? => skir.TypeUse.wrapNamed(named),
          _ => null,
        },
      skir.TypeTemplate_nullableWrapper(:final value) => _concreteTemplateType(
        value.value,
        nullable: true,
      ),
      _ => null,
    };
    if (use == null || !nullable) return use;
    return skir.TypeUse.wrapNullable(skir.NullableTypeUse(value: use));
  }

  skir.RepresentationKind? representationKind(skir.TypeSelection selection) =>
      _representationKind(selected(selection)?.definition.representation);

  skir.RepresentationKind? _representationKindForUse(skir.TypeUse? use) {
    var current = use;
    while (current is skir.TypeUse_nullableWrapper) {
      current = current.value.value;
    }
    return switch (current) {
      skir.TypeUse_scalarWrapper(:final value) => _scalarRepresentation(value),
      skir.TypeUse_namedWrapper(:final value) => _representationKind(
        published(value.definition)?.definition.representation,
      ),
      _ => null,
    };
  }

  skir.RepresentationKind? _representationKind(
    skir.RepresentationTemplate? representation,
  ) => switch (representation) {
    skir.RepresentationTemplate_scalarWrapper(:final value) =>
      switch (value.kind) {
        final kind => _scalarRepresentation(kind),
      },
    skir.RepresentationTemplate_recordWrapper() =>
      skir.RepresentationKind.record,
    skir.RepresentationTemplate_sequenceWrapper(:final value) =>
      value.kind == skir.CollectionKind.list
          ? skir.RepresentationKind.list
          : skir.RepresentationKind.set_,
    skir.RepresentationTemplate_mappingWrapper() => skir.RepresentationKind.map,
    skir.RepresentationTemplate_enumerationWrapper() =>
      skir.RepresentationKind.enumeration,
    skir.RepresentationTemplate_linkWrapper() => skir.RepresentationKind.link,
    _ => null,
  };

  skir.RepresentationKind? _scalarRepresentation(skir.ScalarKind kind) =>
      switch (kind) {
        skir.ScalarKind.unit => skir.RepresentationKind.unit,
        skir.ScalarKind.boolean => skir.RepresentationKind.boolean,
        skir.ScalarKind.text => skir.RepresentationKind.text,
        skir.ScalarKind.bytes => skir.RepresentationKind.bytes,
        skir.ScalarKind_integerWrapper() => skir.RepresentationKind.integer,
        skir.ScalarKind_floatWrapper() => skir.RepresentationKind.float,
        skir.ScalarKind.decimal => skir.RepresentationKind.decimal,
        skir.ScalarKind.timestamp => skir.RepresentationKind.timestamp,
        skir.ScalarKind.duration => skir.RepresentationKind.duration,
        _ => null,
      };

  bool _bindingMatchesKnownApplication(
    skir.NamedTypeTemplate template,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
    Set<skir.NamedTypeUse> known,
  ) {
    final applied = _applyNamed(template, bindings);
    if (applied != null) return known.contains(applied);
    return true;
  }

  Map<skir.ParameterKey, skir.TypeUse> _bindings(
    skir.TypeSelection selection,
    skir.PublishedType definition,
  ) {
    final result = <skir.ParameterKey, skir.TypeUse>{};
    final arguments = switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) => [
        for (final argument in value.arguments)
          skir.ArgumentSelection.wrapChosen(argument),
      ],
      skir.TypeSelection_pendingWrapper(:final value) =>
        value.arguments.toList(),
      _ => const <skir.ArgumentSelection>[],
    };
    final parameters = definition.definition.parameters.toList();
    for (
      var index = 0;
      index < parameters.length && index < arguments.length;
      index++
    ) {
      if (arguments[index] case skir.ArgumentSelection_chosenWrapper(
        :final value,
      )) {
        result[parameters[index].key] = value;
      }
    }
    for (final ancestor in definition.ancestorTemplates) {
      final applied = _applyNamed(ancestor, result);
      if (applied == null) continue;
      final publishedAncestor = published(applied.definition);
      if (publishedAncestor == null) continue;
      final ancestorParameters = publishedAncestor.definition.parameters
          .toList();
      final ancestorArguments = applied.arguments.toList();
      for (
        var index = 0;
        index < ancestorParameters.length && index < ancestorArguments.length;
        index++
      ) {
        result[ancestorParameters[index].key] = ancestorArguments[index];
      }
    }
    return result;
  }

  skir.TypeUse? _apply(
    skir.TypeTemplate template,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
  ) => switch (template) {
    skir.TypeTemplate_parameterWrapper(:final value) => bindings[value],
    skir.TypeTemplate_namedWrapper(:final value) => switch (_applyNamed(
      value,
      bindings,
    )) {
      final applied? => skir.TypeUse.wrapNamed(applied),
      null => null,
    },
    skir.TypeTemplate_nullableWrapper(:final value) => switch (_apply(
      value.value,
      bindings,
    )) {
      final applied? => skir.TypeUse.createNullable(value: applied),
      null => null,
    },
    skir.TypeTemplate_scalarWrapper(:final value) => skir.TypeUse.wrapScalar(
      value,
    ),
    _ => null,
  };

  skir.NamedTypeUse? _applyNamed(
    skir.NamedTypeTemplate template,
    Map<skir.ParameterKey, skir.TypeUse> bindings,
  ) {
    final arguments = <skir.TypeUse>[];
    for (final argument in template.arguments) {
      final applied = _apply(argument, bindings);
      if (applied == null) return null;
      arguments.add(applied);
    }
    return skir.NamedTypeUse(
      definition: template.definition,
      arguments: arguments,
    );
  }
}

const _maximumCheckedTypeDepth = 512;

bool _patternMatchesPath(
  skir.RelativeFieldPattern pattern,
  skir.ValuePath path,
) {
  final expected = pattern.segments.toList(growable: false);
  final actual = path.segments.toList(growable: false);
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    final matches = switch ((expected[index], actual[index])) {
      (
        skir.FieldPatternSegment_fieldWrapper(value: final field),
        skir.PathSegment_fieldWrapper(value: final segment),
      ) =>
        field.name == segment.name,
      (final pattern, skir.PathSegment_itemWrapper())
          when pattern == skir.FieldPatternSegment.items =>
        true,
      (final pattern, final segment)
          when pattern == skir.FieldPatternSegment.keys =>
        segment == skir.PathSegment.mapKey,
      (final pattern, final segment)
          when pattern == skir.FieldPatternSegment.values =>
        segment == skir.PathSegment.mapValue,
      _ => false,
    };
    if (!matches) return false;
  }
  return true;
}

/// Whether a type argument choice was admitted into the pending selection.
@freezed
sealed class TypeArgumentChoice with _$TypeArgumentChoice {
  const factory TypeArgumentChoice.accepted(skir.TypeSelection selection) =
      TypeArgumentAccepted;
  const factory TypeArgumentChoice.rejected(String message) =
      TypeArgumentRejected;
}

/// The argument selections of [selection], padded with unfilled selections or
/// cut to [count] parameters.
List<skir.ArgumentSelection> argumentSelections(
  skir.TypeSelection selection,
  int count,
) {
  final current = switch (selection) {
    skir.TypeSelection_completeWrapper(:final value) => [
      for (final argument in value.arguments)
        skir.ArgumentSelection.wrapChosen(argument),
    ],
    skir.TypeSelection_pendingWrapper(:final value) => value.arguments.toList(),
    _ => <skir.ArgumentSelection>[],
  };
  return List.generate(
    count,
    (index) => index < current.length
        ? current[index]
        : skir.ArgumentSelection.unfilled,
  );
}
