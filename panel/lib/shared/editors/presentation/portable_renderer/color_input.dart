part of "../portable_presentation_renderer.dart";

/// The color control.
extension _PortableColorInputRendering on PortablePresentationNodeRenderer {
  Widget _renderColorInput(
    BuildContext context,
    skir.ColorControl input,
    PortablePresentationScope scope,
  ) {
    final payload = scope.read(input.control.binding)?.authoredPayload;
    final color = payload?.asColorOrNull;
    if (payload == null ||
        color == null && payload != skir.DataValue.unfilled) {
      return _diagnostic("The color binding is unavailable");
    }
    final options = input.options;
    ColorFieldFormat format(Object? value) => switch (value) {
      final value
          when value == skir.ColorEditingRepresentation.rgb ||
              value == skir.ColorPickerFormat.rgb =>
        ColorFieldFormat.rgb,
      final value
          when value == skir.ColorEditingRepresentation.hsl ||
              value == skir.ColorPickerFormat.hsl =>
        ColorFieldFormat.hsl,
      _ => ColorFieldFormat.hex,
    };
    final editingFormat = format(options?.editingRepresentation);
    String encode(Color value) => value.toEditorColorText(
      format: editingFormat,
      includeAlpha: input.includeAlpha,
    );
    final swatches = options?.offeredSwatches == null
        ? null
        : scope.evaluate(options!.offeredSwatches!);
    final offered = switch (swatches) {
      PortableExpressionAvailable(
        value: skir.DataValue_listValueWrapper(:final value) ||
            skir.DataValue_setValueWrapper(:final value),
      ) =>
        [for (final item in value.items) item.value.asColorOrNull?.argbValue],
      null => <int?>[],
      _ => throw const FormatException(
        "Offered colors must produce a sequence",
      ),
    };
    if (offered.any((color) => color == null)) {
      return _diagnostic("An offered color is invalid");
    }
    return _controlFrame(
      input.control,
      input.appearance == null
          ? scope
          : scope.withAppearance(input.appearance!),
      _PortableEntryEditing(
        key: ValueKey((
          node.nodeId,
          scope.nativeSourceIdentity(input.control.binding),
          scope.diagnosticTarget(input.control.binding),
        )),
        scope: scope,
        control: input.control,
        mappings: input.mappings,
        validate: (value) => value.asColorOrNull == null
            ? "The completion color must be unsigned ARGB32"
            : null,
        parse: (text) => text.isEmpty
            ? skir.DataValue.unfilled
            : parseEditorColorText(
                text,
                format: editingFormat,
                includeAlpha: input.includeAlpha,
              ).asValue,
        builder: (context, write, complete, mutate) =>
            _PortableControlInteraction(
              scope: scope,
              builder: (context, states, reportInvalid) {
                final style = _controlStyle(context, scope, input.appearance);
                final popup = input.popup;
                final constraints = _popupConstraints(scope, input.popup);
                final leading = _entryLeading(
                  context,
                  input.control,
                  input.content,
                  scope,
                  style,
                  Icons.palette,
                );
                final leadingNode = switch (input.content?.leading) {
                  skir.InputAdornment_contentWrapper(:final value) => value,
                  _ => scope.associationFor(input.control).prefix?.node,
                };
                final externalLeading = _interactiveAdornment(leadingNode);
                final suffix = _entrySuffix(input.content, scope);
                final externalSuffix = _interactiveAdornment(
                  input.content?.suffix,
                );
                final field = ColorPickerField(
                  showDefaultIcon:
                      !externalLeading &&
                      input.content?.leading != skir.InputAdornment.none,
                  key: ValueKey("${node.nodeId}.input"),
                  color: color,
                  includeAlpha: input.includeAlpha,
                  editingFormat: editingFormat,
                  pickerFormat: options?.pickerFormat == null
                      ? null
                      : format(options!.pickerFormat),
                  showSwatch: options?.showSwatch ?? true,
                  showFormatSelector: options?.showFormatSelector ?? true,
                  showCopyAction: options?.showCopyAction ?? true,
                  offeredSwatches: offered.cast<int>(),
                  enabled: scope.enabled,
                  readOnly: scope.readOnly,
                  statesController: states,
                  selectAllOnFocus: input.entry?.selectAllOnFocus ?? false,
                  style: style.valueStyle,
                  textAlign: style.alignment,
                  decoration: style.decoration.copyWith(
                    hintText: _entryPlaceholder(input.content, scope),
                    prefixIcon: externalLeading
                        ? null
                        : (input.content?.leading == null ||
                                  input.content?.leading ==
                                      skir.InputAdornment.default_) &&
                              scope
                                      .associationFor(input.control)
                                      .prefix
                                      ?.node ==
                                  null
                        ? null
                        : leading,
                    suffixIcon: externalSuffix ? null : suffix,
                  ),
                  display: (value) =>
                      _mappedDisplay(
                        scope,
                        input.mappings,
                        value.asValue,
                        reference: input.control.binding,
                      ) ??
                      encode(value),
                  onChanged: (value) => write(value.asValue),
                  onCleared: () => write(skir.DataValue.unfilled),
                  onCommittedDone: complete,
                  onPickerCommitted: (value) =>
                      complete(TextEditingValue(text: encode(value))),
                  popupPadding: popup?.padding == null
                      ? null
                      : _presentationInsets(popup!.padding),
                  popupColor: popup?.fill == null
                      ? null
                      : PresentationValueEnvironment.of(context)
                            .resolve(popup!.fill!, scope),
                  popupShape: _popupShape(context, scope, popup),
                  popupConstraints: constraints,
                  overlayConfig: constraints == null
                      ? null
                      : AnchoredOverlayConfig(
                          preferredSide: AnchoredOverlaySide.bottom,
                          spacing: 6,
                          sharedAxisConstraintMode:
                              SharedAxisConstraintMode.none,
                          maxWidth: constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : constraints.constrainWidth(340),
                          maxHeight: constraints.maxHeight.isFinite
                              ? constraints.maxHeight
                              : 620,
                        ),
                );
                return _entryComposition(
                  child: field,
                  leading: externalLeading ? leading : null,
                  trailing: externalSuffix ? suffix : null,
                );
              },
            ),
      ),
    );
  }
}
