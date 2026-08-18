part of "editor_presentation_encoder.dart";

extension on SkirPresentationEncoder {
  TypeResult<wire.PresentationHeader> _header(PresentationHeader value) {
    final binding = value.binding == null
        ? const TypeResult<wire_binding.BindingRef?>.success(null)
        : expressions.binding(value.binding!).mapValue((value) => value);
    final title = value.title == null
        ? const TypeResult<wire.PresentationHeaderTitle?>.success(null)
        : _headerTitle(value.title!).mapValue((value) => value);
    final description = _optional(value.description);
    final encodedItems = <wire.HeaderItem>[];
    final diagnostics = [
      ...binding.diagnostics,
      ...title.diagnostics,
      ...description.diagnostics,
    ];
    for (final item in value.items) {
      final encoded = _headerItem(item);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final item?) encodedItems.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationHeader(
              binding: binding.valueOrNull,
              title: title.valueOrNull,
              description: description.valueOrNull,
              initiallyExpanded: value.initiallyExpanded,
              items: encodedItems,
              headerPadding: value.headerPadding?._encode,
              contentPadding: value.contentPadding?._encode,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationHeaderTitle> _headerTitle(
    PresentationHeaderTitle value,
  ) => switch (value) {
    PresentationHeaderTextTitle(:final value) =>
      expressions.encode(value).mapValue(wire.PresentationHeaderTitle.wrapText),
    PresentationHeaderNodeTitle(:final node) => encodeNode(
      node,
    ).mapValue(wire.PresentationHeaderTitle.wrapPresentation),
  };

  TypeResult<wire.HeaderItem> _headerItem(HeaderItem value) => switch (value) {
    final HeaderButtonItem item => item._encode(this),
    final HeaderBooleanToggleItem item => item._encode(this),
    final HeaderReorderHandleItem item => item._encode(this),
  };
}

extension on PresentationInsets {
  wire.PresentationInsets get _encode => switch (this) {
    PresentationInsetsAll(:final value) => wire.PresentationInsets.wrapAll(
      value,
    ),
    PresentationInsetsSymmetric(:final horizontal, :final vertical) =>
      wire.PresentationInsets.createSymmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
    PresentationInsetsOnly(
      :final top,
      :final left,
      :final right,
      :final bottom,
    ) =>
      wire.PresentationInsets.createOnly(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
      ),
  };
}

extension on HeaderButtonItem {
  TypeResult<wire.HeaderItem> _encode(SkirPresentationEncoder encoder) {
    final icon = encoder.expressions.encode(this.icon);
    final label = encoder.expressions.encode(this.label);
    final tooltip = encoder._optional(this.tooltip);
    final action = encoder.actions.encode(this.action);
    final priority = encoder._optional(this.priority);
    final visible = encoder._optional(visibleIf);
    final enabled = encoder._optional(enabledIf);
    final confirmation = this.confirmation?._encode(encoder);
    final diagnostics = [
      ...icon.diagnostics,
      ...label.diagnostics,
      ...tooltip.diagnostics,
      ...action.diagnostics,
      ...priority.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...?confirmation?.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.HeaderItem.createButton(
              itemId: id._encode,
              icon: icon.valueOrNull!,
              label: label.valueOrNull!,
              tooltip: tooltip.valueOrNull,
              action: action.valueOrNull!,
              priority: priority.valueOrNull,
              visibleIf: visible.valueOrNull,
              enabledIf: enabled.valueOrNull,
              tone: tone == HeaderActionTone.destructive
                  ? wire.HeaderActionTone.destructive
                  : wire.HeaderActionTone.neutral,
              confirmation: confirmation?.valueOrNull,
              placement: placement._encode,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on HeaderBooleanToggleItem {
  TypeResult<wire.HeaderItem> _encode(SkirPresentationEncoder encoder) {
    final label = encoder.expressions.encode(this.label);
    final checked = encoder.expressions.encode(this.checked);
    final action = encoder.actions.encode(this.action);
    final tooltip = encoder._optional(this.tooltip);
    final priority = encoder._optional(this.priority);
    final visible = encoder._optional(visibleIf);
    final enabled = encoder._optional(enabledIf);
    final confirmation = this.confirmation?._encode(encoder);
    final diagnostics = [
      ...label.diagnostics,
      ...checked.diagnostics,
      ...action.diagnostics,
      ...tooltip.diagnostics,
      ...priority.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
      ...?confirmation?.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.HeaderItem.createBooleanToggle(
              itemId: id._encode,
              label: label.valueOrNull!,
              checked: checked.valueOrNull!,
              action: action.valueOrNull!,
              tooltip: tooltip.valueOrNull,
              priority: priority.valueOrNull,
              visibleIf: visible.valueOrNull,
              enabledIf: enabled.valueOrNull,
              confirmation: confirmation?.valueOrNull,
              placement: placement._encode,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on HeaderReorderHandleItem {
  TypeResult<wire.HeaderItem> _encode(SkirPresentationEncoder encoder) {
    final label = encoder.expressions.encode(this.label);
    final source = encoder.expressions.binding(this.source);
    final tooltip = encoder._optional(this.tooltip);
    final visible = encoder._optional(visibleIf);
    final enabled = encoder._optional(enabledIf);
    final diagnostics = [
      ...label.diagnostics,
      ...source.diagnostics,
      ...tooltip.diagnostics,
      ...visible.diagnostics,
      ...enabled.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.HeaderItem.createReorderHandle(
              itemId: id._encode,
              label: label.valueOrNull!,
              source: source.valueOrNull!,
              tooltip: tooltip.valueOrNull,
              visibleIf: visible.valueOrNull,
              enabledIf: enabled.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on HeaderItemId {
  wire.HeaderItemId get _encode =>
      wire.HeaderItemId(namespace: namespace, name: name);
}

extension on HeaderActionPlacement {
  wire.HeaderActionPlacement get _encode => switch (this) {
    HeaderActionPlacement.beforeTitle => wire.HeaderActionPlacement.beforeTitle,
    HeaderActionPlacement.afterTitle => wire.HeaderActionPlacement.afterTitle,
    HeaderActionPlacement.end => wire.HeaderActionPlacement.end,
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
