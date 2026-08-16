part of "editor_presentation_codec.dart";

extension on SkirPresentationDecoder {
  PresentationHeader _header(wire.PresentationHeader value) {
    final binding = value.binding == null
        ? const TypeResult<BindingReference?>.success(null)
        : expressions.binding(value.binding!).mapValue((value) => value);
    final title = value.title == null
        ? const TypeResult<PresentationHeaderTitle?>.success(null)
        : _headerTitle(value.title!).mapValue((value) => value);
    final description = _optionalExpression(value.description);
    return PresentationHeader(
      binding: binding.valueOrNull,
      title: title.valueOrNull,
      description: description.valueOrNull,
      initiallyExpanded: value.initiallyExpanded,
      items: [for (final item in value.items) _headerItem(item)],
    );
  }

  TypeResult<PresentationHeaderTitle> _headerTitle(
    wire.PresentationHeaderTitle value,
  ) => switch (value) {
    wire.PresentationHeaderTitle_textWrapper(:final value) =>
      expressions.decode(value).mapValue(PresentationHeaderTitle.text),
    wire.PresentationHeaderTitle_presentationWrapper(:final value) =>
      TypeResult.success(
        PresentationHeaderTitle.presentation(decodeNode(value)),
      ),
    wire.PresentationHeaderTitle_unknown() => invalidWire(
      "Unknown presentation header title",
    ),
  };

  HeaderItem _headerItem(wire.HeaderItem value) => switch (value) {
    wire.HeaderItem_buttonWrapper(:final value) => _buttonItem(value),
    wire.HeaderItem_booleanToggleWrapper(:final value) => _booleanToggleItem(
      value,
    ),
    wire.HeaderItem_reorderHandleWrapper(:final value) => _reorderHandleItem(
      value,
    ),
    wire.HeaderItem_unknown() => [
      wireDiagnostic("Unknown header item"),
    ]._invalidHeaderItem,
  };

  HeaderItem _buttonItem(wire.HeaderButtonItem value) {
    final icon = expressions.decode(value.icon);
    final label = expressions.decode(value.label);
    final tooltip = _optionalExpression(value.tooltip);
    final action = actions.decode(value.action);
    final priority = _optionalExpression(value.priority);
    final visible = _optionalExpression(value.visibleIf);
    final enabled = _optionalExpression(value.enabledIf);
    final confirmation = value.confirmation?._decode(this);
    final diagnostics = [
      ...icon.diagnostics,
      ...label.diagnostics,
      ...tooltip.diagnostics,
      ...action.diagnostics,
      ...priority.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...?confirmation?.diagnostics,
      ...value.itemId._validate,
    ];
    if (diagnostics.isNotEmpty) return diagnostics._invalidHeaderItem;
    return HeaderButtonItem(
      id: value.itemId._decode,
      icon: icon.valueOrNull!,
      label: label.valueOrNull!,
      tooltip: tooltip.valueOrNull,
      action: action.valueOrNull!,
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

  HeaderItem _booleanToggleItem(wire.HeaderBooleanToggleItem value) {
    final label = expressions.decode(value.label);
    final checked = expressions.decode(value.checked);
    final action = actions.decode(value.action);
    final tooltip = _optionalExpression(value.tooltip);
    final priority = _optionalExpression(value.priority);
    final visible = _optionalExpression(value.visibleIf);
    final enabled = _optionalExpression(value.enabledIf);
    final confirmation = value.confirmation?._decode(this);
    final diagnostics = [
      ...label.diagnostics,
      ...checked.diagnostics,
      ...action.diagnostics,
      ...tooltip.diagnostics,
      ...priority.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...?confirmation?.diagnostics,
      ...value.itemId._validate,
    ];
    if (diagnostics.isNotEmpty) return diagnostics._invalidHeaderItem;
    return HeaderBooleanToggleItem(
      id: value.itemId._decode,
      label: label.valueOrNull!,
      checked: checked.valueOrNull!,
      action: action.valueOrNull!,
      tooltip: tooltip.valueOrNull,
      priority: priority.valueOrNull,
      visibleIf: visible.valueOrNull,
      enabledIf: enabled.valueOrNull,
      confirmation: confirmation?.valueOrNull,
      placement: value.placement._decode,
    );
  }

  HeaderItem _reorderHandleItem(wire.HeaderReorderHandleItem value) {
    final label = expressions.decode(value.label);
    final source = expressions.binding(value.source);
    final tooltip = _optionalExpression(value.tooltip);
    final visible = _optionalExpression(value.visibleIf);
    final enabled = _optionalExpression(value.enabledIf);
    final diagnostics = [
      ...label.diagnostics,
      ...source.diagnostics,
      ...tooltip.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...value.itemId._validate,
    ];
    if (diagnostics.isNotEmpty) return diagnostics._invalidHeaderItem;
    return HeaderReorderHandleItem(
      id: value.itemId._decode,
      label: label.valueOrNull!,
      source: source.valueOrNull!,
      tooltip: tooltip.valueOrNull,
      visibleIf: visible.valueOrNull,
      enabledIf: enabled.valueOrNull,
    );
  }
}

extension on wire.HeaderItemId {
  HeaderItemId get _decode => HeaderItemId(namespace: namespace, name: name);

  List<TypeDiagnostic> get _validate => namespace.isEmpty || name.isEmpty
      ? [wireDiagnostic("Header item id is not qualified")]
      : const [];
}

extension on wire.HeaderActionPlacement {
  HeaderActionPlacement get _decode => switch (this) {
    wire.HeaderActionPlacement.beforeTitle => HeaderActionPlacement.beforeTitle,
    wire.HeaderActionPlacement.afterTitle => HeaderActionPlacement.afterTitle,
    wire.HeaderActionPlacement.end ||
    wire.HeaderActionPlacement_unknown() => HeaderActionPlacement.end,
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
  HeaderItem get _invalidHeaderItem {
    final message = map((item) => item.message).join("\n");
    return HeaderButtonItem(
      id: const HeaderItemId(namespace: "wire", name: "invalid"),
      icon: message.asStringLiteral,
      label: "Invalid item".asStringLiteral,
      action: const RealmEditorAction(ReloadRealmAction()),
    );
  }
}
