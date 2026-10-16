import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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

  final skir.PresentationRole requestedRole;
  final skir.PresentationRole resolvedRole;
  final skir.PresentationDescriptor descriptor;
  final skir.PresentationMaterial material;
}

final class MissingEditorPresentation extends EditorPresentationSelection {
  const MissingEditorPresentation(this.requestedRole);

  final skir.PresentationRole requestedRole;
}

final class ConflictingEditorPresentation extends EditorPresentationSelection {
  const ConflictingEditorPresentation({
    required this.role,
    required this.candidates,
  });

  final skir.PresentationRole role;
  final List<skir.PresentationId> candidates;
}

final class UnavailableEditorPresentation extends EditorPresentationSelection {
  const UnavailableEditorPresentation({
    required this.role,
    required this.presentation,
  });

  final skir.PresentationRole role;
  final skir.PresentationId presentation;
}

sealed class EditorFieldPresentationSelection {
  const EditorFieldPresentationSelection();
}

final class SelectedEditorFieldPresentation
    extends EditorFieldPresentationSelection {
  const SelectedEditorFieldPresentation(this.presentation);

  final skir.PresentationId presentation;
}

final class ConflictingEditorFieldPresentation
    extends EditorFieldPresentationSelection {
  const ConflictingEditorFieldPresentation(this.presentations);

  final List<skir.PresentationId> presentations;
}

final class CheckedEditorCatalog {
  CheckedEditorCatalog(this.snapshot)
    : _types = {
        for (final published in snapshot.types)
          published.definition.id: published,
      } {
    for (final id in _types.keys) {
      if (id.typeId case skir.TypeId_qualifiedWrapper(:final value)
          when value.namespace == "typewriter.read") {
        throw const FormatException(
          "Authored declarations cannot use the reserved canonical read namespace",
        );
      }
    }
  }

  late final expressionPrograms = PortableExpressionPrograms(this);

  final skir.EditorCatalogWireSnapshot snapshot;
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

  List<skir.PresentationRole> roleFallbackOrder(
    skir.PresentationRole requested,
  ) {
    final parents = {
      for (final fallback in snapshot.roleFallbacks)
        fallback.role: fallback.parents.toList(growable: false),
    };
    final pending = <skir.PresentationRole>[requested];
    final visited = <skir.PresentationRole>{};
    final ordered = <skir.PresentationRole>[];
    while (pending.isNotEmpty) {
      final current = pending.removeAt(0);
      if (!visited.add(current)) continue;
      ordered.add(current);
      pending.addAll(parents[current] ?? const []);
    }
    return List.unmodifiable(ordered);
  }

  EditorPresentationSelection selectPresentation(
    skir.TypeSelection actual,
    skir.PresentationRole requested,
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

  skir.PresentationMaterial? presentationMaterial(
    skir.PresentationId id,
    skir.TypeSelection actual,
  ) => snapshot.presentationMaterials
      .where(
        (material) =>
            material.provider == id &&
            _presentationTargetMatches(material.target, actual) &&
            (actual is skir.TypeSelection_pendingWrapper ||
                presentationExpressionProblems(material, actual).isEmpty),
      )
      .firstOrNull;

  Map<skir.ValuePath, EditorFieldPresentationSelection> fieldPresentations(
    skir.TypeSelection actual,
    skir.PresentationRole role,
  ) {
    final candidates = <skir.ValuePath, List<_FieldPresentationCandidate>>{};
    for (final material in snapshot.presentationMaterials) {
      if (material.role != role ||
          !_presentationTargetMatches(material.target, actual) ||
          (actual is! skir.TypeSelection_pendingWrapper &&
              presentationExpressionProblems(material, actual).isNotEmpty)) {
        continue;
      }
      final descriptor = snapshot.presentations
          .where((candidate) => candidate.id == material.provider)
          .firstOrNull;
      if (descriptor == null) continue;
      for (final selection in [
        ..._explicitFieldSelections(material.layout),
        if (material.resultAppearance?.leading case final leading?)
          ..._explicitFieldSelections(leading),
      ]) {
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
    skir.PresentationTarget target,
    skir.TypeSelection actual,
  ) => _presentationTargetMatches(target, actual);

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

  skir.PublishedType? selected(skir.TypeSelection selection) {
    final definition = switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) => value.definition,
      skir.TypeSelection_pendingWrapper(:final value) => value.definition,
      _ => null,
    };
    return definition == null ? null : published(definition);
  }

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

  ({skir.EndpointId endpoint, skir.TypeUse target})? referenceTypeAt(
    skir.AuthoringRecord record,
    skir.ValuePath path,
  ) => _referenceForUse(
    namedUse(
      valueTypeAt(
        record.configuration,
        path,
        value: skir.DataValue.createRecord(fields: record.fields),
      ),
    ),
  );

  ({skir.EndpointId endpoint, skir.TypeUse target})? _referenceForUse(
    skir.NamedTypeUse? use,
  ) {
    if (use == null) return null;
    final declaration = published(use.definition);
    if (declaration?.status != skir.DeclarationStatus.ready) return null;
    final representation = declaration?.definition.representation;
    if (representation is! skir.RepresentationTemplate_linkWrapper) return null;
    final target = applyTemplate(
      representation.value.target,
      skir.TypeSelection.wrapComplete(use),
    );
    return target == null
        ? null
        : (endpoint: representation.value.endpoint, target: target);
  }

  /// Exact reference paths in the authored value, including unfinished links.
  Iterable<
    ({skir.ValuePath path, skir.EndpointId endpoint, skir.TypeUse target})
  >
  referenceLocations(skir.AuthoringRecord record) sync* {
    for (final node in record._referenceValues) {
      final reference = referenceTypeAt(record, node.path);
      if (reference != null) {
        yield (
          path: node.path,
          endpoint: reference.endpoint,
          target: reference.target,
        );
      }
    }
  }

  /// Existing collection containers whose item contract is a direct reference.
  Iterable<
    ({skir.ValuePath path, skir.EndpointId endpoint, skir.TypeUse target})
  >
  referenceCollections(skir.AuthoringRecord record) sync* {
    for (final node in record._referenceValues) {
      if (node.value.authoredItems == null &&
          node.value.authoredPayload != skir.DataValue.unfilled) {
        continue;
      }
      final type = valueTypeAt(
        record.configuration,
        node.path,
        value: skir.DataValue.createRecord(fields: record.fields),
      );
      final reference = _referenceForUse(namedUse(collectionItemType(type)));
      if (reference != null) {
        yield (
          path: node.path,
          endpoint: reference.endpoint,
          target: reference.target,
        );
      }
    }
  }

  /// Unselected authored forms that could contain the requested counterpart.
  Iterable<skir.ValuePath> unselectedReferenceForms(
    skir.AuthoringRecord record,
    skir.EndpointId endpoint,
  ) sync* {
    for (final node in record._referenceValues) {
      final use = namedUse(
        valueTypeAt(
          record.configuration,
          node.path,
          value: skir.DataValue.createRecord(fields: record.fields),
        ),
      );
      if (use == null) continue;
      final selection = _selectionForUse(use, node.value);
      if (selection == null || !isAbstractRecordSelection(selection)) continue;
      if (_mayContainReference(skir.TypeUse.wrapNamed(use), endpoint, {})) {
        yield node.path;
      }
    }
  }

  bool _mayContainReference(
    skir.TypeUse? type,
    skir.EndpointId endpoint,
    Set<skir.NamedTypeUse> visited,
  ) {
    final use = namedUse(type);
    if (use == null || visited.contains(use)) return false;
    if (visited.length >= _maximumCheckedTypeDepth) return true;
    final selection = skir.TypeSelection.wrapComplete(use);
    final next = {...visited, use};
    final representation = published(use.definition)?.definition.representation;
    return switch (representation) {
      skir.RepresentationTemplate_linkWrapper(:final value) =>
        value.endpoint == endpoint,
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        fields(selection).any(
              (field) => _mayContainReference(field.type, endpoint, next),
            ) ||
            (value.abstract_ &&
                concreteRecordSelections(selection).any(
                  (candidate) => fields(candidate).any(
                    (field) => _mayContainReference(field.type, endpoint, next),
                  ),
                )),
      skir.RepresentationTemplate_sequenceWrapper(:final value) =>
        _mayContainReference(
          applyTemplate(value.item, selection),
          endpoint,
          next,
        ),
      skir.RepresentationTemplate_mappingWrapper(:final value) =>
        _mayContainReference(
              applyTemplate(value.key, selection),
              endpoint,
              next,
            ) ||
            _mayContainReference(
              applyTemplate(value.value, selection),
              endpoint,
              next,
            ),
      _ => false,
    };
  }

  skir.TypeSelection? _selectionAtValue(
    skir.TypeSelection declared,
    skir.DataValue? value,
  ) {
    if (value case skir.DataValue_namedWrapper(:final value)) {
      final actual = value.actualType;
      final compatible = switch (declared) {
        skir.TypeSelection_completeWrapper(:final value) => isReadableAs(
          skir.TypeUse.wrapNamed(actual),
          skir.TypeUse.wrapNamed(value),
        ),
        skir.TypeSelection_pendingWrapper() =>
          knownApplications(skir.TypeSelection.wrapComplete(actual)).any(
            (candidate) => knownApplications(declared).any(
              (expected) => isReadableAs(
                skir.TypeUse.wrapNamed(candidate),
                skir.TypeUse.wrapNamed(expected),
              ),
            ),
          ),
        _ => false,
      };
      return compatible ? skir.TypeSelection.wrapComplete(actual) : null;
    }
    return declared;
  }

  skir.TypeSelection? _selectionForUse(
    skir.NamedTypeUse declared,
    skir.DataValue? value,
  ) {
    if (value case skir.DataValue_namedWrapper(:final value)) {
      if (!isReadableAs(
        skir.TypeUse.wrapNamed(value.actualType),
        skir.TypeUse.wrapNamed(declared),
      )) {
        return null;
      }
      return skir.TypeSelection.wrapComplete(value.actualType);
    }
    return skir.TypeSelection.wrapComplete(declared);
  }

  skir.DataValue? _namedPayload(skir.DataValue? value) => switch (value) {
    skir.DataValue_namedWrapper(:final value) => value.payload,
    _ => value,
  };

  skir.DataValue? _fieldValue(skir.DataValue? value, String name) {
    final payload = _namedPayload(value);
    final fields = switch (payload) {
      skir.DataValue_recordWrapper(:final value) =>
        value.fields
            .where((field) => field.name == name)
            .toList(growable: false),
      _ => const <skir.FieldValue>[],
    };
    return fields.length == 1 ? fields.single.value : null;
  }

  skir.DataValue? _collectionItem(skir.DataValue? value, skir.ItemId id) {
    final items = switch (value) {
      skir.DataValue_listValueWrapper(:final value) => value.items,
      skir.DataValue_setValueWrapper(:final value) => value.items,
      _ => const <skir.ListItem>[],
    };
    final matching = items
        .where((candidate) => candidate.id == id)
        .toList(growable: false);
    return matching.length == 1 ? matching.single.value : null;
  }

  skir.DataValue? _mapRowValue(
    skir.DataValue? value,
    skir.ItemId id,
    skir.PathSegment branch,
  ) {
    final rows = switch (value) {
      skir.DataValue_mapValueWrapper(:final value) =>
        value.rows
            .where((candidate) => candidate.id == id)
            .toList(growable: false),
      _ => const <skir.MapRow>[],
    };
    if (rows.length != 1) return null;
    return switch (branch) {
      final value when value == skir.PathSegment.mapKey => rows.single.key,
      final value when value == skir.PathSegment.mapValue => rows.single.value,
      _ => null,
    };
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

  skir.AuthoringResourceDefinition? resourceDefinition(
    skir.TypeSelection selection,
  ) {
    final definitions = nominalDefinitions(selection);
    final candidates = snapshot.resourceDefinitions
        .where((resource) => definitions.contains(resource.root))
        .toList(growable: false);
    return candidates.length == 1 ? candidates.single : null;
  }

  bool isResourceDefinition(
    skir.TypeSelection selection,
    skir.ResourceDefinitionId id,
  ) {
    final definitions = nominalDefinitions(selection);
    return snapshot.resourceDefinitions.any(
      (resource) => resource.id == id && definitions.contains(resource.root),
    );
  }

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
                _isNominalSubtype(
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
          !_isNominalSubtype(published.definition.id, root)) {
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
    final arguments = _argumentSelections(selection, parameters.length);
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
    final arguments = _argumentSelections(
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

  bool isReadableAs(skir.TypeUse actual, skir.TypeUse expected) =>
      _isReadableAs(actual, expected, 0);

  /// Whether a complete named use is valid in this checked snapshot.
  ///
  /// Equality and nominal readability assume their inputs are valid type uses.
  /// This boundary also proves that every referenced declaration is ready,
  /// every application has the declared arity, and every applied argument
  /// satisfies its parameter bounds.
  bool isReadyTypeUse(skir.TypeUse use) => _isReadyTypeUse(use, 0);

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

  EditorPresentationSelection _selectWithinRole(
    skir.TypeSelection actual,
    skir.PresentationRole role,
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
    if (material == null ||
        (actual is! skir.TypeSelection_pendingWrapper &&
            presentationExpressionProblems(material, actual).isNotEmpty)) {
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
    skir.PresentationTarget target,
    skir.TypeSelection actual,
  ) => switch (target) {
    skir.PresentationTarget_namedWrapper(:final value) =>
      _namedPresentationTargetMatches(value, actual),
    skir.PresentationTarget_representationWrapper(:final value) =>
      representationKind(actual) == value,
    _ => false,
  };

  bool _namedPresentationTargetMatches(
    skir.NamedTypeTemplate target,
    skir.TypeSelection actual,
  ) {
    for (final application in knownApplications(actual)) {
      if (_templateMatchesUse(
        target,
        application,
        <skir.ParameterKey, skir.TypeUse>{},
      )) {
        return true;
      }
    }
    if (actual case skir.TypeSelection_pendingWrapper(:final value)) {
      if (target.definition != value.definition ||
          target.arguments.length != value.arguments.length) {
        return false;
      }
      final bindings = <skir.ParameterKey, skir.TypeUse>{};
      final expectedArguments = target.arguments.toList();
      final actualArguments = value.arguments.toList();
      for (var index = 0; index < expectedArguments.length; index++) {
        switch (actualArguments[index]) {
          case skir.ArgumentSelection_chosenWrapper(:final value):
            if (!_templateMatches(expectedArguments[index], value, bindings)) {
              return false;
            }
          case final argument when argument == skir.ArgumentSelection.unfilled:
            if (expectedArguments[index]
                is! skir.TypeTemplate_parameterWrapper) {
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

  bool _isMoreSpecific(
    skir.PresentationTarget left,
    skir.PresentationTarget right,
  ) {
    if (left is skir.PresentationTarget_namedWrapper &&
        right is skir.PresentationTarget_representationWrapper) {
      return true;
    }
    if (left is! skir.PresentationTarget_namedWrapper ||
        right is! skir.PresentationTarget_namedWrapper) {
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
    skir.PresentationTarget left,
    skir.PresentationTarget right,
  ) => switch ((left, right)) {
    (
      skir.PresentationTarget_namedWrapper(:final value),
      skir.PresentationTarget_namedWrapper(value: final rightValue),
    ) =>
      _namedTemplateSubsumes(value, rightValue) &&
          _namedTemplateSubsumes(rightValue, value),
    (
      skir.PresentationTarget_representationWrapper(:final value),
      skir.PresentationTarget_representationWrapper(value: final rightValue),
    ) =>
      value == rightValue,
    _ => false,
  };

  bool _isNominalSubtype(
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

  List<skir.ArgumentSelection> _argumentSelections(
    skir.TypeSelection selection,
    int count,
  ) {
    final current = switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) => [
        for (final argument in value.arguments)
          skir.ArgumentSelection.wrapChosen(argument),
      ],
      skir.TypeSelection_pendingWrapper(:final value) =>
        value.arguments.toList(),
      _ => <skir.ArgumentSelection>[],
    };
    return List.generate(
      count,
      (index) => index < current.length
          ? current[index]
          : skir.ArgumentSelection.unfilled,
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

  final skir.PresentationId presentation;
  final skir.PresentationTarget target;
  final int priority;
}

final class _ExplicitFieldPresentation {
  const _ExplicitFieldPresentation({
    required this.path,
    required this.presentation,
  });

  final skir.ValuePath path;
  final skir.PresentationId presentation;
}

Iterable<_ExplicitFieldPresentation> _explicitFieldSelections(
  skir.PresentationNode root,
) sync* {
  final configured = skir.ExpressionBindingId(value: "configured_value");
  final origin = AuthoredBindingRoot.local(configured);
  for (final use in root.authoredBindingUses({
    configured: AuthoredBindingAddress(root: origin, path: const []),
  })) {
    if (use.selectedPresentation == null ||
        use.address.root != origin ||
        use.address.path.isEmpty ||
        use.address.path.any((step) => step is! ExactAuthoredPathStep)) {
      continue;
    }
    yield _ExplicitFieldPresentation(
      path: skir.ValuePath(
        segments: [
          for (final step in use.address.path)
            (step as ExactAuthoredPathStep).segment,
        ],
      ),
      presentation: use.selectedPresentation!,
    );
  }
}

extension PresentationNodeStructure on skir.PresentationNode {
  Iterable<skir.PresentationNode> get nestedPresentationNodes =>
      _nestedPresentationNodes(this);

  skir.BoundControl? get boundControl => switch (element) {
    skir.PresentationElement_textInputWrapper(:final value) => value.control,
    skir.PresentationElement_numericInputWrapper(:final value) => value.control,
    skir.PresentationElement_defaultPresentationWrapper(:final value) =>
      value.control,
    skir.PresentationElement_toggleInputWrapper(:final value) => value.control,
    skir.PresentationElement_durationInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_bytesInputWrapper(:final value) => value.control,
    skir.PresentationElement_enumInputWrapper(:final value) => value.control,
    skir.PresentationElement_selectInputWrapper(:final value) => value.control,
    skir.PresentationElement_sliderInputWrapper(:final value) => value.control,
    skir.PresentationElement_dateTimeInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_colorInputWrapper(:final value) => value.control,
    skir.PresentationElement_namedInputWrapper(:final value) => value.control,
    skir.PresentationElement_listInputWrapper(:final value) => value.control,
    skir.PresentationElement_setInputWrapper(:final value) => value.control,
    skir.PresentationElement_mapInputWrapper(:final value) => value.control,
    skir.PresentationElement_recordInputWrapper(:final value) => value.control,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_searchInputWrapper(:final value) => value.control,
    skir.PresentationElement_nullableInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_linkInputWrapper(:final value) => value.control,
    skir.PresentationElement_pageGraphWrapper(:final value) => value.control,
    skir.PresentationElement_pageTimelineWrapper(:final value) => value.control,
    _ => null,
  };
}

Iterable<skir.PresentationNode> _nestedPresentationNodes(
  skir.PresentationNode node,
) sync* {
  final title = node.header?.title;
  if (title case skir.PresentationHeaderTitle_presentationWrapper(
    :final value,
  )) {
    yield value;
  }
  final element = node.element;
  final inputContent = switch (element) {
    skir.PresentationElement_textInputWrapper(:final value) => value.content,
    skir.PresentationElement_numericInputWrapper(:final value) => value.content,
    skir.PresentationElement_durationInputWrapper(:final value) =>
      value.content,
    skir.PresentationElement_dateTimeInputWrapper(:final value) =>
      value.content,
    skir.PresentationElement_colorInputWrapper(:final value) => value.content,
    skir.PresentationElement_bytesInputWrapper(:final value) => value.content,
    skir.PresentationElement_enumInputWrapper(:final value) => value.content,
    skir.PresentationElement_selectInputWrapper(:final value) => value.content,
    skir.PresentationElement_searchInputWrapper(:final value) => value.content,
    skir.PresentationElement_linkInputWrapper(:final value) =>
      value.inputContent,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.inputContent,
    _ => null,
  };
  if (inputContent?.leading case skir.InputAdornment_contentWrapper(
    :final value,
  )) {
    yield value;
  }
  if (inputContent?.suffix case final child?) yield child;
  final collectionContent = switch (element) {
    skir.PresentationElement_listInputWrapper(:final value) => value.content,
    skir.PresentationElement_setInputWrapper(:final value) => value.content,
    skir.PresentationElement_mapInputWrapper(:final value) => value.content,
    skir.PresentationElement_recordInputWrapper(:final value) => value.content,
    skir.PresentationElement_linkInputWrapper(:final value) => value.content,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.content,
    _ => null,
  };
  if (collectionContent != null) {
    for (final child in [
      collectionContent.empty,
      collectionContent.addIcon,
      collectionContent.removeIcon,
      collectionContent.reorderIcon,
      collectionContent.chooseIcon,
      collectionContent.unlinkIcon,
    ]) {
      if (child != null) yield child;
    }
  }
  switch (element) {
    case skir.PresentationElement_childrenWrapper(:final value):
      yield* _childrenNodes(value);
    case skir.PresentationElement_appearanceDefaultsWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_defaultPresentationWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_sectionWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_paddingWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_tabsWrapper(:final value):
      for (final tab in value.tabs) {
        yield tab.child;
        if (tab.icon case final child?) yield child;
      }
    case skir.PresentationElement_typedFieldWrapper(:final value):
      if (value.presentation case final child?) yield child;
    case skir.PresentationElement_conditionalWrapper(:final value):
      yield value.whenTrue;
      if (value.whenFalse case final child?) yield child;
    case skir.PresentationElement_repeatedWrapper(:final value):
      yield* _sequenceNodes(value.presentation);
    case skir.PresentationElement_scopedBindingWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_textInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_numericInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_toggleInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_selectInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      for (final option in value.options) {
        if (option.content case final child?) yield child;
      }
      for (final option
          in value.optionsConfig?.optionOverrides ??
              const <skir.ChoiceOptionAppearance>[]) {
        if (option.content case final child?) yield child;
      }
    case skir.PresentationElement_sliderInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_dateTimeInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_durationInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_colorInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_bytesInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_enumInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      for (final option
          in value.options?.optionOverrides ??
              const <skir.ChoiceOptionAppearance>[]) {
        if (option.content case final child?) yield child;
      }
    case skir.PresentationElement_namedInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.payloadPresentation case final child?) yield child;
    case skir.PresentationElement_buttonWrapper(:final value):
      if (value.icon case final child?) yield child;
    case skir.PresentationElement_menuWrapper(:final value):
      for (final item in value.items) {
        if (item.icon case final child?) yield child;
      }
    case skir.PresentationElement_tooltipWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_listInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.itemPresentation case final child?) yield child;
    case skir.PresentationElement_setInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.itemPresentation case final child?) yield child;
    case skir.PresentationElement_mapInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.keyPresentation case final child?) yield child;
      if (value.valuePresentation case final child?) yield child;
    case skir.PresentationElement_recordInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.fieldPresentation case final child?) yield child;
    case skir.PresentationElement_polymorphicInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      for (final option in value.concreteTypes) {
        if (option.presentation case final child?) yield child;
      }
    case skir.PresentationElement_searchInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.summary case final child?) yield child;
      if (value.empty case final child?) yield child;
      if (value.loading case final child?) yield child;
      yield* _searchProviderNodes(value.provider);
    case skir.PresentationElement_collectionLookupWrapper(:final value):
      yield value.found;
      yield value.missing;
      if (value.loading case final child?) yield child;
    case skir.PresentationElement_collectionGraphWrapper(:final value):
      yield* _sequenceNodes(value.rootSequence);
      yield value.node;
      yield* _sequenceNodes(value.children);
    case skir.PresentationElement_alignWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_containerWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_anchorWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_connectionLayerWrapper(:final value):
      yield value.child;
      for (final connection in value.connections) {
        yield* _connectionNodes(connection);
      }
    case skir.PresentationElement_polymorphicMatchWrapper(:final value):
      for (final item in value.cases) {
        yield item.child;
      }
      if (value.fallback case final child?) yield child;
    case skir.PresentationElement_linkInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_adaptiveLeadingWrapper(:final value):
      yield value.leading;
      if (value.center case final child?) yield child;
      if (value.suffix case final child?) yield child;
    case skir.PresentationElement_nullableInputWrapper(:final value):
      yield* _boundControlNodes(value.control);
      if (value.valuePresentation case final child?) yield child;
    case skir.PresentationElement_pageGraphWrapper(:final value):
      yield* _boundControlNodes(value.control);
    case skir.PresentationElement_pageTimelineWrapper(:final value):
      yield* _boundControlNodes(value.control);
    default:
      break;
  }
}

Iterable<skir.PresentationNode> _childrenNodes(
  skir.ChildrenElement children,
) sync* {
  switch (children) {
    case skir.ChildrenElement_columnWrapper(:final value) ||
        skir.ChildrenElement_rowWrapper(:final value):
      for (final child in value.children) {
        switch (child) {
          case skir.AxisChild_fixedWrapper(:final value):
            yield value;
          case skir.AxisChild_flexibleWrapper(:final value):
            yield value.child;
          default:
            break;
        }
      }
    case skir.ChildrenElement_wrapWrapper(:final value):
      yield* value.children;
    case skir.ChildrenElement_gridWrapper(:final value):
      yield* value.children;
    case skir.ChildrenElement_stackWrapper(:final value):
      yield* value.children;
    default:
      break;
  }
}

Iterable<skir.PresentationNode> _sequenceNodes(
  skir.SequencePresentation sequence,
) sync* {
  yield sequence.item;
  if (sequence.empty case final child?) yield child;
  if (sequence.separator case final child?) yield child;
}

Iterable<skir.PresentationNode> _boundControlNodes(
  skir.BoundControl control,
) sync* {
  if (control.prefix case final prefix?) yield prefix;
}

Iterable<skir.PresentationNode> _connectionNodes(
  skir.PresentationConnection connection,
) sync* {
  final markers = switch (connection) {
    skir.PresentationConnection_connectionWrapper(:final value) =>
      value.markers,
    skir.PresentationConnection_bundleWrapper(:final value) => [
      ...value.trunkMarkers,
      ...value.branchMarkers,
    ],
    _ => const <skir.ConnectionMarker>[],
  };
  for (final marker in markers) {
    yield marker.node;
  }
}

Iterable<skir.PresentationNode> _searchResultNodes(
  skir.SearchResultMapping result,
) sync* {
  yield result.presentation;
  if (result.resultAppearance?.leading case final leading?) yield leading;
}

Iterable<skir.PresentationNode> _searchProviderNodes(
  skir.SearchProvider provider,
) sync* {
  switch (provider) {
    case skir.SearchProvider_staticValuesWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_collectionWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_httpJsonWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_realmCallbackWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_gateWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_debounceWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_cacheWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_rankWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_limitWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_distinctWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_historyWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_sectionWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_mergeWrapper(:final value):
      for (final child in value.children) {
        yield* _searchProviderNodes(child);
      }
    default:
      break;
  }
}

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

sealed class TypeArgumentChoice {
  const TypeArgumentChoice();

  const factory TypeArgumentChoice.accepted(skir.TypeSelection selection) =
      TypeArgumentAccepted;

  const factory TypeArgumentChoice.rejected(String message) =
      TypeArgumentRejected;
}

final class TypeArgumentAccepted extends TypeArgumentChoice {
  const TypeArgumentAccepted(this.selection);

  final skir.TypeSelection selection;
}

final class TypeArgumentRejected extends TypeArgumentChoice {
  const TypeArgumentRejected(this.message);

  final String message;
}

extension _AuthoredReferenceValues on skir.AuthoringRecord {
  Iterable<({skir.ValuePath path, skir.DataValue value})>
  get _referenceValues sync* {
    final pending = <(skir.DataValue, skir.ValuePath, int)>[
      (
        skir.DataValue.createRecord(fields: fields),
        skir.ValuePath(segments: const []),
        0,
      ),
    ];
    final visited = <skir.ValuePath>{};
    while (pending.isNotEmpty) {
      final (value, path, depth) = pending.removeLast();
      if (depth > _maximumCheckedTypeDepth) {
        throw StateError("The authored value exceeded its depth limit");
      }
      if (path.segments.isNotEmpty && visited.add(path)) {
        yield (path: path, value: value);
      }
      void add(skir.DataValue value, skir.PathSegment segment) => pending.add((
        value,
        skir.ValuePath(segments: [...path.segments, segment]),
        depth + 1,
      ));
      switch (value) {
        case skir.DataValue_namedWrapper(:final value):
          pending.add((value.payload, path, depth + 1));
        case skir.DataValue_recordWrapper(:final value):
          for (final field in value.fields.toList().reversed) {
            add(field.value, skir.PathSegment.createField(name: field.name));
          }
        case skir.DataValue_listValueWrapper(:final value):
          for (final item in value.items.toList().reversed) {
            add(item.value, skir.PathSegment.createItem(id: item.id));
          }
        case skir.DataValue_setValueWrapper(:final value):
          for (final item in value.items.toList().reversed) {
            add(item.value, skir.PathSegment.createItem(id: item.id));
          }
        case skir.DataValue_mapValueWrapper(:final value):
          for (final row in value.rows.toList().reversed) {
            final rowPath = skir.ValuePath(
              segments: [
                ...path.segments,
                skir.PathSegment.createItem(id: row.id),
              ],
            );
            pending
              ..add((
                row.value,
                skir.ValuePath(
                  segments: [...rowPath.segments, skir.PathSegment.mapValue],
                ),
                depth + 1,
              ))
              ..add((
                row.key,
                skir.ValuePath(
                  segments: [...rowPath.segments, skir.PathSegment.mapKey],
                ),
                depth + 1,
              ));
          }
        default:
      }
    }
  }
}
