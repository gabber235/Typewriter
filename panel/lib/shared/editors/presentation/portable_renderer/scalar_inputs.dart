part of "../portable_presentation_renderer.dart";

extension _PortableScalarInputRendering on PortablePresentationNodeRenderer {
  Widget _renderEntry({
    required skir.BoundControl control,
    required PortablePresentationScope scope,
    required String icon,
    required IconData nativeIcon,
    required String name,
    required String Function(skir.DataValue) encode,
    required skir.DataValue Function(String) parse,
    skir.InputAppearance? appearance,
    skir.InputContent? content,
    skir.ValueMappings? mappings,
    skir.TextEntryInteractionOptions? entry,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
    String? Function(skir.DataValue)? validate,
    Widget? trailing,
    Widget Function(
      BuildContext,
      void Function(skir.DataValue? Function(PortablePresentationScope)),
    )?
    trailingBuilder,
  }) {
    final current = scope.read(control.binding)?.authoredPayload;
    if (current == null) return _diagnostic("The $name binding is unavailable");
    return _controlFrame(
      control,
      appearance == null ? scope : scope.withAppearance(appearance),
      _PortableEntryEditing(
        key: ValueKey((
          node.nodeId,
          scope.nativeSourceIdentity(control.binding),
          scope.diagnosticTarget(control.binding),
        )),
        scope: scope,
        control: control,
        mappings: mappings,
        parse: parse,
        validate: validate,
        builder: (context, write, complete, mutate) =>
            _PortableControlInteraction(
              scope: scope,
              builder: (context, states, reportInvalid) {
                final style = _controlStyle(context, scope, appearance);
                final leadingNode = switch (content?.leading) {
                  skir.InputAdornment_contentWrapper(:final value) => value,
                  _ => scope.associationFor(control).prefix?.node,
                };
                final leading = _entryLeading(
                  context,
                  control,
                  content,
                  scope,
                  style,
                  nativeIcon,
                );
                final suffix = _entrySuffix(content, scope);
                final externalLeading = _interactiveAdornment(leadingNode);
                final externalSuffix = _interactiveAdornment(content?.suffix);
                final diagnostics = PortableControlDiagnostics.of(context);
                final outsideTrailing = <Widget>[
                  ?trailingBuilder?.call(context, mutate),
                  ?trailing,
                  if (externalSuffix) ?suffix,
                ];
                return _entryComposition(
                  leading: externalLeading ? leading : null,
                  trailing: outsideTrailing.isEmpty
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: outsideTrailing,
                        ),
                  child: _semanticInput(
                    control,
                    scope,
                    ValidatedTextField<skir.DataValue>(
                      showDefaultIcon: false,
                      key: ValueKey("${node.nodeId}.input"),
                      value: current == skir.DataValue.unfilled
                          ? null
                          : current,
                      name: name,
                      icon: icon,
                      enabled: scope.enabled,
                      readOnly: scope.readOnly,
                      selectAllOnFocus: entry?.selectAllOnFocus ?? false,
                      statesController: states,
                      keyboardType: keyboardType,
                      inputFormatters: formatters,
                      style: style.valueStyle,
                      textAlign: style.alignment,
                      decoration: style.decoration.copyWith(
                        hintText:
                            _entryPlaceholder(content, scope) ??
                            "Enter a $name",
                        helperText: current == skir.DataValue.unfilled
                            ? "This value is Unfilled"
                            : null,
                        prefixIcon: externalLeading ? null : leading,
                        suffixIcon: externalSuffix ? null : suffix,
                      ),
                      deserialize: encode,
                      serialize: parse,
                      validator: validate,
                      display: (value) =>
                          _mappedDisplay(
                            scope,
                            mappings,
                            value,
                            reference: control.binding,
                          ) ??
                          encode(value),
                      onChanged: write,
                      onCommittedDone: complete,
                      showValidationMessage: false,
                      validationIdentity: diagnostics.identity,
                      onValidationChanged: (message) {
                        diagnostics.onValidationChanged(message);
                        reportInvalid(message);
                      },
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _renderTextInput(
    skir.TextControl input,
    PortablePresentationScope scope,
  ) {
    final current = scope.read(input.control.binding)?.authoredPayload;
    if (current != skir.DataValue.unfilled &&
        current is! skir.DataValue_stringValueWrapper) {
      return _diagnostic("The text control binding is unavailable");
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
        parse: skir.DataValue.wrapStringValue,
        builder: (context, write, complete, mutate) =>
            _PortableControlInteraction(
              scope: scope,
              builder: (context, states, reportInvalid) {
                final style = _controlStyle(context, scope, input.appearance);
                final options = input.options;
                final lines = switch (options.lines) {
                  skir.TextLines_multipleWrapper(:final value) => value,
                  _ => null,
                };
                final multiple = lines != null;
                final leadingNode = switch (input.content?.leading) {
                  skir.InputAdornment_contentWrapper(:final value) => value,
                  _ => scope.associationFor(input.control).prefix?.node,
                };
                final leading = _entryLeading(
                  context,
                  input.control,
                  input.content,
                  scope,
                  style,
                  Icons.edit_outlined,
                );
                final suffix = _entrySuffix(input.content, scope);
                final outsideLeading = _interactiveAdornment(leadingNode);
                final outsideSuffix = _interactiveAdornment(
                  input.content?.suffix,
                );
                return _entryComposition(
                  leading: outsideLeading ? leading : null,
                  trailing: outsideSuffix ? suffix : null,
                  child: _semanticInput(
                    input.control,
                    scope,
                    EditorTextField(
                      key: ValueKey("${node.nodeId}.input"),
                      text: current is skir.DataValue_stringValueWrapper
                          ? current.value
                          : "",
                      displayText: current == null
                          ? null
                          : _mappedDisplay(
                              scope,
                              input.mappings,
                              current,
                              reference: input.control.binding,
                            ),
                      readOnly: scope.readOnly,
                      enabled: scope.enabled,
                      statesController: states,
                      singleLine: !multiple,
                      minLines: lines?.minimum ?? (multiple ? 3 : 1),
                      maxLines: lines?.maximum ?? (multiple ? null : 1),
                      keyboardType: switch (options.purpose) {
                        skir.TextPurpose.email => TextInputType.emailAddress,
                        skir.TextPurpose.url => TextInputType.url,
                        _ =>
                          multiple
                              ? TextInputType.multiline
                              : TextInputType.text,
                      },
                      obscureText: options.purpose == skir.TextPurpose.password,
                      textCapitalization: switch (options.capitalization) {
                        skir.TextCapitalization.words =>
                          TextCapitalization.words,
                        skir.TextCapitalization.sentences =>
                          TextCapitalization.sentences,
                        skir.TextCapitalization.characters =>
                          TextCapitalization.characters,
                        _ => TextCapitalization.none,
                      },
                      enableSuggestions:
                          options.suggestions ??
                          options.purpose != skir.TextPurpose.password,
                      maxLength: options.length?.maximumGraphemes,
                      maxLengthEnforcement: options.length == null
                          ? null
                          : options.length!.enforceAfterComposition
                          ? MaxLengthEnforcement.truncateAfterCompositionEnds
                          : MaxLengthEnforcement.enforced,
                      inputFormatters: [
                        for (final filter in options.characterFilters)
                          switch (filter) {
                            skir.CharacterFilter_allowWrapper(:final value) =>
                              FilteringTextInputFormatter.allow(RegExp(value)),
                            skir.CharacterFilter_denyWrapper(:final value) =>
                              FilteringTextInputFormatter.deny(RegExp(value)),
                            _ => throw const FormatException(
                              "The text filter is unavailable",
                            ),
                          },
                      ],
                      style: style.valueStyle,
                      textAlign: style.alignment,
                      decoration: style.decoration.copyWith(
                        hintText:
                            _entryPlaceholder(input.content, scope) ??
                            "Enter text",
                        suffixIcon: outsideSuffix ? null : suffix,
                      ),
                      prefix: outsideLeading ? null : leading,
                      selectAllOnFocus: input.entry?.selectAllOnFocus ?? false,
                      onChanged: (text) =>
                          write(skir.DataValue.wrapStringValue(text)),
                      onCommittedDone: complete,
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _renderNumericInput(
    skir.NumericControl input,
    PortablePresentationScope scope,
  ) {
    final current = scope.read(input.control.binding)?.authoredPayload;
    final expected = scope.expectedPayloadType(input.control.binding);
    if (current == null ||
        portableNumericInputText(current: current, expected: expected) ==
            null) {
      return _diagnostic("The numeric binding is unavailable");
    }
    final localeExpression = input.options.editingLocale;
    final locale = localeExpression == null
        ? null
        : switch (_string(scope, localeExpression)) {
            _ResolvedValue(:final value) => value,
            _ResolvedFailure(:final message) => throw PresentationValueFailure(
              message,
            ),
          };
    if (locale != null &&
        Intl.verifiedLocale(
              locale,
              NumberFormat.localeExists,
              onFailure: (_) => null,
            ) ==
            null) {
      throw const PresentationValueFailure(
        "The numeric editing locale is unavailable",
      );
    }
    final symbols = locale == null
        ? null
        : NumberFormat.decimalPattern(locale).symbols;
    String normalize(String text) {
      if (symbols == null) return text;
      final zero = symbols.ZERO_DIGIT.runes.single;
      final digits = String.fromCharCodes(
        text.runes.map(
          (rune) => rune >= zero && rune < zero + 10 ? rune - zero + 48 : rune,
        ),
      );
      return digits
          .replaceAll(symbols.GROUP_SEP, "")
          .replaceAll(symbols.DECIMAL_SEP, ".")
          .replaceAll(symbols.MINUS_SIGN, "-");
    }

    skir.DataValue parse(String text) {
      final normalized = normalize(text);
      if (normalized.isEmpty) return skir.DataValue.unfilled;
      return admitPortableNumericInput(
            current: current,
            expected: expected,
            text: normalized,
          ) ??
          (throw const FormatException("Enter a valid number"));
    }

    skir.DataValue? option(
      skir.ExpressionNode? expression, [
      PortablePresentationScope? evaluation,
    ]) {
      if (expression == null) return null;
      return switch ((evaluation ?? scope).evaluate(expression)) {
        PortableExpressionAvailable(:final value)
            when value is skir.DataValue_integerWrapper ||
                value is skir.DataValue_floatWrapper ||
                value is skir.DataValue_decimalWrapper =>
          value,
        _ => throw const PresentationValueFailure(
          "Numeric options must produce an available numeric value",
        ),
      };
    }

    final minimum = option(input.options.minimum);
    final maximum = option(input.options.maximum);
    final configuredStep = option(input.options.step);
    if (minimum != null &&
        maximum != null &&
        (comparePortableNumericValues(minimum, maximum) ?? 1) > 0) {
      return _diagnostic("Numeric minimum exceeds maximum");
    }
    if (configuredStep != null &&
        (comparePortableNumericValues(
                  configuredStep,
                  skir.DataValue.wrapInteger("0"),
                ) ??
                0) <=
            0) {
      return _diagnostic("The numeric step must be positive");
    }
    return _renderEntry(
      control: input.control,
      scope: scope,
      icon: HeroiconsSolid.hashtag,
      nativeIcon: Icons.numbers,
      name: "number",
      appearance: input.appearance,
      content: input.content,
      mappings: input.mappings,
      entry: input.entry,
      encode: (value) =>
          (portableNumericInputText(current: value, expected: expected) ?? "")
              .replaceAll(".", symbols?.DECIMAL_SEP ?? "."),
      parse: parse,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      validate: (value) {
        if (minimum != null &&
            (comparePortableNumericValues(value, minimum) ?? 0) < 0) {
          return "The number is below the minimum";
        }
        if (maximum != null &&
            (comparePortableNumericValues(value, maximum) ?? 0) > 0) {
          return "The number exceeds the maximum";
        }
        return null;
      },
      trailingBuilder: input.options.steppers == skir.NumericSteppers.inline
          ? (context, mutate) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final direction in [-1, 1])
                  IconButton(
                    tooltip: direction < 0 ? "Decrease" : "Increase",
                    onPressed: scope.enabled && !scope.readOnly
                        ? () => mutate((fresh) {
                            final value = fresh
                                .read(input.control.binding)
                                ?.authoredPayload;
                            if (value == null) return null;
                            final step = input.options.step == null
                                ? switch (value) {
                                    skir.DataValue_floatWrapper() =>
                                      skir.DataValue.wrapFloat(1),
                                    skir.DataValue_decimalWrapper() =>
                                      skir.DataValue.wrapDecimal("1"),
                                    _ => skir.DataValue.wrapInteger("1"),
                                  }
                                : switch (fresh.evaluate(input.options.step!)) {
                                    PortableExpressionAvailable(:final value) =>
                                      value,
                                    _ => null,
                                  };
                            if (step == null ||
                                (comparePortableNumericValues(
                                          step,
                                          skir.DataValue.wrapInteger("0"),
                                        ) ??
                                        0) <=
                                    0) {
                              return null;
                            }
                            final minimum = option(
                              input.options.minimum,
                              fresh,
                            );
                            final maximum = option(
                              input.options.maximum,
                              fresh,
                            );
                            final replacement = stepPortableNumericValue(
                              current: value,
                              step: step,
                              expected: expected,
                              direction: direction,
                            );
                            if (replacement == null ||
                                minimum != null &&
                                    (comparePortableNumericValues(
                                              replacement,
                                              minimum,
                                            ) ??
                                            -1) <
                                        0 ||
                                maximum != null &&
                                    (comparePortableNumericValues(
                                              replacement,
                                              maximum,
                                            ) ??
                                            1) >
                                        0) {
                              return null;
                            }
                            return replacement;
                          })
                        : null,
                    icon: Icon(direction < 0 ? Icons.remove : Icons.add),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _renderBytesInput(
    skir.BytesControl input,
    PortablePresentationScope scope,
  ) {
    final options = input.options;
    final isBase64 =
        options?.editingEncoding == skir.BytesEditingEncoding.base64;
    final groupSize = options?.groupSize;
    if (groupSize != null && groupSize <= 0) {
      return _diagnostic("Byte grouping must be positive");
    }
    String encode(skir.DataValue value) {
      if (value is! skir.DataValue_bytesWrapper) return "";
      final encoded = isBase64
          ? value.value.toBase64()
          : value.value.toBase16();
      if (groupSize == null) return encoded;
      final width = isBase64 ? groupSize : groupSize * 2;
      return [
        for (var offset = 0; offset < encoded.length; offset += width)
          encoded.substring(offset, (offset + width).clamp(0, encoded.length)),
      ].join(" ");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _renderEntry(
          control: input.control,
          scope: scope,
          icon: Ic.round_data_object,
          nativeIcon: Icons.data_object,
          name: "bytes",
          appearance: input.appearance,
          content: input.content,
          mappings: input.mappings,
          entry: input.entry,
          encode: encode,
          parse: (text) {
            final raw = text.replaceAll(RegExp(r"\s"), "");
            if (raw.isEmpty) return skir.DataValue.unfilled;
            try {
              return skir.DataValue.wrapBytes(
                isBase64
                    ? skir.ByteString.fromBase64(raw)
                    : skir.ByteString.fromBase16(raw),
              );
            } on Object {
              throw FormatException(
                isBase64
                    ? "Enter valid Base64 bytes"
                    : "Enter complete hexadecimal bytes",
              );
            }
          },
        ),
        if (options?.showCount == true)
          Text(switch (scope.read(input.control.binding)?.authoredPayload) {
            skir.DataValue_bytesWrapper(:final value) =>
              "${value.length} bytes",
            _ => "No byte value",
          }),
        if (scope.read(input.control.binding)?.authoredPayload ==
            skir.DataValue.unfilled)
          TextButton(
            onPressed: scope.enabled && !scope.readOnly
                ? () => scope.writePayload(
                    input.control.binding,
                    skir.DataValue.wrapBytes(skir.ByteString.empty),
                  )
                : null,
            child: const Text("Use empty bytes"),
          ),
      ],
    );
  }
}
