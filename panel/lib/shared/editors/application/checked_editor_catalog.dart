import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

final class AppliedEditorField {
  const AppliedEditorField({required this.template, required this.type});

  final catalog.EffectiveFieldTemplate template;
  final types.TypeUse? type;

  bool get isAvailable => type != null;
}

final class AppliedEndpointBinding {
  const AppliedEndpointBinding({
    required this.template,
    required this.containingResource,
    required this.target,
  });

  final catalog.EndpointBindingTemplate template;
  final types.NamedTypeUse? containingResource;
  final types.TypeUse? target;

  bool get isAvailable => containingResource != null && target != null;
}

sealed class EditorPresentationSelection {
  const EditorPresentationSelection();
}

final class SelectedEditorPresentation extends EditorPresentationSelection {
  const SelectedEditorPresentation({
    required this.requestedRole,
    required this.resolvedRole,
    required this.descriptor,
    required this.material,
  });

  final catalog.PresentationRole requestedRole;
  final catalog.PresentationRole resolvedRole;
  final catalog.PresentationDescriptor descriptor;
  final catalog.PresentationMaterial material;
}

final class MissingEditorPresentation extends EditorPresentationSelection {
  const MissingEditorPresentation(this.requestedRole);

  final catalog.PresentationRole requestedRole;
}

final class ConflictingEditorPresentation extends EditorPresentationSelection {
  const ConflictingEditorPresentation({
    required this.role,
    required this.candidates,
  });

  final catalog.PresentationRole role;
  final List<types.PresentationId> candidates;
}

final class UnavailableEditorPresentation extends EditorPresentationSelection {
  const UnavailableEditorPresentation({
    required this.role,
    required this.presentation,
  });

  final catalog.PresentationRole role;
  final types.PresentationId presentation;
}

sealed class EditorFieldPresentationSelection {
  const EditorFieldPresentationSelection();
}

final class SelectedEditorFieldPresentation
    extends EditorFieldPresentationSelection {
  const SelectedEditorFieldPresentation(this.presentation);

  final types.PresentationId presentation;
}

final class ConflictingEditorFieldPresentation
    extends EditorFieldPresentationSelection {
  const ConflictingEditorFieldPresentation(this.presentations);

  final List<types.PresentationId> presentations;
}

final class CheckedEditorCatalog {
  CheckedEditorCatalog(this.snapshot)
    : _types = {
        for (final published in snapshot.types)
          published.definition.id: published,
      };

  final catalog.EditorCatalogWireSnapshot snapshot;
  final Map<types.TypeDefinitionId, catalog.PublishedType> _types;

  catalog.PublishedType? published(types.TypeDefinitionId id) => _types[id];

  catalog.TypeDisplay? typeDisplay(types.TypeDefinitionId id) =>
      _types[id]?.display;

  catalog.TypeDisplay? selectionDisplay(types.TypeSelection selection) =>
      selected(selection)?.display;

  String typeDefinitionName(types.TypeDefinitionId definition) {
    final displayName = typeDisplay(definition)?.name.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return switch (definition.typeId) {
      types.TypeId_qualifiedWrapper(:final value) => value.name,
      types.TypeId_declaredWrapper(:final value) => value.value,
      _ => "Unknown type",
    };
  }

  String typeUseName(types.TypeUse type) => switch (type) {
    types.TypeUse_namedWrapper(:final value) => _namedTypeName(value),
    types.TypeUse_nullableWrapper(:final value) =>
      "${typeUseName(value.value)}?",
    types.TypeUse_scalarWrapper(:final value) => _scalarName(value),
    _ => "Unknown type",
  };

  String typeSelectionName(
    types.TypeSelection selection,
  ) => switch (selection) {
    types.TypeSelection_completeWrapper(:final value) => _namedTypeName(value),
    types.TypeSelection_pendingWrapper(:final value) => _pendingTypeName(value),
    _ => "Unknown type",
  };

  String _namedTypeName(types.NamedTypeUse type) {
    final name = typeDefinitionName(type.definition);
    final arguments = type.arguments.toList(growable: false);
    if (arguments.isEmpty) return name;
    return "$name<${arguments.map(typeUseName).join(", ")}>";
  }

  String _pendingTypeName(types.PendingTypeSelection type) {
    final name = typeDefinitionName(type.definition);
    final arguments = type.arguments.toList(growable: false);
    if (arguments.isEmpty) return name;
    return "$name<${arguments.map((argument) => switch (argument) {
      types.ArgumentSelection_chosenWrapper(:final value) => typeUseName(value),
      _ => "Unfilled",
    }).join(", ")}>";
  }

  String _scalarName(types.ScalarKind scalar) => switch (scalar) {
    types.ScalarKind.unit => "Unit",
    types.ScalarKind.boolean => "Boolean",
    types.ScalarKind.text => "Text",
    types.ScalarKind.bytes => "Bytes",
    types.ScalarKind.decimal => "Decimal",
    types.ScalarKind.timestamp => "Timestamp",
    types.ScalarKind.duration => "Duration",
    types.ScalarKind_integerWrapper(:final value) => switch (value.width) {
      types.IntegerWidth.signedEight => "Signed 8 bit integer",
      types.IntegerWidth.signedSixteen => "Signed 16 bit integer",
      types.IntegerWidth.signedThirtyTwo => "Signed 32 bit integer",
      types.IntegerWidth.signedSixtyFour => "Signed 64 bit integer",
      types.IntegerWidth.unsignedEight => "Unsigned 8 bit integer",
      types.IntegerWidth.unsignedSixteen => "Unsigned 16 bit integer",
      types.IntegerWidth.unsignedThirtyTwo => "Unsigned 32 bit integer",
      types.IntegerWidth.unsignedSixtyFour => "Unsigned 64 bit integer",
      _ => "Integer",
    },
    types.ScalarKind_floatWrapper(:final value) => switch (value.width) {
      types.FloatWidth.thirtyTwo => "32 bit float",
      types.FloatWidth.sixtyFour => "64 bit float",
      _ => "Float",
    },
    _ => "Unknown type",
  };

  List<catalog.PresentationRole> roleFallbackOrder(
    catalog.PresentationRole requested,
  ) {
    final parents = {
      for (final fallback in snapshot.roleFallbacks)
        fallback.role: fallback.parents.toList(growable: false),
    };
    final pending = <catalog.PresentationRole>[requested];
    final visited = <catalog.PresentationRole>{};
    final ordered = <catalog.PresentationRole>[];
    while (pending.isNotEmpty) {
      final current = pending.removeAt(0);
      if (!visited.add(current)) continue;
      ordered.add(current);
      pending.addAll(parents[current] ?? const []);
    }
    return List.unmodifiable(ordered);
  }

  EditorPresentationSelection selectPresentation(
    types.TypeSelection actual,
    catalog.PresentationRole requested,
  ) {
    for (final role in roleFallbackOrder(requested)) {
      final selected = _selectWithinRole(actual, role);
      if (selected case MissingEditorPresentation()) continue;
      if (selected case SelectedEditorPresentation(
        :final descriptor,
        :final material,
      )) {
        return SelectedEditorPresentation(
          requestedRole: requested,
          resolvedRole: role,
          descriptor: descriptor,
          material: material,
        );
      }
      return selected;
    }
    return MissingEditorPresentation(requested);
  }

  catalog.PresentationMaterial? presentationMaterial(
    types.PresentationId id,
    types.TypeSelection actual,
  ) => snapshot.presentationMaterials
      .where(
        (material) =>
            material.provider == id &&
            _presentationTargetMatches(material.target, actual),
      )
      .firstOrNull;

  Map<types.ValuePath, EditorFieldPresentationSelection> fieldPresentations(
    types.TypeSelection actual,
    catalog.PresentationRole role,
  ) {
    final candidates = <types.ValuePath, List<_FieldPresentationCandidate>>{};
    for (final material in snapshot.presentationMaterials) {
      if (material.role != role ||
          !_presentationTargetMatches(material.target, actual)) {
        continue;
      }
      final descriptor = snapshot.presentations
          .where((candidate) => candidate.id == material.provider)
          .firstOrNull;
      if (descriptor == null) continue;
      for (final selection in _explicitFieldSelections(material.layout)) {
        candidates
            .putIfAbsent(selection.path, () => [])
            .add(
              _FieldPresentationCandidate(
                presentation: selection.presentation,
                target: material.target,
                priority: descriptor.priority,
              ),
            );
      }
    }
    return {
      for (final entry in candidates.entries)
        entry.key: _selectFieldPresentation(entry.value),
    };
  }

  EditorFieldPresentationSelection _selectFieldPresentation(
    List<_FieldPresentationCandidate> candidates,
  ) {
    final maximal = candidates
        .where(
          (candidate) => !candidates.any(
            (other) =>
                other != candidate &&
                _isMoreSpecific(other.target, candidate.target),
          ),
        )
        .toList(growable: false);
    final presentations = maximal
        .map((candidate) => candidate.presentation)
        .toSet();
    if (presentations.length == 1) {
      return SelectedEditorFieldPresentation(presentations.single);
    }
    if (maximal
        .skip(1)
        .any(
          (candidate) => !_presentationTargetsEquivalent(
            maximal.first.target,
            candidate.target,
          ),
        )) {
      return ConflictingEditorFieldPresentation(
        List.unmodifiable(presentations),
      );
    }
    final priority = maximal
        .map((candidate) => candidate.priority)
        .reduce((left, right) => left > right ? left : right);
    final winners = maximal
        .where((candidate) => candidate.priority == priority)
        .map((candidate) => candidate.presentation)
        .toSet();
    return winners.length == 1
        ? SelectedEditorFieldPresentation(winners.single)
        : ConflictingEditorFieldPresentation(List.unmodifiable(winners));
  }

  bool isPresentationCompatible(
    catalog.PresentationTarget target,
    types.TypeSelection actual,
  ) => _presentationTargetMatches(target, actual);

  types.TypeUse? applyTemplate(
    types.TypeTemplate template,
    types.TypeSelection containing,
  ) {
    final definition = selected(containing);
    if (definition == null) return null;
    return _apply(template, _bindings(containing, definition));
  }

  types.TypeUse? concreteType(types.TypeTemplate template) =>
      _concreteTemplateType(template);

  bool hasConstructorDefault(types.FieldOwner owner) {
    final definition = _types[owner.definition];
    final representation = definition?.definition.representation;
    if (representation case types.RepresentationTemplate_recordWrapper(
      :final value,
    )) {
      return value.fields
              .where((field) => field.owner == owner)
              .firstOrNull
              ?.hasConstructorDefault ??
          false;
    }
    return false;
  }

  catalog.PublishedType? selected(types.TypeSelection selection) {
    final definition = switch (selection) {
      types.TypeSelection_completeWrapper(:final value) => value.definition,
      types.TypeSelection_pendingWrapper(:final value) => value.definition,
      _ => null,
    };
    return definition == null ? null : _types[definition];
  }

  List<AppliedEditorField> fields(types.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null ||
        definition.status != catalog.DeclarationStatus.ready) {
      return const [];
    }
    final bindings = _bindings(selection, definition);
    return [
      for (final field in definition.effectiveFields)
        AppliedEditorField(template: field, type: _apply(field.type, bindings)),
    ];
  }

  types.TypeUse? valueTypeAt(
    types.TypeSelection root,
    types.ValuePath path, {
    types.DataValue? value,
  }) {
    var selection = root;
    types.TypeUse? current;
    var currentValue = value;
    final segments = path.segments.toList(growable: false);
    var index = 0;
    while (index < segments.length) {
      final segment = segments[index];
      switch (segment) {
        case types.PathSegment_fieldWrapper(:final value):
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
        case types.PathSegment_itemWrapper():
          final named = _namedValueUse(current);
          if (named == null) return null;
          final containing = _selectionForUse(named, currentValue);
          if (containing == null) return null;
          final actual = switch (containing) {
            types.TypeSelection_completeWrapper(:final value) => value,
            _ => null,
          };
          if (actual == null) return null;
          final representation = published(actual.definition)
              ?.definition
              .representation;
          final payload = _namedPayload(currentValue);
          final itemId = segment.value.id;
          switch (representation) {
            case types.RepresentationTemplate_sequenceWrapper(:final value):
              current = applyTemplate(value.item, containing);
              currentValue = _collectionItem(payload, itemId);
              index++;
            case types.RepresentationTemplate_mappingWrapper(:final value):
              if (index + 1 >= segments.length) return null;
              final rowPart = segments[index + 1];
              current = switch (rowPart) {
                types.PathSegment.mapKey => applyTemplate(
                  value.key,
                  containing,
                ),
                types.PathSegment.mapValue => applyTemplate(
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
        case types.PathSegment.mapKey || types.PathSegment.mapValue:
          return null;
        default:
          return null;
      }
      if (index < segments.length &&
          segments[index] is types.PathSegment_fieldWrapper) {
        final named = _namedValueUse(current);
        if (named == null) return null;
        final nested = _selectionForUse(named, currentValue);
        if (nested == null) return null;
        selection = nested;
      }
    }
    return current;
  }

  types.TypeSelection? _selectionAtValue(
    types.TypeSelection declared,
    types.DataValue? value,
  ) {
    if (value case types.DataValue_namedWrapper(:final value)) {
      final actual = value.actualType;
      final compatible = switch (declared) {
        types.TypeSelection_completeWrapper(:final value) => isReadableAs(
          types.TypeUse.wrapNamed(actual),
          types.TypeUse.wrapNamed(value),
        ),
        types.TypeSelection_pendingWrapper() =>
          knownApplications(types.TypeSelection.wrapComplete(actual)).any(
            (candidate) => knownApplications(declared).any(
              (expected) => isReadableAs(
                types.TypeUse.wrapNamed(candidate),
                types.TypeUse.wrapNamed(expected),
              ),
            ),
          ),
        _ => false,
      };
      return compatible ? types.TypeSelection.wrapComplete(actual) : null;
    }
    return declared;
  }

  types.TypeSelection? _selectionForUse(
    types.NamedTypeUse declared,
    types.DataValue? value,
  ) {
    if (value case types.DataValue_namedWrapper(:final value)) {
      if (!isReadableAs(
        types.TypeUse.wrapNamed(value.actualType),
        types.TypeUse.wrapNamed(declared),
      )) {
        return null;
      }
      return types.TypeSelection.wrapComplete(value.actualType);
    }
    return types.TypeSelection.wrapComplete(declared);
  }

  types.DataValue? _namedPayload(types.DataValue? value) => switch (value) {
    types.DataValue_namedWrapper(:final value) => value.payload,
    _ => value,
  };

  types.DataValue? _fieldValue(types.DataValue? value, String name) {
    final payload = _namedPayload(value);
    final fields = switch (payload) {
      types.DataValue_recordWrapper(:final value) =>
        value.fields
            .where((field) => field.name == name)
            .toList(growable: false),
      _ => const <types.FieldValue>[],
    };
    return fields.length == 1 ? fields.single.value : null;
  }

  types.DataValue? _collectionItem(types.DataValue? value, types.ItemId id) {
    final items = switch (value) {
      types.DataValue_listValueWrapper(:final value) => value.items,
      types.DataValue_setValueWrapper(:final value) => value.items,
      _ => const <types.ListItem>[],
    };
    final matching = items
        .where((candidate) => candidate.id == id)
        .toList(growable: false);
    return matching.length == 1 ? matching.single.value : null;
  }

  types.DataValue? _mapRowValue(
    types.DataValue? value,
    types.ItemId id,
    types.PathSegment branch,
  ) {
    final rows = switch (value) {
      types.DataValue_mapValueWrapper(:final value) =>
        value.rows
            .where((candidate) => candidate.id == id)
            .toList(growable: false),
      _ => const <types.MapRow>[],
    };
    if (rows.length != 1) return null;
    return switch (branch) {
      final value when value == types.PathSegment.mapKey => rows.single.key,
      final value when value == types.PathSegment.mapValue => rows.single.value,
      _ => null,
    };
  }

  types.NamedTypeUse? _namedValueUse(types.TypeUse? type) {
    var current = type;
    while (current is types.TypeUse_nullableWrapper) {
      current = current.value.value;
    }
    return switch (current) {
      types.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
  }

  Set<types.NamedTypeUse> knownApplications(types.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null ||
        definition.status != catalog.DeclarationStatus.ready) {
      return const {};
    }
    final bindings = _bindings(selection, definition);
    final applications = <types.NamedTypeUse>{};
    final selectedUse = switch (selection) {
      types.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (selectedUse != null) applications.add(selectedUse);
    for (final template in definition.ancestorTemplates) {
      final applied = _applyNamed(template, bindings);
      if (applied != null) applications.add(applied);
    }
    return applications;
  }

  List<catalog.TypeRecommendation> get recommendations =>
      snapshot.recommendations.toList(growable: false);

  catalog.InitializationDescriptor? initialization(
    types.TypeDefinitionId definition,
  ) => snapshot.initialization
      .where((descriptor) => descriptor.definition == definition)
      .firstOrNull;

  catalog.AuthoringResourceDefinition? resourceDefinition(
    types.TypeSelection selection,
  ) {
    final definitions = nominalDefinitions(selection);
    return snapshot.resourceDefinitions
        .where((resource) => definitions.contains(resource.root))
        .firstOrNull;
  }

  bool isResourceDefinition(
    types.TypeSelection selection,
    catalog.ResourceDefinitionId id,
  ) {
    final definitions = nominalDefinitions(selection);
    return snapshot.resourceDefinitions.any(
      (resource) => resource.id == id && definitions.contains(resource.root),
    );
  }

  Set<types.TypeDefinitionId> nominalDefinitions(
    types.TypeSelection selection,
  ) {
    final definition = selected(selection);
    if (definition == null) return const {};
    return {
      definition.definition.id,
      for (final ancestor in definition.ancestorTemplates) ancestor.definition,
    };
  }

  List<AppliedEndpointBinding> endpointBindings(types.TypeSelection selection) {
    final definition = selected(selection);
    if (definition == null) return const [];
    final nominal = nominalDefinitions(selection);
    final bindings = _bindings(selection, definition);
    final known = knownApplications(selection);
    return [
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
  }

  List<AppliedEndpointBinding> endpointBindingsAt(
    types.TypeSelection selection,
    types.ValuePath path,
  ) => endpointBindings(selection)
      .where(
        (binding) => _patternMatchesPath(binding.template.relativePath, path),
      )
      .toList(growable: false);

  types.NamedTypeUse? namedUse(types.TypeUse? type) => _namedValueUse(type);

  types.TypeUse? collectionItemType(types.TypeUse? type) {
    final named = _namedValueUse(type);
    if (named == null) return null;
    final representation = published(named.definition)
        ?.definition
        .representation;
    if (representation case types.RepresentationTemplate_sequenceWrapper(
      :final value,
    )) {
      return applyTemplate(value.item, types.TypeSelection.wrapComplete(named));
    }
    return null;
  }

  List<catalog.ConfigurationRecipe> configuration(
    types.TypeSelection selection,
  ) {
    final owners = nominalDefinitions(selection);
    return [
      for (final recipe in snapshot.configuration)
        if (owners.contains(recipe.origin.owner)) recipe,
    ];
  }

  catalog.RepresentationKind? representationKindAt(
    types.TypeSelection root,
    types.ValuePath path, {
    types.DataValue? value,
  }) {
    if (path.segments.isEmpty) return representationKind(root);
    return _representationKindForUse(valueTypeAt(root, path, value: value));
  }

  types.TypeSelection beginSelection(types.TypeDefinitionId definition) {
    final published = _types[definition];
    if (published == null ||
        published.status != catalog.DeclarationStatus.ready) {
      return types.TypeSelection.unknown;
    }
    final count = published.definition.parameters.length;
    if (count == 0) {
      return types.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      );
    }
    return types.TypeSelection.createPending(
      definition: definition,
      arguments: List.filled(count, types.ArgumentSelection.unfilled),
    );
  }

  bool isAbstractRecordSelection(types.TypeSelection selection) =>
      switch (selected(selection)?.definition.representation) {
        types.RepresentationTemplate_recordWrapper(:final value) =>
          value.abstract_,
        _ => false,
      };

  List<types.TypeSelection> concreteRecordSelections(
    types.TypeSelection expected,
  ) {
    final root = selected(expected)?.definition.id;
    if (root == null) return const [];
    final selections = <types.TypeSelection>[];
    for (final published in snapshot.types) {
      final representation = published.definition.representation;
      if (published.status != catalog.DeclarationStatus.ready ||
          representation is! types.RepresentationTemplate_recordWrapper ||
          representation.value.abstract_ ||
          !_isNominalSubtype(published.definition.id, root)) {
        continue;
      }
      selections.add(beginSelection(published.definition.id));
    }
    return selections;
  }

  TypeArgumentChoice chooseArgument(
    types.TypeSelection selection,
    int index,
    types.TypeUse argument,
  ) {
    final published = selected(selection);
    if (published == null ||
        published.status != catalog.DeclarationStatus.ready) {
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
    final arguments = _argumentSelections(selection, parameters.length);
    arguments[index] = types.ArgumentSelection.wrapChosen(argument);
    final pending = types.TypeSelection.createPending(
      definition: published.definition.id,
      arguments: arguments,
    );
    final bindings = _bindings(pending, published);
    var complete = true;
    for (var position = 0; position < parameters.length; position++) {
      final chosenArgument = switch (arguments[position]) {
        types.ArgumentSelection_chosenWrapper(:final value) => value,
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
    final chosen = <types.TypeUse>[];
    for (final selection in arguments) {
      chosen.add((selection as types.ArgumentSelection_chosenWrapper).value);
    }
    return TypeArgumentChoice.accepted(
      types.TypeSelection.createComplete(
        definition: published.definition.id,
        arguments: chosen,
      ),
    );
  }

  types.TypeSelection clearArgument(types.TypeSelection selection, int index) {
    final published = selected(selection);
    if (published == null) return types.TypeSelection.unknown;
    final arguments = _argumentSelections(
      selection,
      published.definition.parameters.length,
    );
    if (index < 0 || index >= arguments.length) return selection;
    arguments[index] = types.ArgumentSelection.unfilled;
    return types.TypeSelection.createPending(
      definition: published.definition.id,
      arguments: arguments,
    );
  }

  bool isReadableAs(types.TypeUse actual, types.TypeUse expected) =>
      _isReadableAs(actual, expected, 0);

  /// Whether a complete named use is valid in this checked snapshot.
  ///
  /// Equality and nominal readability assume their inputs are valid type uses.
  /// This boundary also proves that every referenced declaration is ready,
  /// every application has the declared arity, and every applied argument
  /// satisfies its parameter bounds.
  bool isReadyApplication(types.NamedTypeUse application) =>
      _isReadyApplication(application, 0);

  bool _isReadyApplication(types.NamedTypeUse application, int depth) {
    if (depth > _maximumCheckedTypeDepth) return false;
    final published = _types[application.definition];
    if (published == null ||
        published.status != catalog.DeclarationStatus.ready) {
      return false;
    }
    final parameters = published.definition.parameters.toList(growable: false);
    final arguments = application.arguments.toList(growable: false);
    if (parameters.length != arguments.length) return false;
    for (final argument in arguments) {
      if (!_isReadyTypeUse(argument, depth + 1)) return false;
    }
    final selection = types.TypeSelection.wrapComplete(application);
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

  bool _isReadyTypeUse(types.TypeUse use, int depth) {
    if (depth > _maximumCheckedTypeDepth) return false;
    return switch (use) {
      types.TypeUse_scalarWrapper(:final value) => _isReadyScalar(value),
      types.TypeUse_nullableWrapper(:final value) => _isReadyTypeUse(
        value.value,
        depth + 1,
      ),
      types.TypeUse_namedWrapper(:final value) => _isReadyApplication(
        value,
        depth + 1,
      ),
      _ => false,
    };
  }

  bool _isReadyScalar(types.ScalarKind scalar) {
    if (scalar case types.ScalarKind_integerWrapper(:final value)) {
      return value.width != types.IntegerWidth.unknown;
    }
    if (scalar case types.ScalarKind_floatWrapper(:final value)) {
      return value.width != types.FloatWidth.unknown;
    }
    return scalar == types.ScalarKind.unit ||
        scalar == types.ScalarKind.boolean ||
        scalar == types.ScalarKind.text ||
        scalar == types.ScalarKind.bytes ||
        scalar == types.ScalarKind.decimal ||
        scalar == types.ScalarKind.timestamp ||
        scalar == types.ScalarKind.duration;
  }

  bool _isReadableAs(types.TypeUse actual, types.TypeUse expected, int depth) {
    if (depth > 64) return false;
    if (actual == expected) return true;
    if (expected case types.TypeUse_nullableWrapper(:final value)) {
      final expectedValue = value.value;
      if (actual case types.TypeUse_nullableWrapper(:final value)) {
        return _isReadableAs(value.value, expectedValue, depth + 1);
      }
      return _isReadableAs(actual, expectedValue, depth + 1);
    }
    if (actual case types.TypeUse_namedWrapper(:final value)) {
      if (expected case types.TypeUse_namedWrapper(value: final expectedUse)) {
        final selection = types.TypeSelection.wrapComplete(value);
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
    Iterable<types.TypeUse> actual,
    Iterable<types.TypeUse> expected,
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

  EditorPresentationSelection _selectWithinRole(
    types.TypeSelection actual,
    catalog.PresentationRole role,
  ) {
    final matching = snapshot.presentations
        .where(
          (descriptor) =>
              descriptor.roles.contains(role) &&
              _presentationTargetMatches(descriptor.target, actual),
        )
        .toList(growable: false);
    if (matching.isEmpty) return MissingEditorPresentation(role);
    final maximal = matching
        .where(
          (candidate) => !matching.any(
            (other) =>
                other != candidate &&
                _isMoreSpecific(other.target, candidate.target),
          ),
        )
        .toList(growable: false);
    if (maximal.length > 1 &&
        maximal
            .skip(1)
            .any(
              (candidate) => !_presentationTargetsEquivalent(
                maximal.first.target,
                candidate.target,
              ),
            )) {
      return ConflictingEditorPresentation(
        role: role,
        candidates: List.unmodifiable(maximal.map((candidate) => candidate.id)),
      );
    }
    final priority = maximal
        .map((candidate) => candidate.priority)
        .reduce((left, right) => left > right ? left : right);
    final winners = maximal
        .where((candidate) => candidate.priority == priority)
        .toList(growable: false);
    if (winners.length != 1) {
      return ConflictingEditorPresentation(
        role: role,
        candidates: List.unmodifiable(winners.map((candidate) => candidate.id)),
      );
    }
    final descriptor = winners.single;
    final material = snapshot.presentationMaterials
        .where(
          (candidate) =>
              candidate.provider == descriptor.id && candidate.role == role,
        )
        .firstOrNull;
    if (material == null) {
      return UnavailableEditorPresentation(
        role: role,
        presentation: descriptor.id,
      );
    }
    return SelectedEditorPresentation(
      requestedRole: role,
      resolvedRole: role,
      descriptor: descriptor,
      material: material,
    );
  }

  bool _presentationTargetMatches(
    catalog.PresentationTarget target,
    types.TypeSelection actual,
  ) => switch (target) {
    catalog.PresentationTarget_namedWrapper(:final value) =>
      _namedPresentationTargetMatches(value, actual),
    catalog.PresentationTarget_representationWrapper(:final value) =>
      representationKind(actual) == value,
    _ => false,
  };

  bool _namedPresentationTargetMatches(
    types.NamedTypeTemplate target,
    types.TypeSelection actual,
  ) {
    for (final application in knownApplications(actual)) {
      if (_templateMatchesUse(
        target,
        application,
        <types.ParameterKey, types.TypeUse>{},
      )) {
        return true;
      }
    }
    if (actual case types.TypeSelection_pendingWrapper(:final value)) {
      if (target.definition != value.definition ||
          target.arguments.length != value.arguments.length) {
        return false;
      }
      final bindings = <types.ParameterKey, types.TypeUse>{};
      final expectedArguments = target.arguments.toList();
      final actualArguments = value.arguments.toList();
      for (var index = 0; index < expectedArguments.length; index++) {
        switch (actualArguments[index]) {
          case types.ArgumentSelection_chosenWrapper(:final value):
            if (!_templateMatches(expectedArguments[index], value, bindings)) {
              return false;
            }
          case final argument when argument == types.ArgumentSelection.unfilled:
            if (expectedArguments[index]
                is! types.TypeTemplate_parameterWrapper) {
              return false;
            }
          default:
            return false;
        }
      }
      return true;
    }
    return false;
  }

  bool matchesNamedTemplate(
    types.TypeSelection actual,
    types.NamedTypeTemplate expected,
  ) => _namedPresentationTargetMatches(expected, actual);

  bool _templateMatchesUse(
    types.NamedTypeTemplate expected,
    types.NamedTypeUse actual,
    Map<types.ParameterKey, types.TypeUse> bindings,
  ) =>
      expected.definition == actual.definition &&
      expected.arguments.length == actual.arguments.length &&
      _templatesMatchUses(expected.arguments, actual.arguments, bindings);

  bool _templatesMatchUses(
    Iterable<types.TypeTemplate> expected,
    Iterable<types.TypeUse> actual,
    Map<types.ParameterKey, types.TypeUse> bindings,
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
    types.TypeTemplate expected,
    types.TypeUse actual,
    Map<types.ParameterKey, types.TypeUse> bindings,
  ) => switch (expected) {
    types.TypeTemplate_parameterWrapper(:final value) =>
      bindings[value] == null
          ? (bindings[value] = actual) == actual
          : bindings[value] == actual,
    types.TypeTemplate_scalarWrapper(:final value) =>
      actual == types.TypeUse.wrapScalar(value),
    types.TypeTemplate_nullableWrapper(:final value) =>
      actual is types.TypeUse_nullableWrapper &&
          _templateMatches(value.value, actual.value.value, bindings),
    types.TypeTemplate_namedWrapper(:final value) =>
      actual is types.TypeUse_namedWrapper &&
          (_templateMatchesUse(value, actual.value, bindings) ||
              knownApplications(types.TypeSelection.wrapComplete(actual.value))
                  .any(
                    (application) =>
                        _templateMatchesUse(value, application, bindings),
                  )),
    _ => false,
  };

  bool _isMoreSpecific(
    catalog.PresentationTarget left,
    catalog.PresentationTarget right,
  ) {
    if (left is catalog.PresentationTarget_namedWrapper &&
        right is catalog.PresentationTarget_representationWrapper) {
      return true;
    }
    if (left is! catalog.PresentationTarget_namedWrapper ||
        right is! catalog.PresentationTarget_namedWrapper) {
      return false;
    }
    final leftDefinition = left.value.definition;
    final rightDefinition = right.value.definition;
    if (leftDefinition != rightDefinition) {
      return _isNominalSubtype(leftDefinition, rightDefinition) &&
          !_isNominalSubtype(rightDefinition, leftDefinition);
    }
    final rightSubsumesLeft = _namedTemplateSubsumes(right.value, left.value);
    final leftSubsumesRight = _namedTemplateSubsumes(left.value, right.value);
    return rightSubsumesLeft && !leftSubsumesRight;
  }

  bool _presentationTargetsEquivalent(
    catalog.PresentationTarget left,
    catalog.PresentationTarget right,
  ) => switch ((left, right)) {
    (
      catalog.PresentationTarget_namedWrapper(:final value),
      catalog.PresentationTarget_namedWrapper(value: final rightValue),
    ) =>
      _namedTemplateSubsumes(value, rightValue) &&
          _namedTemplateSubsumes(rightValue, value),
    (
      catalog.PresentationTarget_representationWrapper(:final value),
      catalog.PresentationTarget_representationWrapper(value: final rightValue),
    ) =>
      value == rightValue,
    _ => false,
  };

  bool _isNominalSubtype(
    types.TypeDefinitionId actual,
    types.TypeDefinitionId expected,
  ) {
    if (actual == expected) return true;
    final pending = <types.TypeDefinitionId>[actual];
    final visited = <types.TypeDefinitionId>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) continue;
      final published = _types[current];
      if (published == null ||
          published.status != catalog.DeclarationStatus.ready) {
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
    types.NamedTypeTemplate broader,
    types.NamedTypeTemplate narrower,
  ) => _namedTemplateSubsumesWithBindings(
    broader,
    narrower,
    <types.ParameterKey, types.TypeTemplate>{},
  );

  bool _namedTemplateSubsumesWithBindings(
    types.NamedTypeTemplate broader,
    types.NamedTypeTemplate narrower,
    Map<types.ParameterKey, types.TypeTemplate> bindings,
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
    types.TypeTemplate broader,
    types.TypeTemplate narrower,
    Map<types.ParameterKey, types.TypeTemplate> bindings,
  ) => switch (broader) {
    types.TypeTemplate_parameterWrapper(:final value) =>
      bindings[value] == null
          ? (bindings[value] = narrower) == narrower
          : bindings[value] == narrower,
    types.TypeTemplate_scalarWrapper(:final value) =>
      narrower is types.TypeTemplate_scalarWrapper && narrower.value == value,
    types.TypeTemplate_nullableWrapper(:final value) =>
      narrower is types.TypeTemplate_nullableWrapper &&
          _templateSubsumes(value.value, narrower.value.value, bindings),
    types.TypeTemplate_namedWrapper(:final value) =>
      narrower is types.TypeTemplate_namedWrapper &&
          (_namedTemplateSubsumesWithBindings(
                value,
                narrower.value,
                bindings,
              ) ||
              _concreteTemplateReadableAs(narrower.value, value)),
    _ => false,
  };

  bool _concreteTemplateReadableAs(
    types.NamedTypeTemplate actual,
    types.NamedTypeTemplate expected,
  ) {
    final actualUse = _concreteTemplateUse(actual);
    final expectedUse = _concreteTemplateUse(expected);
    return actualUse != null &&
        expectedUse != null &&
        isReadableAs(
          types.TypeUse.wrapNamed(actualUse),
          types.TypeUse.wrapNamed(expectedUse),
        );
  }

  types.NamedTypeUse? _concreteTemplateUse(types.NamedTypeTemplate template) {
    final arguments = <types.TypeUse>[];
    for (final argument in template.arguments) {
      final applied = switch (argument) {
        types.TypeTemplate_scalarWrapper(:final value) =>
          types.TypeUse.wrapScalar(value),
        types.TypeTemplate_nullableWrapper(:final value) =>
          _concreteTemplateType(value.value, nullable: true),
        types.TypeTemplate_namedWrapper() => _concreteTemplateType(argument),
        _ => null,
      };
      if (applied == null) return null;
      arguments.add(applied);
    }
    return types.NamedTypeUse(
      definition: template.definition,
      arguments: arguments,
    );
  }

  types.TypeUse? _concreteTemplateType(
    types.TypeTemplate template, {
    bool nullable = false,
  }) {
    final use = switch (template) {
      types.TypeTemplate_scalarWrapper(:final value) =>
        types.TypeUse.wrapScalar(value),
      types.TypeTemplate_namedWrapper(:final value) =>
        switch (_concreteTemplateUse(value)) {
          final named? => types.TypeUse.wrapNamed(named),
          _ => null,
        },
      types.TypeTemplate_nullableWrapper(:final value) => _concreteTemplateType(
        value.value,
        nullable: true,
      ),
      _ => null,
    };
    if (use == null || !nullable) return use;
    return types.TypeUse.wrapNullable(types.NullableTypeUse(value: use));
  }

  catalog.RepresentationKind? representationKind(
    types.TypeSelection selection,
  ) => _representationKind(selected(selection)?.definition.representation);

  catalog.RepresentationKind? _representationKindForUse(types.TypeUse? use) {
    var current = use;
    while (current is types.TypeUse_nullableWrapper) {
      current = current.value.value;
    }
    return switch (current) {
      types.TypeUse_scalarWrapper(:final value) => _scalarRepresentation(value),
      types.TypeUse_namedWrapper(:final value) => _representationKind(
        published(value.definition)?.definition.representation,
      ),
      _ => null,
    };
  }

  catalog.RepresentationKind? _representationKind(
    types.RepresentationTemplate? representation,
  ) => switch (representation) {
    types.RepresentationTemplate_scalarWrapper(:final value) =>
      switch (value.kind) {
        final kind => _scalarRepresentation(kind),
      },
    types.RepresentationTemplate_recordWrapper() =>
      catalog.RepresentationKind.record,
    types.RepresentationTemplate_sequenceWrapper(:final value) =>
      value.kind == types.CollectionKind.list
          ? catalog.RepresentationKind.list
          : catalog.RepresentationKind.set_,
    types.RepresentationTemplate_mappingWrapper() =>
      catalog.RepresentationKind.map,
    types.RepresentationTemplate_enumerationWrapper() =>
      catalog.RepresentationKind.enumeration,
    types.RepresentationTemplate_linkWrapper() =>
      catalog.RepresentationKind.link,
    _ => null,
  };

  catalog.RepresentationKind? _scalarRepresentation(types.ScalarKind kind) =>
      switch (kind) {
        types.ScalarKind.unit => catalog.RepresentationKind.unit,
        types.ScalarKind.boolean => catalog.RepresentationKind.boolean,
        types.ScalarKind.text => catalog.RepresentationKind.text,
        types.ScalarKind.bytes => catalog.RepresentationKind.bytes,
        types.ScalarKind_integerWrapper() => catalog.RepresentationKind.integer,
        types.ScalarKind_floatWrapper() => catalog.RepresentationKind.float,
        types.ScalarKind.decimal => catalog.RepresentationKind.decimal,
        types.ScalarKind.timestamp => catalog.RepresentationKind.timestamp,
        types.ScalarKind.duration => catalog.RepresentationKind.duration,
        _ => null,
      };

  bool _bindingMatchesKnownApplication(
    types.NamedTypeTemplate template,
    Map<types.ParameterKey, types.TypeUse> bindings,
    Set<types.NamedTypeUse> known,
  ) {
    final applied = _applyNamed(template, bindings);
    if (applied != null) return known.contains(applied);
    return true;
  }

  Map<types.ParameterKey, types.TypeUse> _bindings(
    types.TypeSelection selection,
    catalog.PublishedType definition,
  ) {
    final result = <types.ParameterKey, types.TypeUse>{};
    final arguments = switch (selection) {
      types.TypeSelection_completeWrapper(:final value) => [
        for (final argument in value.arguments)
          types.ArgumentSelection.wrapChosen(argument),
      ],
      types.TypeSelection_pendingWrapper(:final value) =>
        value.arguments.toList(),
      _ => const <types.ArgumentSelection>[],
    };
    final parameters = definition.definition.parameters.toList();
    for (
      var index = 0;
      index < parameters.length && index < arguments.length;
      index++
    ) {
      if (arguments[index] case types.ArgumentSelection_chosenWrapper(
        :final value,
      )) {
        result[parameters[index].key] = value;
      }
    }
    for (final ancestor in definition.ancestorTemplates) {
      final applied = _applyNamed(ancestor, result);
      if (applied == null) continue;
      final publishedAncestor = _types[applied.definition];
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

  types.TypeUse? _apply(
    types.TypeTemplate template,
    Map<types.ParameterKey, types.TypeUse> bindings,
  ) => switch (template) {
    types.TypeTemplate_parameterWrapper(:final value) => bindings[value],
    types.TypeTemplate_namedWrapper(:final value) => switch (_applyNamed(
      value,
      bindings,
    )) {
      final applied? => types.TypeUse.wrapNamed(applied),
      null => null,
    },
    types.TypeTemplate_nullableWrapper(:final value) => switch (_apply(
      value.value,
      bindings,
    )) {
      final applied? => types.TypeUse.createNullable(value: applied),
      null => null,
    },
    types.TypeTemplate_scalarWrapper(:final value) => types.TypeUse.wrapScalar(
      value,
    ),
    _ => null,
  };

  types.NamedTypeUse? _applyNamed(
    types.NamedTypeTemplate template,
    Map<types.ParameterKey, types.TypeUse> bindings,
  ) {
    final arguments = <types.TypeUse>[];
    for (final argument in template.arguments) {
      final applied = _apply(argument, bindings);
      if (applied == null) return null;
      arguments.add(applied);
    }
    return types.NamedTypeUse(
      definition: template.definition,
      arguments: arguments,
    );
  }

  List<types.ArgumentSelection> _argumentSelections(
    types.TypeSelection selection,
    int count,
  ) {
    final current = switch (selection) {
      types.TypeSelection_completeWrapper(:final value) => [
        for (final argument in value.arguments)
          types.ArgumentSelection.wrapChosen(argument),
      ],
      types.TypeSelection_pendingWrapper(:final value) =>
        value.arguments.toList(),
      _ => <types.ArgumentSelection>[],
    };
    return List.generate(
      count,
      (index) => index < current.length
          ? current[index]
          : types.ArgumentSelection.unfilled,
    );
  }
}

const _maximumCheckedTypeDepth = 512;

final class _FieldPresentationCandidate {
  const _FieldPresentationCandidate({
    required this.presentation,
    required this.target,
    required this.priority,
  });

  final types.PresentationId presentation;
  final catalog.PresentationTarget target;
  final int priority;
}

final class _ExplicitFieldPresentation {
  const _ExplicitFieldPresentation({
    required this.path,
    required this.presentation,
  });

  final types.ValuePath path;
  final types.PresentationId presentation;
}

Iterable<_ExplicitFieldPresentation> _explicitFieldSelections(
  presentation.PresentationNode root,
) sync* {
  final pending = <presentation.PresentationNode>[root];
  while (pending.isNotEmpty) {
    final node = pending.removeLast();
    final element = node.element;
    if (element
        case presentation.PresentationElement_defaultPresentationWrapper(
          :final value,
        )) {
      final id = value.presentationId;
      if (id != null &&
          value.binding.bindingId.value == "configured_value" &&
          value.binding.path.segments.isNotEmpty) {
        yield _ExplicitFieldPresentation(
          path: value.binding.path,
          presentation: id,
        );
      }
    }
    pending.addAll(_nestedPresentationNodes(node));
  }
}

Iterable<presentation.PresentationNode> _nestedPresentationNodes(
  presentation.PresentationNode node,
) sync* {
  final title = node.header?.title;
  if (title case presentation.PresentationHeaderTitle_presentationWrapper(
    :final value,
  )) {
    yield value;
  }
  final element = node.element;
  switch (element) {
    case presentation.PresentationElement_childrenWrapper(:final value):
      yield* _childrenNodes(value);
    case presentation.PresentationElement_sectionWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_paddingWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_tabsWrapper(:final value):
      for (final tab in value.tabs) {
        yield tab.child;
      }
    case presentation.PresentationElement_typedFieldWrapper(:final value):
      if (value.presentation case final child?) yield child;
    case presentation.PresentationElement_conditionalWrapper(:final value):
      yield value.whenTrue;
      if (value.whenFalse case final child?) yield child;
    case presentation.PresentationElement_repeatedWrapper(:final value):
      yield* _sequenceNodes(value.presentation);
    case presentation.PresentationElement_scopedBindingWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_textInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_numericInputWrapper(:final value):
      yield* _boundControlNodes(value);
    case presentation.PresentationElement_toggleInputWrapper(:final value):
      yield* _boundControlNodes(value);
    case presentation.PresentationElement_selectInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_sliderInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_dateTimeInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_durationInputWrapper(:final value):
      yield* _boundControlNodes(value);
    case presentation.PresentationElement_colorInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_bytesInputWrapper(:final value):
      yield* _boundControlNodes(value);
    case presentation.PresentationElement_namedInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.payloadPresentation case final child?) yield child;
    case presentation.PresentationElement_tooltipWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_listInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.itemPresentation case final child?) yield child;
    case presentation.PresentationElement_setInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.itemPresentation case final child?) yield child;
    case presentation.PresentationElement_mapInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.keyPresentation case final child?) yield child;
      if (value.valuePresentation case final child?) yield child;
    case presentation.PresentationElement_recordInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.fieldPresentation case final child?) yield child;
    case presentation.PresentationElement_polymorphicInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      for (final option in value.concreteTypes) {
        if (option.presentation case final child?) yield child;
      }
    case presentation.PresentationElement_searchInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.summary case final child?) yield child;
      yield* _searchProviderNodes(value.provider);
    case presentation.PresentationElement_collectionLookupWrapper(:final value):
      yield value.found;
      yield value.missing;
      if (value.loading case final child?) yield child;
    case presentation.PresentationElement_collectionGraphWrapper(:final value):
      yield* _sequenceNodes(value.rootSequence);
      yield value.node;
      yield* _sequenceNodes(value.children);
    case presentation.PresentationElement_containerWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_anchorWrapper(:final value):
      yield value.child;
    case presentation.PresentationElement_connectionLayerWrapper(:final value):
      yield value.child;
      for (final connection in value.connections) {
        yield* _connectionNodes(connection);
      }
    case presentation.PresentationElement_polymorphicMatchWrapper(:final value):
      for (final item in value.cases) {
        yield item.child;
      }
      if (value.fallback case final child?) yield child;
    case presentation.PresentationElement_linkInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_adaptiveLeadingWrapper(:final value):
      yield value.leading;
      if (value.center case final child?) yield child;
      if (value.suffix case final child?) yield child;
    case presentation.PresentationElement_nullableInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.valuePresentation case final child?) yield child;
    case presentation.PresentationElement_pageGraphWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case presentation.PresentationElement_pageTimelineWrapper(:final value):
      yield* _boundControlNodes(value.control);
    default:
      break;
  }
}

Iterable<presentation.PresentationNode> _childrenNodes(
  presentation.ChildrenElement children,
) sync* {
  switch (children) {
    case presentation.ChildrenElement_columnWrapper(:final value) ||
        presentation.ChildrenElement_rowWrapper(:final value):
      for (final child in value.children) {
        switch (child) {
          case presentation.AxisChild_fixedWrapper(:final value):
            yield value;
          case presentation.AxisChild_flexibleWrapper(:final value):
            yield value.child;
          default:
            break;
        }
      }
    case presentation.ChildrenElement_wrapWrapper(:final value):
      yield* value.children;
    case presentation.ChildrenElement_gridWrapper(:final value):
      yield* value.children;
    case presentation.ChildrenElement_stackWrapper(:final value):
      yield* value.children;
    default:
      break;
  }
}

Iterable<presentation.PresentationNode> _sequenceNodes(
  presentation.SequencePresentation sequence,
) sync* {
  yield sequence.item;
  if (sequence.empty case final child?) yield child;
  if (sequence.separator case final child?) yield child;
}

Iterable<presentation.PresentationNode> _boundControlNodes(
  presentation.BoundControl control,
) sync* {
  if (control.prefix case final prefix?) yield prefix;
}

Iterable<presentation.PresentationNode> _connectionNodes(
  presentation.PresentationConnection connection,
) sync* {
  final markers = switch (connection) {
    presentation.PresentationConnection_connectionWrapper(:final value) =>
      value.markers,
    presentation.PresentationConnection_bundleWrapper(:final value) => [
      ...value.trunkMarkers,
      ...value.branchMarkers,
    ],
    _ => const <presentation.ConnectionMarker>[],
  };
  for (final marker in markers) {
    yield marker.node;
  }
}

Iterable<presentation.PresentationNode> _searchProviderNodes(
  presentation.SearchProvider provider,
) sync* {
  switch (provider) {
    case presentation.SearchProvider_staticValuesWrapper(:final value):
      yield value.result.presentation;
    case presentation.SearchProvider_collectionWrapper(:final value):
      yield value.result.presentation;
    case presentation.SearchProvider_httpJsonWrapper(:final value):
      yield value.result.presentation;
    case presentation.SearchProvider_realmCallbackWrapper(:final value):
      yield value.result.presentation;
    case presentation.SearchProvider_gateWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_debounceWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_cacheWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_rankWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_limitWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_distinctWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_historyWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_sectionWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case presentation.SearchProvider_mergeWrapper(:final value):
      for (final child in value.children) {
        yield* _searchProviderNodes(child);
      }
    default:
      break;
  }
}

bool _patternMatchesPath(
  types.RelativeFieldPattern pattern,
  types.ValuePath path,
) {
  final expected = pattern.segments.toList(growable: false);
  final actual = path.segments.toList(growable: false);
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    final matches = switch ((expected[index], actual[index])) {
      (
        types.FieldPatternSegment_fieldWrapper(value: final field),
        types.PathSegment_fieldWrapper(value: final segment),
      ) =>
        field.name == segment.name,
      (final pattern, types.PathSegment_itemWrapper())
          when pattern == types.FieldPatternSegment.items =>
        true,
      (final pattern, final segment)
          when pattern == types.FieldPatternSegment.keys =>
        segment == types.PathSegment.mapKey,
      (final pattern, final segment)
          when pattern == types.FieldPatternSegment.values =>
        segment == types.PathSegment.mapValue,
      _ => false,
    };
    if (!matches) return false;
  }
  return true;
}

sealed class TypeArgumentChoice {
  const TypeArgumentChoice();

  const factory TypeArgumentChoice.accepted(types.TypeSelection selection) =
      TypeArgumentAccepted;

  const factory TypeArgumentChoice.rejected(String message) =
      TypeArgumentRejected;
}

final class TypeArgumentAccepted extends TypeArgumentChoice {
  const TypeArgumentAccepted(this.selection);

  final types.TypeSelection selection;
}

final class TypeArgumentRejected extends TypeArgumentChoice {
  const TypeArgumentRejected(this.message);

  final String message;
}
