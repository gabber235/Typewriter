part of "../portable_presentation_renderer.dart";

/// A structural occurrence keeps its lexical owner, including collection items.
@freezed
abstract class PortableAuthoredPart with _$PortableAuthoredPart {
  const factory PortableAuthoredPart({
    required String nodeId,
    required skir.PresentationPartElement part,
    required AuthoredBindingAddress? owner,
  }) = _PortableAuthoredPart;
}

/// Live edits detect overlap. Reservations also retain replaced part fields.
@freezed
abstract class PortableInspectorClaims with _$PortableInspectorClaims {
  const factory PortableInspectorClaims({
    @Default({}) Set<String> editedFields,
    @Default({}) Set<String> reservedFields,
    @Default({}) Set<String> excludedFields,
    @Default({}) Set<skir.PresentationPartId> parts,
    @Default({}) Map<String, String> problems,
  }) = _PortableInspectorClaims;
}

/// Continuation belongs to an inspector application, not a delegated control.
@freezed
abstract class PortableInspectorFrame with _$PortableInspectorFrame {
  const factory PortableInspectorFrame({
    required AuthoredBindingAddress owner,
    required skir.TypeSelection actualType,
    required skir.PresentationTarget sourceTarget,
    required skir.PresentationId source,
    @Default(PortableInspectorClaims()) PortableInspectorClaims higher,
  }) = _PortableInspectorFrame;
}

@freezed
abstract class ActiveInspectorLayout with _$ActiveInspectorLayout {
  const factory ActiveInspectorLayout({
    required skir.PresentationId source,
    required AuthoredBindingAddress owner,
  }) = _ActiveInspectorLayout;
}

@freezed
abstract class ActivePartPresentation with _$ActivePartPresentation {
  const factory ActivePartPresentation({
    required skir.PresentationPartId key,
    required AuthoredBindingAddress owner,
    required skir.PresentationRole role,
  }) = _ActivePartPresentation;
}

extension PortableInspectorComposition on PortablePresentationScope {
  PortablePresentationScope startInspectorLayout() {
    final source = material;
    final owner = authoredAliases[_configuredValueBindingId];
    final actual = configuredSelection;
    final descriptor = catalog?.snapshot.presentations
        .where((entry) => entry.id == source?.provider)
        .firstOrNull;
    if (role != skir.PresentationRole.inspector ||
        source == null ||
        owner == null ||
        actual == null ||
        descriptor == null) {
      return copyWith(inspectorFrame: null);
    }
    return copyWith(
      inspectorFrame: PortableInspectorFrame(
        owner: owner,
        actualType: actual,
        sourceTarget: descriptor.target,
        source: descriptor.id,
      ),
      activeInspectorLayouts: {
        ...activeInspectorLayouts,
        ActiveInspectorLayout(source: descriptor.id, owner: owner),
      },
    );
  }

  PortableInspectorFrame? get currentInspectorFrame {
    final owner = authoredAliases[_configuredValueBindingId];
    return owner != null && inspectorFrame?.owner == owner
        ? inspectorFrame
        : null;
  }

  EditorPartPresentationSelection resolvePart(
    skir.PresentationPartElement part,
  ) {
    final actual = configuredSelection;
    final checked = catalog;
    if (actual == null || checked == null) {
      return const InvalidEditorPartPresentation(
        diagnostic: "The part record is unavailable",
      );
    }
    if (part.body != null && material == null) {
      return const InvalidEditorPartPresentation(
        diagnostic: "The part source material is unavailable",
      );
    }
    return checked.partPresentation(
      actual,
      part.key,
      role ?? skir.PresentationRole.inspector,
      local: part.body == null
          ? null
          : EditorPartDeclaration(material: material!, body: part.body!),
    );
  }

  /// Reserves authored destinations structurally, including hidden branches.
  /// Replaced parts retain their fallback field reservation, preventing a
  /// remaining fields continuation from reintroducing the displaced controls.
  PortableInspectorClaims inspectorClaims() {
    final owner = authoredAliases[_configuredValueBindingId];
    if (owner == null) return const PortableInspectorClaims();
    final higher =
        currentInspectorFrame?.higher ?? const PortableInspectorClaims();
    final independent = {
      for (final use
          in independentAuthoredIndex?.uses ??
              authoredIndex?.uses ??
              const <AuthoredBindingUse>[])
        ?use.address.fieldBelow(owner),
    };
    final edited = {...higher.editedFields, ...independent};
    final reserved = {...higher.reservedFields, ...independent};
    final keys = {...higher.parts};
    final problems = {...higher.problems};
    final owners = <String, String>{};
    final partOwners = <skir.PresentationPartId, String>{};
    for (final occurrence in authoredParts) {
      final partOwner = occurrence.owner;
      if (partOwner == null) {
        problems[occurrence.nodeId] =
            "Part ${occurrence.part.key.name} has no record owner";
        continue;
      }
      if (!partOwner.matches(owner)) {
        final field = partOwner.fieldBelow(owner);
        if (field != null) {
          edited.add(field);
          reserved.add(field);
        }
        continue;
      }
      final part = occurrence.part;
      final selected = resolvePart(part);
      if (selected is! SelectedEditorPartPresentation) {
        problems[occurrence.nodeId] = _partSelectionProblem(part.key, selected);
        continue;
      }
      final overlap = selected.editedFields.intersection(edited);
      final excluded = selected.editedFields.intersection(
        higher.excludedFields,
      );
      final overlappingParts = selected.claimedParts.intersection(keys);
      if (overlappingParts.isNotEmpty ||
          overlap.isNotEmpty ||
          excluded.isNotEmpty) {
        final conflicts = {
          ...overlap,
          ...excluded,
          for (final key in overlappingParts) "part ${key.name}",
        }.toList()..sort();
        final problem =
            "Part ${part.key.name} overlaps ${conflicts.join(', ')}. Replace or exclude the whole part.";
        problems[occurrence.nodeId] = problem;
        for (final field in overlap) {
          if (owners[field] case final previous?) problems[previous] = problem;
        }
        for (final key in overlappingParts) {
          if (partOwners[key] case final previous?) {
            problems[previous] = problem;
          }
        }
      }
      keys.addAll(selected.claimedParts);
      for (final key in selected.claimedParts) {
        partOwners[key] = occurrence.nodeId;
      }
      for (final field in selected.editedFields) {
        owners[field] = occurrence.nodeId;
      }
      edited.addAll(selected.editedFields);
      reserved.addAll(selected.fallbackFields);
    }
    return PortableInspectorClaims(
      editedFields: edited,
      reservedFields: reserved,
      excludedFields: higher.excludedFields,
      parts: keys,
      problems: problems,
    );
  }

  PortableInspectorClaims withRemainderExclusions(
    PortableInspectorClaims claims,
    skir.RemainingFieldsElement element,
    String nodeId,
  ) {
    final fields = {
      for (final pattern in element.excluded)
        if (pattern.segments.length == 1)
          if (pattern.segments.single
              case skir.FieldPatternSegment_fieldWrapper(:final value))
            value.name,
    };
    final reserved = {...claims.reservedFields, ...fields};
    final parts = {...claims.parts, ...element.excludedParts};
    final problems = {...claims.problems};
    for (final key in element.excludedParts) {
      final selected = resolvePart(
        skir.PresentationPartElement(key: key, body: null),
      );
      if (selected is SelectedEditorPartPresentation) {
        reserved.addAll(selected.fallbackFields);
        parts.addAll(selected.claimedParts);
      } else {
        problems[nodeId] = _partSelectionProblem(key, selected);
      }
    }
    return claims.copyWith(
      reservedFields: reserved,
      excludedFields: {...claims.excludedFields, ...fields},
      parts: parts,
      problems: problems,
    );
  }
}

String _partSelectionProblem(
  skir.PresentationPartId key,
  EditorPartPresentationSelection selected,
) => switch (selected) {
  InvalidEditorPartPresentation(:final diagnostic) => diagnostic,
  ConflictingEditorPartPresentation() =>
    "Part ${key.name} has conflicting presentations",
  _ => "Part ${key.name} is unavailable",
};

extension _PortableInspectorRendering on PortablePresentationNodeRenderer {
  Widget _renderPart(
    skir.PresentationPartElement element,
    PortablePresentationScope childScope,
  ) {
    final owner = childScope.authoredAliases[_configuredValueBindingId];
    if (owner == null) return _diagnostic("The part record is unavailable");
    final active = ActivePartPresentation(
      key: element.key,
      owner: owner,
      role: childScope.role ?? skir.PresentationRole.inspector,
    );
    if (childScope.activeParts.contains(active)) {
      return _diagnostic("Part ${element.key.name} is recursive");
    }
    final claims = childScope.inspectorClaims();
    if (claims.problems[node.nodeId] case final problem?) {
      return _diagnostic(problem);
    }
    final selected = childScope.resolvePart(element);
    if (selected is! SelectedEditorPartPresentation) {
      return _diagnostic(_partSelectionProblem(element.key, selected));
    }
    final nested = childScope
        .withMaterialContext(selected.material)
        .withAuthoredLayout(selected.body, startInspector: false)
        .copyWith(activeParts: {...childScope.activeParts, active});
    return PortablePresentationNodeRenderer(node: selected.body, scope: nested);
  }

  Widget? _renderInheritedInspector(
    PortablePresentationScope childScope,
    PortableInspectorClaims claims,
  ) {
    final frame = childScope.currentInspectorFrame;
    final checked = childScope.catalog;
    if (frame == null || checked == null) return null;
    final selected = checked.nextInspectorLayout(
      actualOwner: frame.actualType,
      below: frame.sourceTarget,
      role: childScope.role ?? skir.PresentationRole.inspector,
    );
    switch (selected) {
      case MissingEditorInspectorLayout():
        return null;
      case InvalidEditorInspectorLayout(:final diagnostic):
        return _diagnostic(diagnostic);
      case ConflictingEditorInspectorLayout():
        return _diagnostic(
          "The remaining fields have conflicting inherited inspector layouts",
        );
      case SelectedEditorInspectorLayout():
        final active = ActiveInspectorLayout(
          source: selected.descriptor.id,
          owner: frame.owner,
        );
        if (childScope.activeInspectorLayouts.contains(active)) {
          return _diagnostic("Inspector layout inheritance is recursive");
        }
        final projected = _projectInspectorNode(
          selected.material.layout,
          selected.inheritableNodes,
          claims,
        );
        if (projected == null) return const SizedBox.shrink();
        final nested = childScope
            .withMaterialContext(selected.material)
            .withAuthoredLayout(projected, startInspector: false)
            .copyWith(
              inspectorFrame: frame.copyWith(
                sourceTarget: selected.descriptor.target,
                source: selected.descriptor.id,
                higher: claims,
              ),
              activeInspectorLayouts: {
                ...childScope.activeInspectorLayouts,
                active,
              },
            );
        return PortablePresentationNodeRenderer(node: projected, scope: nested);
    }
  }
}

/// Only canonical admitted nodes contribute. Controls become default requests,
/// so layout position never overrides a more specific field behavior.
skir.PresentationNode? _projectInspectorNode(
  skir.PresentationNode node,
  Set<String> admitted,
  PortableInspectorClaims higher,
) {
  if (!admitted.contains(node.nodeId)) return null;
  final control = node.boundControl;
  if (control != null) {
    final field = switch (control.binding.path.segments.singleOrNull) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (field == null || higher.reservedFields.contains(field)) return null;
    return skir.PresentationNode(
      nodeId: node.nodeId,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createDefaultPresentation(
        control: _generatedControl(control.binding),
        presentationId: null,
      ),
      header: null,
    );
  }
  final element = node.element;
  if (element case skir.PresentationElement_partWrapper(:final value)) {
    if (higher.parts.contains(value.key)) return null;
    return skir.PresentationNode(
      nodeId: node.nodeId,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createPart(key: value.key, body: null),
      header: null,
    );
  }
  if (element is skir.PresentationElement_remainingFieldsWrapper) return node;
  if (element is! skir.PresentationElement_childrenWrapper) return null;
  skir.PresentationNode? project(skir.PresentationNode child) =>
      _projectInspectorNode(child, admitted, higher);
  List<skir.PresentationNode> nodes(Iterable<skir.PresentationNode> children) =>
      [for (final child in children) ?project(child)];
  final skir.ChildrenElement children;
  final original = element.value;
  if (original is skir.ChildrenElement_columnWrapper ||
      original is skir.ChildrenElement_rowWrapper) {
    final value = original is skir.ChildrenElement_columnWrapper
        ? original.value
        : (original as skir.ChildrenElement_rowWrapper).value;
    final projected = <skir.AxisChild>[];
    for (final child in value.children) {
      switch (child) {
        case skir.AxisChild_fixedWrapper(:final value):
          if (project(value) case final retained?) {
            projected.add(skir.AxisChild.wrapFixed(retained));
          }
        case skir.AxisChild_flexibleWrapper(:final value):
          if (project(value.child) case final retained?) {
            projected.add(
              skir.AxisChild.createFlexible(
                child: retained,
                flex: value.flex,
                fit: value.fit,
              ),
            );
          }
        default:
          break;
      }
    }
    if (projected.isEmpty) return null;
    final valueOut = skir.AxisChildrenElement(
      children: projected,
      layout: value.layout,
    );
    children = original is skir.ChildrenElement_columnWrapper
        ? skir.ChildrenElement.wrapColumn(valueOut)
        : skir.ChildrenElement.wrapRow(valueOut);
  } else if (original is skir.ChildrenElement_wrapWrapper) {
    final retained = nodes(original.value.children);
    if (retained.isEmpty) return null;
    children = skir.ChildrenElement.createWrap(
      children: retained,
      layout: original.value.layout,
    );
  } else if (original is skir.ChildrenElement_gridWrapper) {
    final retained = nodes(original.value.children);
    if (retained.isEmpty) return null;
    children = skir.ChildrenElement.createGrid(
      children: retained,
      layout: original.value.layout,
    );
  } else if (original is skir.ChildrenElement_stackWrapper) {
    final retained = <skir.StackChild>[
      for (final child in original.value.children)
        ?switch (child) {
          skir.StackChild_flowWrapper(:final value) => switch (project(value)) {
            final kept? => skir.StackChild.wrapFlow(kept),
            null => null,
          },
          skir.StackChild_positionedWrapper(:final value) => switch (project(
            value.child,
          )) {
            final kept? => skir.StackChild.wrapPositioned(
              (value.toMutable()..child = kept).toFrozen(),
            ),
            null => null,
          },
          _ => null,
        },
    ];
    if (retained.isEmpty) return null;
    children = skir.ChildrenElement.createStack(
      children: retained,
      alignment: original.value.alignment,
    );
  } else {
    return null;
  }
  return skir.PresentationNode(
    nodeId: node.nodeId,
    properties: node.properties,
    element: skir.PresentationElement.wrapChildren(children),
    header: null,
  );
}
