part of "editor_presentation_codec.dart";

extension on SkirPresentationDecoder {
  PresentationHeader _header(wire.PresentationHeader value) {
    final binding = value.binding == null
        ? const TypeResult<BindingReference?>.success(null)
        : expressions.binding(value.binding!).mapValue((value) => value);
    final title = _optionalExpression(value.title);
    final description = _optionalExpression(value.description);
    return PresentationHeader(
      binding: binding.valueOrNull,
      title: title.valueOrNull,
      description: description.valueOrNull,
      initiallyExpanded: value.initiallyExpanded,
      actions: [for (final action in value.actions) _headerAction(action)],
    );
  }

  EditorHeaderAction _headerAction(wire.EditorHeaderAction value) {
    final icon = expressions.decode(value.icon);
    final label = expressions.decode(value.label);
    final tooltip = _optionalExpression(value.tooltip);
    final priority = _optionalExpression(value.priority);
    final visible = _optionalExpression(value.visibleIf);
    final enabled = _optionalExpression(value.enabledIf);
    final activation = value.activation._decode(this);
    final confirmation = value.confirmation?._decode(this);
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
    if (value.actionId.namespace.isEmpty || value.actionId.name.isEmpty) {
      diagnostics.add(wireDiagnostic("Header action id is not qualified"));
    }
    if (diagnostics.isNotEmpty) return diagnostics._invalidHeaderAction;
    return EditorHeaderAction(
      id: HeaderActionId(
        namespace: value.actionId.namespace,
        name: value.actionId.name,
      ),
      icon: icon.valueOrNull!,
      label: label.valueOrNull!,
      tooltip: tooltip.valueOrNull,
      activation: activation.valueOrNull!,
      priority: priority.valueOrNull,
      visibleIf: visible.valueOrNull,
      enabledIf: enabled.valueOrNull,
      placement: value.placement._decode,
      tone: value.tone == wire.HeaderActionTone.destructive
          ? HeaderActionTone.destructive
          : HeaderActionTone.neutral,
      confirmation: confirmation?.valueOrNull,
    );
  }
}

extension on wire.HeaderActionPlacement {
  HeaderActionPlacement get _decode => switch (this) {
    wire.HeaderActionPlacement.beforeTitle => HeaderActionPlacement.beforeTitle,
    wire.HeaderActionPlacement.afterTitle => HeaderActionPlacement.afterTitle,
    wire.HeaderActionPlacement.end ||
    wire.HeaderActionPlacement_unknown() => HeaderActionPlacement.end,
  };
}

extension on wire.HeaderActionActivation {
  TypeResult<HeaderActionActivation> _decode(SkirPresentationDecoder decoder) =>
      switch (this) {
        wire.HeaderActionActivation_invokeWrapper(:final value) =>
          decoder.actions.decode(value.action).mapValue(InvokeHeaderAction.new),
        wire.HeaderActionActivation_reorderListItemWrapper(:final value) =>
          decoder.expressions
              .binding(value.source)
              .mapValue(
                (source) => ReorderListItemHeaderAction(source: source),
              ),
        wire.HeaderActionActivation_unknown() => invalidWire(
          "Unknown header action activation",
        ),
      };
}

extension on wire.HeaderActionConfirmation {
  TypeResult<HeaderActionConfirmation> _decode(
    SkirPresentationDecoder decoder,
  ) {
    final title = decoder.expressions.decode(this.title);
    final message = decoder.expressions.decode(this.message);
    final label = decoder.expressions.decode(confirmationLabel);
    final diagnostics = [
      ...title.diagnostics,
      ...message.diagnostics,
      ...label.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            HeaderActionConfirmation(
              title: title.valueOrNull!,
              message: message.valueOrNull!,
              confirmationLabel: label.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on List<TypeDiagnostic> {
  EditorHeaderAction get _invalidHeaderAction {
    final message = map((item) => item.message).join("\n");
    return EditorHeaderAction(
      id: const HeaderActionId(namespace: "wire", name: "invalid"),
      icon: message.asStringLiteral,
      label: "Invalid action".asStringLiteral,
      activation: const InvokeHeaderAction(
        RealmEditorAction(ReloadRealmAction()),
      ),
    );
  }
}
