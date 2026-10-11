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
      PortableCollectionProjectionHost value => value,
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
    final nested = childScope.withConfiguredValue(element.binding);
    if (nested == null) {
      return _diagnostic("The default presentation binding is unavailable");
    }
    final selection = _selectionFor(element.binding, childScope);
    final checked = childScope.catalog;
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
        if (childScope.activePresentations.contains(material.provider)) {
          if (element.presentationId != null) {
            return _diagnostic("Presentation delegation is recursive");
          }
        } else {
          return PortablePresentationNodeRenderer(
            node: material.layout,
            scope: nested
                .withActivePresentation(material.provider)
                .withMaterial(material),
          );
        }
      }
    }
    final expected = childScope.expectedType(element.binding);
    final generated = _defaultElement(
      expected ?? _typeUseForSelection(selection),
      element.binding,
      childScope,
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
            scope: childScope,
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
    final selection = _selectionForConfigured(childScope, configured.value);
    if (selection == null) {
      return _diagnostic("The remaining field type is unavailable");
    }
    final excluded = {
      for (final pattern in element.excluded)
        if (pattern.segments.length == 1)
          switch (pattern.segments.single) {
            skir.FieldPatternSegment_fieldWrapper(:final value) => value.name,
            _ => null,
          },
    }..remove(null);
    final role = childScope.role;
    final explicit = role == null
        ? const <skir.ValuePath, EditorFieldPresentationSelection>{}
        : checked.fieldPresentations(selection, role);
    final children = <Widget>[];
    for (final field in checked.fields(selection)) {
      if (excluded.contains(field.template.key)) continue;
      final path = skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field.template.key)],
      );
      final reference = skir.BindingRef(
        bindingId: _configuredValueBindingId,
        path: path,
      );
      final choice = explicit[path];
      final generated = switch (choice) {
        SelectedEditorFieldPresentation(
          presentation: final selectedPresentation,
        ) =>
          skir.PresentationElement.createDefaultPresentation(
            binding: reference,
            presentationId: selectedPresentation,
          ),
        ConflictingEditorFieldPresentation() => null,
        null => _defaultElement(field.type, reference, childScope),
      };
      children.add(
        Column(
          key: ValueKey("${node.nodeId}.${field.template.key}"),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(field.template.key),
            if (choice is ConflictingEditorFieldPresentation)
              _diagnostic(
                "Field ${field.template.key} has conflicting presentations",
              )
            else if (generated == null)
              _diagnostic("Field ${field.template.key} has no presentation")
            else
              PortablePresentationNodeRenderer(
                node: skir.PresentationNode(
                  nodeId: "${node.nodeId}.${field.template.key}.control",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: generated,
                  header: null,
                ),
                scope: childScope,
              ),
          ],
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

  skir.TypeSelection? _selectionForConfigured(
    PortablePresentationScope childScope,
    skir.DataValue value,
  ) {
    final actual = value.authoredActualType;
    if (actual != null) return skir.TypeSelection.wrapComplete(actual);
    final resource = childScope.resource;
    final host = childScope.host;
    final projectionHost = switch (host) {
      PortableCollectionProjectionHost value => value,
      _ => null,
    };
    return resource == null || projectionHost == null
        ? null
        : projectionHost
              .projectResource(resource, context: childScope.invocation)
              ?.configuration;
  }

  skir.TypeUse? _typeUseForSelection(skir.TypeSelection? selection) =>
      switch (selection) {
        skir.TypeSelection_completeWrapper(:final value) =>
          skir.TypeUse.wrapNamed(value),
        _ => null,
      };

  skir.PresentationElement? _defaultElement(
    skir.TypeUse? declared,
    skir.BindingRef reference,
    PortablePresentationScope childScope,
  ) {
    final type = declared.withoutNullableWrappers;
    if (declared is skir.TypeUse_nullableWrapper) {
      final nested = _defaultElement(
        declared.value.value,
        reference,
        childScope,
      );
      return skir.PresentationElement.wrapNullableInput(
        skir.NullableControl(
          control: _generatedControl(reference),
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
      return _scalarDefaultElement(value, reference);
    }
    if (type case skir.TypeUse_namedWrapper(:final value)) {
      final representation = childScope.catalog
          ?.published(value.definition)
          ?.definition
          .representation;
      return switch (representation) {
        skir.RepresentationTemplate_scalarWrapper(:final value) =>
          _scalarDefaultElement(value.kind, reference),
        skir.RepresentationTemplate_recordWrapper() =>
          skir.PresentationElement.wrapRecordInput(
            skir.RecordControl(
              control: _generatedControl(reference),
              fieldPresentation: skir.PresentationNode(
                nodeId: "${node.nodeId}.fields",
                properties: skir.PresentationProperties.defaultInstance,
                element: skir.PresentationElement.wrapRemainingFields(
                  skir.RemainingFieldsElement(excluded: const []),
                ),
                header: null,
              ),
            ),
          ),
        skir.RepresentationTemplate_sequenceWrapper(:final value) =>
          value.kind == skir.CollectionKind.set_
              ? skir.PresentationElement.wrapSetInput(
                  skir.SetControl(
                    control: _generatedControl(reference),
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
                    control: _generatedControl(reference),
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
              control: _generatedControl(reference),
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
          skir.PresentationElement.wrapEnumInput(_generatedControl(reference)),
        skir.RepresentationTemplate_linkWrapper() =>
          skir.PresentationElement.wrapLinkInput(
            skir.LinkControl(
              control: _generatedControl(reference),
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
    skir.BindingRef reference,
  ) => switch (kind) {
    skir.ScalarKind.boolean => skir.PresentationElement.wrapToggleInput(
      _generatedControl(reference),
    ),
    skir.ScalarKind.text => skir.PresentationElement.wrapTextInput(
      skir.TextControl(
        control: _generatedControl(reference),
        multiline: null,
        placeholder: null,
        inputFormatters: const [],
      ),
    ),
    skir.ScalarKind_integerWrapper() ||
    skir.ScalarKind_floatWrapper() ||
    skir.ScalarKind.decimal => skir.PresentationElement.wrapNumericInput(
      _generatedControl(reference),
    ),
    skir.ScalarKind.timestamp => skir.PresentationElement.wrapDateTimeInput(
      skir.DateTimeControl(
        control: _generatedControl(reference),
        includeDate: true,
        includeTime: true,
      ),
    ),
    skir.ScalarKind.duration => skir.PresentationElement.wrapDurationInput(
      _generatedControl(reference),
    ),
    skir.ScalarKind.bytes => skir.PresentationElement.wrapBytesInput(
      _generatedControl(reference),
    ),
    _ => null,
  };

  skir.BoundControl _generatedControl(skir.BindingRef reference) =>
      skir.BoundControl(
        binding: reference,
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      );
}
