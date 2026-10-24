part of "checked_editor_catalog.dart";

/// Reuses canonical layout members without copying their controls or source scope.
extension InheritedInspectorCatalog on CheckedEditorCatalog {
  CheckedInheritableLayout _checkInheritableLayout(
    skir.PresentationMaterial material,
  ) {
    final nodes = <String, skir.PresentationNode>{};
    String? problem;
    final declaredParts = <skir.PresentationPartId>{};
    final declarations = <String>{};
    final ambiguous = <String>{};
    void index(skir.PresentationNode node) {
      if (node.element case skir.PresentationElement_partWrapper(:final value)
          when value.body != null) {
        declaredParts.add(value.key);
        declarations.add(node.nodeId);
      }
      final previous = nodes[node.nodeId];
      if (ambiguous.contains(node.nodeId) ||
          (previous != null && previous != node)) {
        problem ??= "the source node id ${node.nodeId} is ambiguous";
        ambiguous.add(node.nodeId);
        nodes.remove(node.nodeId);
      } else {
        nodes[node.nodeId] = node;
      }
      for (final child in node.nestedPresentationNodes) {
        index(child);
      }
    }

    index(material.layout);
    final ids = material.inheritableNodes.toSet();
    if (ids.length != material.inheritableNodes.length) {
      problem ??= "the inherited membership repeats a source node";
    }
    final eligible = <String>{};
    void admit(String id) {
      if (!eligible.add(id) && ids.contains(id)) {
        problem ??= "the inherited member $id appears more than once";
      }
    }

    final ancestry = <String, List<String>>{};
    final ownerRemainders = <String>[];
    final canonicalFields = <String>{};
    void visit(skir.PresentationNode node, [List<String> parents = const []]) {
      ancestry[node.nodeId] = parents;
      if (node.boundControl != null) {
        if (node.boundControl!.binding.path.segments.singleOrNull
            case skir.PathSegment_fieldWrapper(:final value)) {
          canonicalFields.add(value.name);
        }
        admit(node.nodeId);
        return;
      }
      if (node.header != null ||
          node.properties.enabledIf != null ||
          node.properties.readOnly) {
        return;
      }
      switch (node.element) {
        case skir.PresentationElement_partWrapper(:final value):
          admit(node.nodeId);
          final subject = material.subject;
          if (value.key.name.trim().isEmpty ||
              subject is! skir.TypeTemplate_namedWrapper ||
              !isNominalSubtype(subject.value.definition, value.key.owner)) {
            problem ??= "the part key has an incompatible declaring owner";
          }
        case skir.PresentationElement_remainingFieldsWrapper():
          admit(node.nodeId);
          ownerRemainders.add(node.nodeId);
        case skir.PresentationElement_childrenWrapper():
          admit(node.nodeId);
          for (final child in node.presentationBodyNodes) {
            visit(child, [...parents, node.nodeId]);
          }
        default:
          break;
      }
    }

    visit(material.layout);
    for (final id in ids) {
      if (!nodes.containsKey(id)) {
        problem ??= "the source node $id is missing";
      } else if (!eligible.contains(id)) {
        problem ??= "the source node $id is outside neutral owner layout";
      }
    }
    final subject = material.subject;
    final owner = subject is skir.TypeTemplate_namedWrapper
        ? published(subject.value.definition)
        : null;
    for (final id in ids) {
      final node = nodes[id];
      final control = node?.boundControl;
      if (control == null) continue;
      final segments = control.binding.path.segments;
      final field = segments.singleOrNull;
      if (control.binding.bindingId.value != "configured_value" ||
          field is! skir.PathSegment_fieldWrapper) {
        problem ??= "the source control does not bind a direct owner field";
        continue;
      }
      final declared = owner?.effectiveFields
          .where((entry) => entry.key == field.value.name)
          .singleOrNull;
      if (declared == null) {
        problem ??= "the declaring subject has no matching field";
        continue;
      }
    }
    final remainderCount = ids.isEmpty ? 0 : ownerRemainders.length;
    if (remainderCount == 1) {
      if (!ids.contains(ownerRemainders.single)) {
        problem ??= "the inherited structure omits its owner remainder";
      }
      if (ids.any(
        (id) => ancestry[id]?.any((parent) => !ids.contains(parent)) ?? false,
      )) {
        problem ??= "the inherited structure omits a neutral ancestor";
      }
    }
    for (final id in declarations) {
      if (!ids.contains(id)) {
        problem ??= "the reusable part declaration $id is not published";
      } else if (!eligible.contains(id)) {
        problem ??=
            "the reusable part declaration $id is outside neutral owner layout";
      }
    }
    final definitions = <skir.PresentationPartId>{};
    for (final id in ids) {
      if (nodes[id]?.element
          case skir.PresentationElement_partWrapper(:final value)
          when value.body != null) {
        if (!definitions.add(value.key)) {
          problem ??= "the material repeats a part definition";
        }
      }
    }
    return CheckedInheritableLayout(
      nodes: nodes,
      inheritableNodes: ids,
      remainderCount: remainderCount,
      canonicalFields: canonicalFields,
      declaredParts: declaredParts,
      diagnostic: problem,
    );
  }

  String? _partBodyProblem(
    skir.PresentationNode body,
    skir.PresentationMaterial material,
  ) {
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final owner = AuthoredBindingAddress(
      root: AuthoredBindingRoot.local(configured),
      path: const [],
    );
    String? problem;
    final subject = material.subject;
    final declaredFields = subject is skir.TypeTemplate_namedWrapper
        ? published(subject.value.definition)?.effectiveFields
              .map((field) => field.key)
              .toSet()
        : null;
    AuthoredPresentationIndex.build(
      body,
      {configured: owner},
      sources: {
        for (final source in material.dependencies.collections)
          source.sourceId: source,
      },
      onEditableBinding: (binding, address) {
        final field = address?.fieldBelow(owner);
        if (field == null || declaredFields?.contains(field) != true) {
          problem ??=
              "the part body has an unresolved, foreign, or whole owner editor";
        }
      },
      onPart: (node, part, aliases) {
        final address = aliases[configured];
        if (address == null ||
            (address != owner && address.fieldBelow(owner) == null)) {
          problem ??= "the nested part owner is unresolved or foreign";
        }
        return part.body != null;
      },
    );
    return problem;
  }

  Iterable<SelectedEditorPresentation> _memberMaterials(
    skir.TypeSelection owner,
    skir.PresentationRole role,
  ) sync* {
    for (final material in snapshot.presentationMaterials) {
      if (material.role != role ||
          !_presentationTargetMatches(material.target, owner) ||
          !_fieldMaterialSubjectMatches(material, owner)) {
        continue;
      }
      final descriptor = snapshot.presentations
          .where((entry) => entry.id == material.provider)
          .firstOrNull;
      if (descriptor == null) continue;
      yield SelectedEditorPresentation(
        requestedRole: role,
        resolvedRole: role,
        descriptor: descriptor,
        material: material,
      );
    }
  }

  List<SelectedEditorPresentation> _rankMemberMaterials(
    List<SelectedEditorPresentation> candidates,
  ) {
    final descriptors = <skir.PresentationId, skir.PresentationDescriptor>{
      for (final candidate in candidates)
        candidate.descriptor.id: candidate.descriptor,
    };
    final winners = _rankPresentationDescriptors(descriptors.values.toList())
        .map((entry) => entry.id)
        .toSet();
    return candidates
        .where((candidate) => winners.contains(candidate.descriptor.id))
        .toList();
  }

  String? _memberProblem(
    skir.PresentationMaterial material,
    skir.TypeSelection owner,
  ) {
    final structural = _inheritableViews[material]!.diagnostic;
    if (structural != null) return structural;
    if (owner is skir.TypeSelection_pendingWrapper) return null;
    final issues = presentationExpressionProblems(material, owner);
    return issues.isEmpty
        ? null
        : "the source expressions are invalid (${issues.join(', ')})";
  }

  /// Continues only through strictly less specific named inspector targets.
  EditorInspectorLayoutSelection nextInspectorLayout({
    required skir.TypeSelection actualOwner,
    required skir.PresentationTarget below,
    skir.PresentationRole role = skir.PresentationRole.inspector,
  }) {
    if (role != skir.PresentationRole.inspector) {
      return const MissingEditorInspectorLayout();
    }
    final candidates = _rankMemberMaterials([
      for (final candidate in _memberMaterials(actualOwner, role))
        if (candidate.descriptor.target
                is skir.PresentationTarget_namedWrapper &&
            _isMoreSpecific(below, candidate.descriptor.target) &&
            _inheritableViews[candidate.material]!.remainderCount == 1)
          candidate,
    ]);
    if (candidates.isEmpty) return const MissingEditorInspectorLayout();
    if (candidates.length != 1) {
      return ConflictingEditorInspectorLayout(
        candidates: candidates.map((entry) => entry.descriptor.id).toList(),
      );
    }
    final selected = candidates.single;
    final problem = _memberProblem(selected.material, actualOwner);
    if (problem != null) {
      return InvalidEditorInspectorLayout(
        diagnostic:
            "Inherited inspector ${selected.descriptor.id.namespace}:${selected.descriptor.id.name}: $problem",
      );
    }
    return SelectedEditorInspectorLayout(
      descriptor: selected.descriptor,
      material: selected.material,
      inheritableNodes: _inheritableViews[selected.material]!.inheritableNodes,
    );
  }

  /// Resolves one atomic body and the fallback fields suppressed by replacements.
  EditorPartPresentationSelection partPresentation(
    skir.TypeSelection actualOwner,
    skir.PresentationPartId key,
    skir.PresentationRole role, {
    EditorPartDeclaration? local,
  }) => _resolvePart(actualOwner, key, role, local, const {});

  EditorPartPresentationSelection _resolvePart(
    skir.TypeSelection owner,
    skir.PresentationPartId key,
    skir.PresentationRole role,
    EditorPartDeclaration? local,
    Set<skir.PresentationPartId> active, {
    skir.PresentationTarget? below,
    bool bounded = false,
  }) {
    String diagnostic(String problem) => "Part ${key.name}: $problem";
    if (active.contains(key)) {
      return InvalidEditorPartPresentation(
        diagnostic: diagnostic(
          "recursive part calls (${[...active.map((entry) => entry.name), key.name].join(' → ')})",
        ),
      );
    }
    if (!isNominalSubtype(
      selected(owner)?.definition.id ?? key.owner,
      key.owner,
    )) {
      return InvalidEditorPartPresentation(
        diagnostic: diagnostic("the key does not belong to this record"),
      );
    }
    final candidates = <SelectedEditorPresentation>[];
    for (final candidate in _memberMaterials(owner, role)) {
      if (below != null &&
          !_isMoreSpecific(below, candidate.descriptor.target)) {
        continue;
      }
      final view = _inheritableViews[candidate.material]!;
      if ((view.diagnostic != null && view.declaredParts.contains(key)) ||
          view.inheritableNodes.any(
            (id) => switch (view.nodes[id]?.element) {
              skir.PresentationElement_partWrapper(:final value) =>
                value.key == key && value.body != null,
              _ => false,
            },
          )) {
        candidates.add(candidate);
      }
    }
    final winners = local == null
        ? _rankMemberMaterials(candidates)
        : <SelectedEditorPresentation>[];
    if (local == null && winners.isEmpty) {
      return const MissingEditorPartPresentation();
    }
    if (winners.length > 1) {
      return ConflictingEditorPartPresentation(
        candidates: winners.map((entry) => entry.descriptor.id).toList(),
      );
    }
    final material = local?.material ?? winners.single.material;
    final problem = _memberProblem(material, owner);
    if (problem != null) {
      return InvalidEditorPartPresentation(diagnostic: diagnostic(problem));
    }
    final body =
        local?.body ??
        [
          for (final id in _inheritableViews[material]!.inheritableNodes)
            if (_inheritableViews[material]!.nodes[id]?.element
                case skir.PresentationElement_partWrapper(:final value)
                when value.key == key && value.body != null)
              value.body!,
        ].single;
    final bodyProblem = _partBodyProblem(body, material);
    if (bodyProblem != null) {
      return InvalidEditorPartPresentation(diagnostic: diagnostic(bodyProblem));
    }
    if (bounded) {
      return SelectedEditorPartPresentation(
        key: key,
        material: material,
        body: body,
        editedFields: const {},
        fallbackFields: const {},
        claimedParts: {key},
      );
    }
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final origin = AuthoredBindingAddress(
      root: AuthoredBindingRoot.local(configured),
      path: const [],
    );
    final edited = <String>{};
    final independent = <String>{};
    final atomic = <String>{};
    final fallback = <String>{};
    final claimedParts = <skir.PresentationPartId>{key};
    String? footprintProblem;
    final nextActive = {...active, key};
    AuthoredPresentationIndex.build(
      body,
      {configured: origin},
      sources: {
        for (final source in material.dependencies.collections)
          source.sourceId: source,
      },
      onEditableBinding: (binding, address) {
        final field = address?.fieldBelow(origin);
        if (field == null) {
          footprintProblem ??=
              "the body has an unresolved, foreign, or whole owner editor";
        } else {
          independent.add(field);
          edited.add(field);
        }
      },
      onPart: (node, part, aliases) {
        final address = aliases[configured];
        if (address == null) {
          footprintProblem ??= "the nested part owner is unresolved";
          return false;
        }
        final projected = address.fieldBelow(origin);
        if (address != origin && projected == null) {
          footprintProblem ??= "the nested part owner is foreign";
          return false;
        }
        // Nested records have separate part namespaces and reserve their containing field.
        var nestedOwner = owner;
        if (projected != null) {
          final type = valueTypeAt(
            owner,
            skir.ValuePath(
              segments: [
                for (final step in address.path)
                  switch (step) {
                    ExactAuthoredPathStep(:final segment) => segment,
                    AnyAuthoredItem() => skir.PathSegment.createItem(
                      id: skir.ItemId(value: "footprint"),
                    ),
                  },
              ],
            ),
          );
          if (type is! skir.TypeUse_namedWrapper) {
            footprintProblem ??= "the nested part record type is unavailable";
            return false;
          }
          nestedOwner = skir.TypeSelection.wrapComplete(type.value);
        }
        final nested = _resolvePart(
          nestedOwner,
          part.key,
          role,
          part.body == null
              ? null
              : EditorPartDeclaration(material: material, body: part.body!),
          address == origin ? nextActive : const {},
          bounded: projected != null,
        );
        if (nested is SelectedEditorPartPresentation) {
          if (projected != null) {
            if (atomic.contains(projected)) {
              footprintProblem ??=
                  "the body contains overlapping atomic part editors";
            }
            atomic.add(projected);
            edited.add(projected);
            fallback.add(projected);
          } else {
            if (claimedParts.intersection(nested.claimedParts).isNotEmpty) {
              footprintProblem ??=
                  "the body contains overlapping atomic part keys";
            }
            claimedParts.addAll(nested.claimedParts);
            if (edited.intersection(nested.editedFields).isNotEmpty) {
              footprintProblem ??=
                  "the body contains overlapping atomic part editors";
            }
            atomic.addAll(nested.editedFields);
            edited.addAll(nested.editedFields);
            fallback.addAll(nested.fallbackFields);
          }
        } else {
          footprintProblem ??= nested is InvalidEditorPartPresentation
              ? nested.diagnostic
              : "the nested part ${part.key.name} is unavailable or ambiguous";
        }
        return false;
      },
    );
    if (independent.intersection(atomic).isNotEmpty) {
      footprintProblem ??= "the body contains overlapping atomic part editors";
    }
    if (footprintProblem != null) {
      return InvalidEditorPartPresentation(
        diagnostic: diagnostic(footprintProblem!),
      );
    }
    // A replacement suppresses the selected ancestor chain, never losing same target alternatives.
    final inherited = _resolvePart(
      owner,
      key,
      role,
      null,
      active,
      below: material.target,
    );
    switch (inherited) {
      case SelectedEditorPartPresentation():
        fallback.addAll(inherited.fallbackFields);
      case InvalidEditorPartPresentation(:final diagnostic):
        return InvalidEditorPartPresentation(diagnostic: diagnostic);
      case ConflictingEditorPartPresentation():
        return inherited;
      case MissingEditorPartPresentation():
        break;
    }
    fallback.addAll(edited);
    return SelectedEditorPartPresentation(
      key: key,
      material: material,
      body: body,
      editedFields: edited,
      fallbackFields: fallback,
      claimedParts: claimedParts,
    );
  }
}
