part of "../portable_presentation_renderer.dart";

extension _PortableStructuredInputRendering
    on PortablePresentationNodeRenderer {
  Widget _renderTypedField(
    skir.TypedFieldElement element,
    PortablePresentationScope childScope,
  ) {
    final custom = element.presentation;
    if (custom == null) {
      return _diagnostic("The typed field has no presentation");
    }
    if (childScope.read(element.binding) == null) {
      return _diagnostic("The typed field binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: custom, scope: childScope);
  }

  Widget _renderPolymorphicInput(
    BuildContext context,
    skir.PolymorphicControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.control.binding);
    final actual = current?.authoredActualType;
    final choices = control.concreteTypes.toList(growable: false);
    final selectedIndex = choices.indexWhere((candidate) {
      return switch (candidate.concreteType) {
        skir.TypeUse_namedWrapper(:final value) => value == actual,
        _ => false,
      };
    });
    final selected = selectedIndex < 0 ? null : choices[selectedIndex];
    if (current == null || choices.isEmpty) {
      return _diagnostic("The selected concrete type is unavailable");
    }
    final nested = selected?.presentation == null
        ? null
        : childScope.withConfiguredValue(control.control.binding);
    String choiceLabel(skir.ConcreteTypePresentation candidate) =>
        switch (_string(childScope, candidate.label)) {
          _ResolvedValue(:final value) => value,
          _ =>
            childScope.catalog?.typeUseName(candidate.concreteType) ??
                "Concrete type",
        };
    Future<void> choose(skir.ConcreteTypePresentation candidate) async {
      if (candidate == selected) return;
      await childScope.executeAction(
        skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createChooseForm(
            target: control.control.binding,
            type: candidate.concreteType,
          ),
        ),
      );
    }

    final enabled =
        childScope.enabled &&
        !childScope.readOnly &&
        childScope.canExecuteAction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _collectionSpacing(context, control.appearance),
      children: [
        _controlFrame(
          control.control,
          control.inputAppearance == null
              ? childScope
              : childScope.withAppearance(control.inputAppearance!),
          _actionAppearance(
            childScope,
            skir.ActionAppearance(
              appearance: control.inputAppearance,
              variant: null,
              tooltip: control.content?.operationTooltip,
            ),
            (context, states, buttonStyle, style) => _entryComposition(
              leading: _entryLeading(
                context,
                control.control,
                control.inputContent,
                childScope,
                style,
                null,
              ),
              trailing: _entrySuffix(control.inputContent, childScope),
              child: choices.length >= 2 && choices.length <= 3
                  ? _controlSurface(
                      style,
                      SlidingChoiceControl<int>(
                        key: ValueKey("${node.nodeId}.type"),
                        selected: selectedIndex < 0 ? null : selectedIndex,
                        enabled: enabled,
                        padding: style.padding,
                        backgroundColor: style.decoration.fillColor,
                        children: {
                          for (final (index, candidate) in choices.indexed)
                            index: Text(
                              choiceLabel(candidate),
                              style: style.valueStyle,
                            ),
                        },
                        onSelected: (index) async {
                          if (index != null) await choose(choices[index]);
                        },
                      ),
                    )
                  : OutlinedButton.icon(
                      key: ValueKey("${node.nodeId}.type"),
                      statesController: states,
                      style:
                          _operationButtonStyle(control.content)
                              ?.merge(buttonStyle) ??
                          buttonStyle,
                      icon: _operationGlyph(
                        control.content?.chooseIcon,
                        childScope,
                        const Icon(Icons.category_outlined),
                      ),
                      label: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          selected == null
                              ? _entryPlaceholder(
                                      control.inputContent,
                                      childScope,
                                    ) ??
                                    _operationText(
                                      childScope,
                                      control.content?.chooseLabel,
                                      "Choose a type",
                                    )
                              : choiceLabel(selected),
                        ),
                      ),
                      onPressed: enabled
                          ? () async {
                              final chosen = await showAuthoredTypeSearch(
                                context,
                                searchHint: _operationText(
                                  childScope,
                                  control.searchHint,
                                  "Search value types",
                                ),
                                candidates: choices,
                                id: (candidate) =>
                                    choices.indexOf(candidate).toString(),
                                label: choiceLabel,
                                display: (candidate) =>
                                    switch (candidate.concreteType) {
                                      skir.TypeUse_namedWrapper(:final value) =>
                                        childScope.catalog?.typeDisplay(
                                          value.definition,
                                        ),
                                      _ => null,
                                    },
                              );
                              if (chosen == null || !context.mounted) return;
                              await choose(chosen);
                            }
                          : null,
                    ),
            ),
          ),
        ),
        if (nested != null)
          _configuredCollectionBody(
            selected!.presentation!,
            nested,
            control.appearance,
          ),
      ],
    );
  }

  Widget _renderRecordInput(
    skir.RecordControl recordControl,
    PortablePresentationScope childScope,
  ) {
    final custom = recordControl.fieldPresentation;
    if (custom == null) {
      return _diagnostic("The record control has no field presentation");
    }
    if (childScope.read(recordControl.control.binding) == null) {
      return _diagnostic("The record control binding is unavailable");
    }
    return _controlFrame(
      recordControl.control,
      childScope,
      _configuredCollectionBody(custom, childScope, recordControl.appearance),
      renderPrefix: true,
    );
  }

  Widget _renderNullableInput(
    skir.NullableControl nullable,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(nullable.control.binding);
    if (current == null) {
      return _diagnostic("The nullable control binding is unavailable");
    }
    final isNull = current.authoredPayload == skir.DataValue.null_;
    if (isNull) {
      return _compositeControlContent(
        nullable.control,
        childScope,
        SwitchListTile(
          value: false,
          title: _fieldLabel(nullable.control, childScope),
          subtitle: Text(
            _operationText(childScope, nullable.emptyText, "No value"),
          ),
          onChanged: null,
        ),
      );
    }
    final custom = nullable.valuePresentation;
    return _compositeControlContent(
      nullable.control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: true,
            title: _fieldLabel(nullable.control, childScope),
            subtitle: nullable.clearLabel == null
                ? null
                : Text(
                    _operationText(
                      childScope,
                      nullable.clearLabel,
                      "Clear value",
                    ),
                  ),
            onChanged: childScope.enabled && !childScope.readOnly
                ? (_) => childScope.write(
                    nullable.control.binding,
                    skir.DataValue.null_,
                  )
                : null,
          ),
          if (custom != null)
            PortablePresentationNodeRenderer(node: custom, scope: childScope),
        ],
      ),
    );
  }

  Widget _renderNamed(
    skir.NamedControl control,
    PortablePresentationScope childScope,
  ) => PortableNamedControlHost(
    control: control,
    bindings: childScope.bindings,
    budget: childScope.budget,
    setBinding: childScope.apply,
    unavailableBuilder: (context, message) => _diagnostic(message),
    builder: (context, customPresentation, payload) {
      if (customPresentation == null) {
        return _diagnostic("The named control has no payload presentation");
      }
      return _controlFrame(
        control.control,
        childScope,
        _configuredCollectionBody(
          customPresentation,
          childScope,
          control.appearance,
        ),
        renderPrefix: true,
      );
    },
  );

  Widget _configuredCollectionBody(
    skir.PresentationNode body,
    PortablePresentationScope scope,
    skir.CollectionAppearance? appearance,
  ) {
    if (appearance == null) {
      return PortablePresentationNodeRenderer(node: body, scope: scope);
    }
    return Builder(
      builder: (context) {
        Widget decorate(skir.PresentationNode item, Widget child) =>
            _collectionSurface(
              context,
              appearance,
              scope,
              item,
              Padding(
                padding: appearance.itemPadding == null
                    ? EdgeInsets.zero
                    : _presentationInsets(appearance.itemPadding),
                child: child,
              ),
            );
        final content = body.element;
        if (body.header == null &&
            content is skir.PresentationElement_childrenWrapper) {
          final renderer = PortablePresentationNodeRenderer(
            node: body,
            scope: scope,
          );
          final indexed = scope.authoredIndex == null
              ? scope.withAuthoredLayout(body)
              : scope;
          final enabled = _boolean(
            indexed,
            body.properties.enabledIf,
            fallback: true,
          );
          if (enabled case _ResolvedFailure(:final message)) {
            return _diagnostic(message);
          }
          final available = (enabled as _ResolvedValue<bool>).value;
          final nested = indexed
              .withReadOnly(body.properties.readOnly)
              .withEnabled(available);
          final axis = switch (content.value) {
            skir.ChildrenElement_columnWrapper(:final value) => renderer._axis(
              value,
              nested,
              vertical: true,
              fillAvailableSpace: false,
              spacing: appearance.itemSpacing,
              decorateItem: decorate,
            ),
            skir.ChildrenElement_rowWrapper(:final value) => renderer._axis(
              value,
              nested,
              vertical: false,
              fillAvailableSpace: false,
              spacing: appearance.itemSpacing,
              decorateItem: decorate,
            ),
            _ => null,
          };
          return axis == null
              ? decorate(body, renderer)
              : renderer._renderNode(
                  context,
                  content,
                  nested,
                  available,
                  renderedContent: axis,
                );
        }
        return decorate(
          body,
          PortablePresentationNodeRenderer(node: body, scope: scope),
        );
      },
    );
  }
}
