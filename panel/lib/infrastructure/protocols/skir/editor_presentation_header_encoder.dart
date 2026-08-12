part of "editor_presentation_encoder.dart";

extension on SkirPresentationEncoder {
  TypeResult<wire.PresentationHeader> _header(PresentationHeader value) {
    final binding = value.binding == null
        ? const TypeResult<wire_binding.BindingRef?>.success(null)
        : expressions.binding(value.binding!).mapValue((value) => value);
    final title = _optional(value.title);
    final description = _optional(value.description);
    final encodedActions = <wire.EditorHeaderAction>[];
    final diagnostics = [
      ...binding.diagnostics,
      ...title.diagnostics,
      ...description.diagnostics,
    ];
    for (final action in value.actions) {
      final encoded = _headerAction(action);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final item?) encodedActions.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationHeader(
              binding: binding.valueOrNull,
              title: title.valueOrNull,
              description: description.valueOrNull,
              initiallyExpanded: value.initiallyExpanded,
              actions: encodedActions,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.EditorHeaderAction> _headerAction(EditorHeaderAction value) {
    final icon = expressions.encode(value.icon);
    final label = expressions.encode(value.label);
    final tooltip = _optional(value.tooltip);
    final priority = _optional(value.priority);
    final visible = _optional(value.visibleIf);
    final enabled = _optional(value.enabledIf);
    final activation = value.activation._encode(this);
    final confirmation = value.confirmation?._encode(this);
    final diagnostics = [
      ...icon.diagnostics,
      ...label.diagnostics,
      ...tooltip.diagnostics,
      ...priority.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...activation.diagnostics,
      ...?confirmation?.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.EditorHeaderAction(
              actionId: wire.HeaderActionId(
                namespace: value.id.namespace,
                name: value.id.name,
              ),
              icon: icon.valueOrNull!,
              label: label.valueOrNull!,
              tooltip: tooltip.valueOrNull,
              activation: activation.valueOrNull!,
              priority: priority.valueOrNull,
              visibleIf: visible.valueOrNull,
              enabledIf: enabled.valueOrNull,
              placement: value.placement._encode,
              tone: value.tone == HeaderActionTone.destructive
                  ? wire.HeaderActionTone.destructive
                  : wire.HeaderActionTone.neutral,
              confirmation: confirmation?.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on HeaderActionPlacement {
  wire.HeaderActionPlacement get _encode => switch (this) {
    HeaderActionPlacement.beforeTitle => wire.HeaderActionPlacement.beforeTitle,
    HeaderActionPlacement.afterTitle => wire.HeaderActionPlacement.afterTitle,
    HeaderActionPlacement.end => wire.HeaderActionPlacement.end,
  };
}

extension on HeaderActionActivation {
  TypeResult<wire.HeaderActionActivation> _encode(
    SkirPresentationEncoder encoder,
  ) => switch (this) {
    InvokeHeaderAction(:final action) =>
      encoder.actions
          .encode(action)
          .mapValue(
            (action) =>
                wire.HeaderActionActivation.createInvoke(action: action),
          ),
    ReorderListItemHeaderAction(:final source) =>
      encoder.expressions
          .binding(source)
          .mapValue(
            (source) => wire.HeaderActionActivation.createReorderListItem(
              source: source,
            ),
          ),
  };
}

extension on HeaderActionConfirmation {
  TypeResult<wire.HeaderActionConfirmation> _encode(
    SkirPresentationEncoder encoder,
  ) {
    final title = encoder.expressions.encode(this.title);
    final message = encoder.expressions.encode(this.message);
    final label = encoder.expressions.encode(confirmationLabel);
    final diagnostics = [
      ...title.diagnostics,
      ...message.diagnostics,
      ...label.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.HeaderActionConfirmation(
              title: title.valueOrNull!,
              message: message.valueOrNull!,
              confirmationLabel: label.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}
