part of "../portable_presentation_renderer.dart";

extension _PortableDelegationRendering on PortablePresentationNodeRenderer {
  Widget _renderPolymorphicMatch(
    skir.PolymorphicMatchElement element,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.read(element.binding);
    final actual = switch (value) {
      skir.DataValue_namedWrapper(:final value) => skir.TypeUse.wrapNamed(
        value.actualType,
      ),
      _ => null,
    };
    if (actual == null) {
      final fallback = element.fallback;
      return fallback == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: fallback, scope: childScope);
    }
    final selected = element.cases
        .where(
          (candidate) =>
              childScope.catalog?.isReadableAs(
                actual,
                candidate.concreteType,
              ) ??
              actual == candidate.concreteType,
        )
        .firstOrNull;
    final node = selected?.child ?? element.fallback;
    if (node == null) return const SizedBox.shrink();
    final nested = childScope.withBinding(
      element.binding,
      element.scopeBindingId,
    );
    return nested == null
        ? _diagnostic("The polymorphic value is unavailable")
        : PortablePresentationNodeRenderer(node: node, scope: nested);
  }

  Widget _renderInvocation(
    skir.PresentationInvocation invocation,
    PortablePresentationScope childScope,
  ) {
    final catalog = childScope.catalog;
    if (catalog == null) {
      return _diagnostic("The presentation catalog is unavailable");
    }
    var nested = childScope;
    skir.TypeSelection? target;
    for (final argument in invocation.arguments) {
      final value = nested.read(argument.binding);
      if (target == null && value is skir.DataValue_namedWrapper) {
        target = skir.TypeSelection.wrapComplete(value.value.actualType);
      }
      final rebound = nested.withBinding(argument.binding, argument.input);
      if (rebound == null) {
        return _diagnostic("A presentation argument is unavailable");
      }
      nested = rebound;
    }
    target ??= switch (nested
        .bindings[_configuredValueBindingId]
        ?.value
        .authoredActualType) {
      final actual? => skir.TypeSelection.wrapComplete(actual),
      null => null,
    };
    final host = childScope.host;
    final resource = childScope.resource;
    final projectionHost = switch (host) {
      final PortableCollectionProjectionHost value => value,
      _ => null,
    };
    if (projectionHost != null && resource != null) {
      target ??= projectionHost
          .projectResource(resource, context: childScope.invocation)
          ?.configuration;
    }
    final material = target == null
        ? null
        : catalog.presentationMaterial(invocation.presentationId, target);
    if (material == null) {
      return _diagnostic("The invoked presentation is unavailable");
    }
    if (nested.activePresentations.contains(invocation.presentationId)) {
      return _diagnostic("The invoked presentation is recursive");
    }
    return PortablePresentationNodeRenderer(
      node: material.layout,
      scope: nested
          .withActivePresentation(invocation.presentationId)
          .withMaterial(material),
    );
  }

  Widget _renderDefaultPresentation(
    skir.DefaultPresentationElement element,
    PortablePresentationScope childScope,
  ) {
    if (element.presentationId != null) {
      return _renderTypeDefault(element, childScope);
    }
    final owner = childScope.recordOwning(element.control.binding);
    final checked = childScope.catalog;
    if (owner != null && checked != null) {
      final selected = checked.fieldPresentation(
        owner.type,
        owner.field,
        childScope.role ?? skir.PresentationRole.inspector,
      );
      switch (selected) {
        case SelectedEditorFieldPresentation():
          return _renderInheritedField(
            selected,
            owner,
            element.control,
            childScope,
          );
        case ConflictingEditorFieldPresentation():
          return _diagnostic(
            "Field ${owner.field} has conflicting presentations",
          );
        case InvalidEditorFieldPresentation(:final diagnostic):
          return _diagnostic(diagnostic);
        case MissingEditorFieldPresentation():
          break;
      }
    }
    return _renderTypeDefault(element, childScope, fallbackLabel: owner?.field);
  }

  Widget _renderInheritedField(
    SelectedEditorFieldPresentation selected,
    PortableRecordFieldOwner owner,
    skir.BoundControl request,
    PortablePresentationScope caller,
  ) {
    final active = ActiveFieldPresentation(
      identity: selected.identity,
      owner: owner.address,
    );
    if (caller.activeFieldPresentations.contains(active)) {
      return _diagnostic(
        "Field ${owner.field} presentation inheritance is recursive",
      );
    }
    final nested = owner.scope
        .withMaterialContext(selected.material)
        .copyWith(
          activeFieldPresentations: {
            ...caller.activeFieldPresentations,
            active,
          },
        )
        .withAuthoredFragment(
          selected.node,
          includeRootPrefix: request.prefix == null,
        );
    final association = _resolveFieldAssociation(
      inherited: selected.node.boundControl!,
      inheritedScope: nested,
      local: request,
      localScope: caller,
      fallbackLabel: owner.field,
    );
    return PortablePresentationNodeRenderer(
      node: selected.node,
      scope: nested,
      fieldAssociation: association,
    );
  }

  Widget _renderTypeDefault(
    skir.DefaultPresentationElement element,
    PortablePresentationScope childScope, {
    String? fallbackLabel,
  }) {
    final association = childScope
        .associationFor(element.control)
        .withFallbackLabel(fallbackLabel);
    final controlScope = childScope.copyWith(
      associatedControl: element.control,
      fieldAssociation: association,
    );
    final nested = controlScope.withConfiguredValue(element.control.binding);
    if (nested == null) {
      return _diagnostic("The default presentation binding is unavailable");
    }
    final selection = _selectionFor(element.control.binding, controlScope);
    final checked = controlScope.catalog;
    if (selection != null && checked != null) {
      final material = element.presentationId == null
          ? switch (checked.selectPresentation(
              selection,
              skir.PresentationRole.inspector,
            )) {
              SelectedEditorPresentation(:final material) => material,
              _ => null,
            }
          : checked.presentationMaterial(element.presentationId!, selection);
      if (material != null) {
        if (controlScope.activePresentations.contains(material.provider)) {
          if (element.presentationId != null) {
            return _diagnostic("Presentation delegation is recursive");
          }
        } else {
          return _controlAssociation(
            element.control,
            controlScope,
            PortablePresentationNodeRenderer(
              node: material.layout,
              scope: nested
                  .withActivePresentation(material.provider)
                  .withMaterial(material),
            ),
          );
        }
      }
    }
    final expected = controlScope.expectedType(element.control.binding);
    final generated = _defaultElement(
      expected ?? _typeUseForSelection(selection),
      element.control,
      controlScope,
    );
    return generated == null
        ? _diagnostic("No default presentation is available")
        : PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "${node.nodeId}.default",
              properties: skir.PresentationProperties.defaultInstance,
              element: generated,
              header: null,
            ),
            scope: controlScope,
            fieldAssociation: association,
          );
  }

  Widget _renderRemainingFields(
    BuildContext context,
    skir.RemainingFieldsElement element,
    PortablePresentationScope childScope,
  ) {
    final checked = childScope.catalog;
    final configured = childScope.bindings[_configuredValueBindingId];
    if (checked == null || configured == null) {
      return _diagnostic("The remaining fields are unavailable");
    }
    final selection = childScope.configuredSelection;
    if (selection == null) {
      return _diagnostic("The remaining field type is unavailable");
    }
    final claims = childScope.withRemainderExclusions(
      childScope.inspectorClaims(),
      element,
      node.nodeId,
    );
    if (claims.problems.isNotEmpty) {
      return _diagnostic(claims.problems.values.first);
    }
    final inherited = _renderInheritedInspector(childScope, claims);
    if (inherited != null) return inherited;
    final excluded = claims.reservedFields;
    final children = <Widget>[];
    for (final field in checked.fields(selection)) {
      if (excluded.contains(field.template.key)) continue;
      final reference = skir.BindingRef(
        bindingId: _configuredValueBindingId,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: field.template.key)],
        ),
      );
      children.add(
        PortablePresentationNodeRenderer(
          key: ValueKey("${node.nodeId}.${field.template.key}"),
          node: skir.PresentationNode(
            nodeId: "${node.nodeId}.${field.template.key}.control",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.createDefaultPresentation(
              control: _generatedControl(reference),
              presentationId: null,
            ),
            header: null,
          ),
          scope: childScope,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: children,
    );
  }

  skir.TypeSelection? _selectionFor(
    skir.BindingRef reference,
    PortablePresentationScope childScope,
  ) {
    final actual = childScope.read(reference)?.authoredActualType;
    if (actual != null) return skir.TypeSelection.wrapComplete(actual);
    final expected = childScope.expectedType(reference).withoutNullableWrappers;
    return switch (expected) {
      skir.TypeUse_namedWrapper(:final value) =>
        skir.TypeSelection.wrapComplete(value),
      _ => null,
    };
  }

  skir.TypeUse? _typeUseForSelection(skir.TypeSelection? selection) =>
      switch (selection) {
        skir.TypeSelection_completeWrapper(:final value) =>
          skir.TypeUse.wrapNamed(value),
        _ => null,
      };

  skir.PresentationElement? _defaultElement(
    skir.TypeUse? declared,
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final reference = control.binding;
    final type = declared.withoutNullableWrappers;
    if (declared is skir.TypeUse_nullableWrapper) {
      final nested = _defaultElement(
        declared.value.value,
        _generatedControl(reference),
        childScope,
      );
      return skir.PresentationElement.wrapNullableInput(
        skir.NullableControl(
          control: control,
          emptyText: null,
          clearLabel: null,
          valuePresentation: nested == null
              ? null
              : skir.PresentationNode(
                  nodeId: "${node.nodeId}.nullable",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: nested,
                  header: null,
                ),
        ),
      );
    }
    if (type case skir.TypeUse_scalarWrapper(:final value)) {
      return _scalarDefaultElement(value, control);
    }
    if (type case skir.TypeUse_namedWrapper(:final value)) {
      final representation = childScope.catalog
          ?.published(value.definition)
          ?.definition
          .representation;
      return switch (representation) {
        skir.RepresentationTemplate_scalarWrapper(:final value) =>
          _scalarDefaultElement(value.kind, control),
        skir.RepresentationTemplate_recordWrapper() =>
          skir.PresentationElement.wrapRecordInput(
            skir.RecordControl(
              control: control,
              appearance: null,
              content: null,
              fieldPresentation: skir.PresentationNode(
                nodeId: "${node.nodeId}.fields",
                properties: skir.PresentationProperties.defaultInstance,
                element: skir.PresentationElement.wrapScopedBinding(
                  skir.ScopedBindingElement(
                    binding: reference,
                    scopeBindingId: _configuredValueBindingId,
                    child: skir.PresentationNode(
                      nodeId: "${node.nodeId}.remainingFields",
                      properties: skir.PresentationProperties.defaultInstance,
                      element: skir.PresentationElement.wrapRemainingFields(
                        skir.RemainingFieldsElement(
                          excluded: const [],
                          excludedParts: const [],
                        ),
                      ),
                      header: null,
                    ),
                  ),
                ),
                header: null,
              ),
            ),
          ),
        skir.RepresentationTemplate_sequenceWrapper(:final value) =>
          value.kind == skir.CollectionKind.set_
              ? skir.PresentationElement.wrapSetInput(
                  skir.SetControl(
                    control: control,
                    appearance: null,
                    content: null,
                    itemPresentation: null,
                    allowAdd: true,
                    allowRemove: true,
                    itemBindingId: skir.ExpressionBindingId(
                      value: "generated_item",
                    ),
                  ),
                )
              : skir.PresentationElement.wrapListInput(
                  skir.ListControl(
                    control: control,
                    appearance: null,
                    content: null,
                    itemPresentation: null,
                    allowAdd: true,
                    allowRemove: true,
                    allowReorder: true,
                    itemBindingId: skir.ExpressionBindingId(
                      value: "generated_item",
                    ),
                    indexBindingId: skir.ExpressionBindingId(
                      value: "generated_index",
                    ),
                  ),
                ),
        skir.RepresentationTemplate_mappingWrapper() =>
          skir.PresentationElement.wrapMapInput(
            skir.MapControl(
              control: control,
              appearance: null,
              content: null,
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: skir.ExpressionBindingId(value: "generated_key"),
              valueBindingId: skir.ExpressionBindingId(
                value: "generated_value",
              ),
            ),
          ),
        skir.RepresentationTemplate_enumerationWrapper() =>
          skir.PresentationElement.wrapEnumInput(
            (skir.EnumControl.defaultInstance.toMutable()..control = control)
                .toFrozen(),
          ),
        skir.RepresentationTemplate_linkWrapper() =>
          skir.PresentationElement.wrapLinkInput(
            skir.LinkControl(
              control: control,
              appearance: null,
              content: null,
              inputAppearance: null,
              inputContent: null,
              popup: null,
              allowReorder: true,
              candidatePolicy: null,
              rejectionDisplay: skir.LinkRejectionDisplay.disabled,
              sourceId: null,
            ),
          ),
        _ => null,
      };
    }
    return null;
  }

  skir.PresentationElement? _scalarDefaultElement(
    skir.ScalarKind kind,
    skir.BoundControl control,
  ) {
    return switch (kind) {
      skir.ScalarKind.boolean => skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
      skir.ScalarKind.text => skir.PresentationElement.wrapTextInput(
        (skir.TextControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
      skir.ScalarKind_integerWrapper() ||
      skir.ScalarKind_floatWrapper() ||
      skir.ScalarKind.decimal => skir.PresentationElement.wrapNumericInput(
        (skir.NumericControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
      skir.ScalarKind.timestamp => skir.PresentationElement.wrapDateTimeInput(
        (skir.DateTimeControl.defaultInstance.toMutable()
              ..control = control
              ..includeDate = true
              ..includeTime = true)
            .toFrozen(),
      ),
      skir.ScalarKind.duration => skir.PresentationElement.wrapDurationInput(
        (skir.DurationControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
      skir.ScalarKind.bytes => skir.PresentationElement.wrapBytesInput(
        (skir.BytesControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
      _ => null,
    };
  }
}

skir.BoundControl _generatedControl(skir.BindingRef reference) =>
    skir.BoundControl(
      binding: reference,
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    );
