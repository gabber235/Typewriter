part of "checked_editor_catalog.dart";

/// The outcome of choosing one presentation for a requested role.
@freezed
sealed class EditorPresentationSelection with _$EditorPresentationSelection {
  const factory EditorPresentationSelection.selected({
    required skir.PresentationRole requestedRole,
    required skir.PresentationRole resolvedRole,
    required skir.PresentationDescriptor descriptor,
    required skir.PresentationMaterial material,
  }) = SelectedEditorPresentation;
  const factory EditorPresentationSelection.missing(
    skir.PresentationRole requestedRole,
  ) = MissingEditorPresentation;
  const factory EditorPresentationSelection.conflicting({
    required skir.PresentationRole role,
    required List<skir.PresentationId> candidates,
  }) = ConflictingEditorPresentation;
  const factory EditorPresentationSelection.unavailable({
    required skir.PresentationRole role,
    required skir.PresentationId presentation,
  }) = UnavailableEditorPresentation;
}

/// Identifies a source control within one compiled material and role.
@freezed
abstract class EditorFieldPresentationIdentity
    with _$EditorFieldPresentationIdentity {
  const factory EditorFieldPresentationIdentity({
    required skir.PresentationId provider,
    required skir.TypeTemplate subject,
    required skir.PresentationRole role,
    required String field,
    required String nodeId,
  }) = _EditorFieldPresentationIdentity;
}

@freezed
sealed class EditorFieldPresentationSelection
    with _$EditorFieldPresentationSelection {
  const factory EditorFieldPresentationSelection.selected({
    required EditorFieldPresentationIdentity identity,
    required skir.PresentationMaterial material,
    required skir.PresentationNode node,
  }) = SelectedEditorFieldPresentation;
  const factory EditorFieldPresentationSelection.conflicting({
    required List<EditorFieldPresentationIdentity> candidates,
  }) = ConflictingEditorFieldPresentation;
  const factory EditorFieldPresentationSelection.invalid({
    required EditorFieldPresentationIdentity identity,
    required String diagnostic,
  }) = InvalidEditorFieldPresentation;
  const factory EditorFieldPresentationSelection.missing() =
      MissingEditorFieldPresentation;
}

@freezed
sealed class _CheckedFieldPresentation with _$CheckedFieldPresentation {
  const factory _CheckedFieldPresentation.valid({
    required EditorFieldPresentationIdentity identity,
    required skir.PresentationMaterial material,
    required skir.PresentationNode node,
  }) = _ValidFieldPresentation;
  const factory _CheckedFieldPresentation.invalid({
    required EditorFieldPresentationIdentity identity,
    required skir.PresentationMaterial material,
    required String diagnostic,
  }) = _InvalidFieldPresentation;
}

@freezed
abstract class _FieldPresentationCandidate with _$FieldPresentationCandidate {
  const factory _FieldPresentationCandidate({
    required skir.PresentationDescriptor descriptor,
    required _CheckedFieldPresentation reference,
  }) = __FieldPresentationCandidate;
}

/// Canonical source membership checked once for an immutable catalog snapshot.
@freezed
abstract class CheckedInheritableLayout with _$CheckedInheritableLayout {
  const factory CheckedInheritableLayout({
    required Map<String, skir.PresentationNode> nodes,
    required Set<String> inheritableNodes,
    required int remainderCount,
    required Set<String> canonicalFields,
    required Set<skir.PresentationPartId> declaredParts,
    String? diagnostic,
  }) = _CheckedInheritableLayout;
}

@freezed
sealed class EditorInspectorLayoutSelection
    with _$EditorInspectorLayoutSelection {
  const factory EditorInspectorLayoutSelection.selected({
    required skir.PresentationDescriptor descriptor,
    required skir.PresentationMaterial material,
    required Set<String> inheritableNodes,
  }) = SelectedEditorInspectorLayout;
  const factory EditorInspectorLayoutSelection.conflicting({
    required List<skir.PresentationId> candidates,
  }) = ConflictingEditorInspectorLayout;
  const factory EditorInspectorLayoutSelection.invalid({
    required String diagnostic,
  }) = InvalidEditorInspectorLayout;
  const factory EditorInspectorLayoutSelection.missing() =
      MissingEditorInspectorLayout;
}

/// An explicitly authored body, independent of the catalog's winning body.
@freezed
abstract class EditorPartDeclaration with _$EditorPartDeclaration {
  const factory EditorPartDeclaration({
    required skir.PresentationMaterial material,
    required skir.PresentationNode body,
  }) = _EditorPartDeclaration;
}

@freezed
sealed class EditorPartPresentationSelection
    with _$EditorPartPresentationSelection {
  const factory EditorPartPresentationSelection.selected({
    required skir.PresentationPartId key,
    required skir.PresentationMaterial material,
    required skir.PresentationNode body,
    required Set<String> editedFields,
    required Set<String> fallbackFields,
    required Set<skir.PresentationPartId> claimedParts,
  }) = SelectedEditorPartPresentation;
  const factory EditorPartPresentationSelection.conflicting({
    required List<skir.PresentationId> candidates,
  }) = ConflictingEditorPartPresentation;
  const factory EditorPartPresentationSelection.invalid({
    required String diagnostic,
  }) = InvalidEditorPartPresentation;
  const factory EditorPartPresentationSelection.missing() =
      MissingEditorPartPresentation;
}

/// Presentation selection: role fallback, material and field presentations,
/// their checks, and ranking among candidate descriptors.
extension CheckedFieldPresentationCatalog on CheckedEditorCatalog {
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

  /// Resolves the requested role through its breadth first fallback order.
  /// A conflicting or unavailable winner ends resolution instead of falling
  /// through to an unrelated representation.
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

  /// Materials were checked when Realm built them, for every application of
  /// their subject, so selection only matches identity and target.
  skir.PresentationMaterial? presentationMaterial(
    skir.PresentationId id,
    skir.TypeSelection actual,
  ) => snapshot.presentationMaterials
      .where(
        (material) =>
            material.provider == id &&
            _presentationTargetMatches(material.target, actual),
      )
      .firstOrNull;

  /// Selects a control from matching owner presentations for one direct field.
  /// Invalid published references remain errors instead of becoming absent defaults.
  EditorFieldPresentationSelection fieldPresentation(
    skir.TypeSelection actualOwner,
    String field,
    skir.PresentationRole role,
  ) {
    final byProvider =
        <skir.PresentationId, List<_FieldPresentationCandidate>>{};
    for (final material in snapshot.presentationMaterials) {
      if (material.role != role ||
          !_presentationTargetMatches(material.target, actualOwner) ||
          !_fieldMaterialSubjectMatches(material, actualOwner)) {
        continue;
      }
      final references =
          _fieldPresentationIndex[material]!
              .where((reference) => reference.identity.field == field)
              .toList(growable: true)
            ..removeWhere(
              (reference) =>
                  reference is _ValidFieldPresentation &&
                  switch (reference.node.element) {
                    skir.PresentationElement_defaultPresentationWrapper(
                      :final value,
                    ) =>
                      value.presentationId == null,
                    _ => false,
                  },
            );
      if (references.isEmpty) continue;
      final descriptor = snapshot.presentations
          .where((candidate) => candidate.id == material.provider)
          .firstOrNull;
      if (descriptor == null) continue;
      for (final reference in references) {
        byProvider
            .putIfAbsent(descriptor.id, () => [])
            .add(
              _FieldPresentationCandidate(
                descriptor: descriptor,
                reference: reference,
              ),
            );
      }
    }
    final winners = _rankPresentationDescriptors([
      for (final candidates in byProvider.values) candidates.first.descriptor,
    ]);
    final surviving = [for (final winner in winners) ...byProvider[winner.id]!];
    if (surviving.isEmpty) return const MissingEditorFieldPresentation();
    if (surviving.length != 1) {
      return ConflictingEditorFieldPresentation(
        candidates: [
          for (final candidate in surviving) candidate.reference.identity,
        ],
      );
    }
    return switch (surviving.single.reference) {
      _ValidFieldPresentation(:final identity, :final material, :final node) =>
        SelectedEditorFieldPresentation(
          identity: identity,
          material: material,
          node: node,
        ),
      _InvalidFieldPresentation(:final identity, :final diagnostic) =>
        InvalidEditorFieldPresentation(
          identity: identity,
          diagnostic: diagnostic,
        ),
    };
  }

  bool _fieldMaterialSubjectMatches(
    skir.PresentationMaterial material,
    skir.TypeSelection actualOwner,
  ) {
    if (material.target is! skir.PresentationTarget_representationWrapper) {
      return true;
    }
    return switch (material.subject) {
      skir.TypeTemplate_namedWrapper(:final value) =>
        value.definition == selected(actualOwner)?.definition.id &&
            _namedPresentationTargetMatches(value, actualOwner),
      _ => false,
    };
  }

  List<_CheckedFieldPresentation> _checkFieldPresentations(
    skir.PresentationMaterial material,
  ) {
    if (material.inheritableNodes.isEmpty) return const [];
    final view = _inheritableViews[material]!;
    final nodes = view.nodes;
    if (view.diagnostic case final diagnostic?) {
      final fields = {
        ...view.canonicalFields,
        for (final id in view.inheritableNodes)
          if (nodes[id]?.boundControl?.binding.path.segments.singleOrNull
              case skir.PathSegment_fieldWrapper(:final value))
            value.name,
      };
      return [
        for (final field in fields)
          _CheckedFieldPresentation.invalid(
            identity: EditorFieldPresentationIdentity(
              provider: material.provider,
              subject: material.subject,
              role: material.role,
              field: field,
              nodeId: material.inheritableNodes.first,
            ),
            material: material,
            diagnostic:
                "Field presentation ${material.provider.namespace}:${material.provider.name} for $field at ${material.inheritableNodes.first}: $diagnostic",
          ),
      ];
    }
    if (!view.inheritableNodes.any((id) => nodes[id]?.boundControl != null)) {
      return const [];
    }
    final subject = material.subject as skir.TypeTemplate_namedWrapper;
    final owner = published(subject.value.definition)!;
    return [
      for (final nodeId in view.inheritableNodes)
        if (nodes[nodeId] case final node? when node.boundControl != null)
          (() {
            final field =
                (node.boundControl!.binding.path.segments.single
                        as skir.PathSegment_fieldWrapper)
                    .value
                    .name;
            final identity = EditorFieldPresentationIdentity(
              provider: material.provider,
              subject: material.subject,
              role: material.role,
              field: field,
              nodeId: nodeId,
            );
            final type = owner.effectiveFields
                .singleWhere((entry) => entry.key == field)
                .type;
            final problem =
                _fieldControlProblem(node, type) ??
                _fieldSubtreeProblem(node, field, material);
            return problem == null
                ? _CheckedFieldPresentation.valid(
                    identity: identity,
                    material: material,
                    node: node,
                  )
                : _CheckedFieldPresentation.invalid(
                    identity: identity,
                    material: material,
                    diagnostic:
                        "Field presentation ${material.provider.namespace}:${material.provider.name} for $field at $nodeId: $problem",
                  );
          })(),
    ];
  }

  String? _fieldSubtreeProblem(
    skir.PresentationNode node,
    String field,
    skir.PresentationMaterial material,
  ) {
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final origin = AuthoredBindingAddress(
      root: AuthoredBindingRoot.local(configured),
      path: const [],
    );
    String? problem;
    AuthoredPresentationIndex.build(
      node,
      {configured: origin},
      sources: {
        for (final source in material.dependencies.collections)
          source.sourceId: source,
      },
      onPart: (node, part, aliases) {
        problem ??= "the source control has an unresolved editable part";
        return false;
      },
      onEditableBinding: (binding, address) {
        if (problem != null) return;
        if (address == null) {
          problem = "the source control has an unresolved editable binding";
          return;
        }
        final first = address.path.firstOrNull;
        if (address.root != origin.root ||
            first is! ExactAuthoredPathStep ||
            first.segment is! skir.PathSegment_fieldWrapper ||
            (first.segment as skir.PathSegment_fieldWrapper).value.name !=
                field) {
          problem = "the source control edits outside its field subtree";
        }
      },
    );
    return problem;
  }

  String? _fieldControlProblem(
    skir.PresentationNode node,
    skir.TypeTemplate type,
  ) {
    if (node.element case skir.PresentationElement_defaultPresentationWrapper(
      :final value,
    )) {
      if (value.presentationId == null) {
        return null;
      }
      if (!snapshot.presentations.any(
        (descriptor) => descriptor.id == value.presentationId,
      )) {
        return "the named presentation is missing";
      }
      return null;
    }
    final kind = _templateRepresentationKind(type);
    if (kind == null) return null;
    final allowed = switch (node.element) {
      skir.PresentationElement_textInputWrapper() => [
        skir.RepresentationKind.text,
      ],
      skir.PresentationElement_numericInputWrapper() ||
      skir.PresentationElement_sliderInputWrapper() => [
        skir.RepresentationKind.integer,
        skir.RepresentationKind.float,
        skir.RepresentationKind.decimal,
      ],
      skir.PresentationElement_toggleInputWrapper() => [
        skir.RepresentationKind.boolean,
      ],
      skir.PresentationElement_bytesInputWrapper() => [
        skir.RepresentationKind.bytes,
      ],
      skir.PresentationElement_durationInputWrapper() => [
        skir.RepresentationKind.duration,
      ],
      skir.PresentationElement_dateTimeInputWrapper() => [
        skir.RepresentationKind.timestamp,
      ],
      skir.PresentationElement_enumInputWrapper() => [
        skir.RepresentationKind.enumeration,
      ],
      skir.PresentationElement_recordInputWrapper() => [
        skir.RepresentationKind.record,
      ],
      skir.PresentationElement_listInputWrapper() => [
        skir.RepresentationKind.list,
      ],
      skir.PresentationElement_setInputWrapper() => [
        skir.RepresentationKind.set_,
      ],
      skir.PresentationElement_mapInputWrapper() => [
        skir.RepresentationKind.map,
      ],
      skir.PresentationElement_linkInputWrapper() => [
        skir.RepresentationKind.link,
      ],
      _ => null,
    };
    return allowed != null && !allowed.contains(kind)
        ? "the control is incompatible with the declaring field type"
        : null;
  }

  skir.RepresentationKind? _templateRepresentationKind(
    skir.TypeTemplate type,
  ) => switch (type) {
    skir.TypeTemplate_scalarWrapper(:final value) => _scalarRepresentation(
      value,
    ),
    skir.TypeTemplate_namedWrapper(:final value) => _representationKind(
      published(value.definition)?.definition.representation,
    ),
    skir.TypeTemplate_nullableWrapper(:final value) =>
      _templateRepresentationKind(value.value),
    _ => null,
  };

  bool isPresentationCompatible(
    skir.PresentationTarget target,
    skir.TypeSelection actual,
  ) => _presentationTargetMatches(target, actual);

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
    final winners = _rankPresentationDescriptors(matching);
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

  List<skir.PresentationDescriptor> _rankPresentationDescriptors(
    List<skir.PresentationDescriptor> candidates,
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
    if (maximal.isEmpty) return const [];
    if (maximal
        .skip(1)
        .any(
          (candidate) => !_presentationTargetsEquivalent(
            maximal.first.target,
            candidate.target,
          ),
        )) {
      return maximal;
    }
    final priority = maximal
        .map((candidate) => candidate.priority)
        .reduce((left, right) => left > right ? left : right);
    return maximal
        .where((candidate) => candidate.priority == priority)
        .toList(growable: false);
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
      return isNominalSubtype(leftDefinition, rightDefinition) &&
          !isNominalSubtype(rightDefinition, leftDefinition);
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
}
