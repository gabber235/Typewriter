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
    final nested = childScope.withConfiguredValue(element.binding);
    if (nested == null) {
      return _diagnostic("The typed field binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: custom, scope: nested);
  }

  Widget _renderScopedBinding(
    skir.ScopedBindingElement element,
    PortablePresentationScope childScope,
  ) {
    final nested = childScope.withBinding(
      element.binding,
      element.scopeBindingId,
    );
    if (nested == null) {
      return _diagnostic("The scoped binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: element.child, scope: nested);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controlFrame(
          control.control,
          childScope,
          OutlinedButton.icon(
            key: ValueKey("${node.nodeId}.type"),
            icon: const Icon(Icons.category_outlined),
            label: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selected == null ? "Choose a type" : choiceLabel(selected),
              ),
            ),
            onPressed:
                childScope.enabled &&
                    !childScope.readOnly &&
                    childScope.authoring != null &&
                    childScope.prepareCreation != null
                ? () async {
                    final chosen = await showAuthoredTypeSearch(
                      context,
                      searchHint: "Search value types",
                      candidates: choices,
                      id: (candidate) => choices.indexOf(candidate).toString(),
                      label: choiceLabel,
                      display: (candidate) => switch (candidate.concreteType) {
                        skir.TypeUse_namedWrapper(:final value) =>
                          childScope.catalog?.typeDisplay(value.definition),
                        _ => null,
                      },
                    );
                    if (chosen == null || !context.mounted) return;
                    await childScope._chooseForm(
                      skir.ChooseFormAction(
                        target: control.control.binding,
                        type: chosen.concreteType,
                      ),
                    );
                  }
                : null,
          ),
        ),
        if (nested != null)
          PortablePresentationNodeRenderer(
            node: selected!.presentation!,
            scope: nested,
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
    final nested = childScope.withConfiguredValue(
      recordControl.control.binding,
    );
    if (nested == null) {
      return _diagnostic("The record control binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: custom, scope: nested);
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
      return SwitchListTile(
        value: false,
        title: _controlText(nullable.control.label, childScope),
        subtitle: const Text("No value"),
        onChanged: null,
      );
    }
    final custom = nullable.valuePresentation;
    final nested = custom == null
        ? null
        : childScope.withConfiguredValue(nullable.control.binding);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: true,
          title: _controlText(nullable.control.label, childScope),
          onChanged: childScope.enabled && !childScope.readOnly
              ? (_) => childScope.write(
                  nullable.control.binding,
                  skir.DataValue.null_,
                )
              : null,
        ),
        if (custom != null && nested != null)
          PortablePresentationNodeRenderer(node: custom, scope: nested),
      ],
    );
  }

  Widget _renderNamed(
    skir.NamedControl control,
    PortablePresentationScope childScope,
  ) => PortableNamedControlHost(
    control: control,
    bindings: childScope.bindings,
    budget: childScope.budget,
    setBinding: childScope.write,
    unavailableBuilder: (context, message) => _diagnostic(message),
    builder: (context, customPresentation, payload) {
      if (customPresentation == null) {
        return _diagnostic("The named control has no payload presentation");
      }
      return PortablePresentationNodeRenderer(
        node: customPresentation,
        scope: childScope.withNamedPayload(payload),
      );
    },
  );
}
