part of "../portable_presentation_renderer.dart";

String _displayNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

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
            _ResolvedFailure(:final message) => throw PresentationColorFailure(
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
      throw const PresentationColorFailure(
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
        _ => throw const PresentationColorFailure(
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

  Widget _renderToggleInput(
    skir.ToggleControl input,
    PortablePresentationScope scope,
  ) {
    final current = scope.read(input.control.binding)?.authoredPayload;
    if (current != skir.DataValue.unfilled &&
        current is! skir.DataValue_booleanWrapper) {
      return _diagnostic("The toggle binding is unavailable");
    }
    final selected = current is skir.DataValue_booleanWrapper
        ? current.value
        : null;
    final options = input.options;
    final labels = {
      true: _controlString(options?.trueLabel, scope) ?? "On",
      false: _controlString(options?.falseLabel, scope) ?? "Off",
    };
    return _controlFrame(
      input.control,
      input.appearance == null
          ? scope
          : scope.withAppearance(input.appearance!),
      _PortableControlInteraction(
        scope: scope,
        builder: (context, states, reportInvalid) {
          final style = _controlStyle(context, scope, input.appearance);
          final colors = PresentationColorEnvironment.of(context);
          Color? resolve(skir.PresentationColor? color) =>
              color == null ? null : colors.resolve(color, scope);
          final enabled = scope.enabled && !scope.readOnly;
          final position = options?.position == skir.TogglePosition.leading
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing;
          final title = Text(
            labels[selected] ?? "Choose a value",
            style: style.valueStyle,
            textAlign: style.alignment,
          );
          void change(bool? value) {
            if (value != null) {
              scope.writePayload(
                input.control.binding,
                skir.DataValue.wrapBoolean(value),
              );
            }
          }

          final interactivePrefix = _interactiveAdornment(
            scope.associationFor(input.control).prefix?.node,
          );
          return _controlSurface(
            style,
            _entryComposition(
              leading: interactivePrefix
                  ? scope.associationFor(input.control).prefix!.render(scope)
                  : null,
              child:
                  selected == null &&
                      options?.presentation != skir.TogglePresentation.checkbox
                  ? AdaptiveChoiceControl<bool>(
                      choices: labels,
                      selected: null,
                      enabled: enabled,
                      initialization: SelectionInitializationPolicy.explicit,
                      onSelected: change,
                    )
                  : options?.presentation == skir.TogglePresentation.checkbox
                  ? CheckboxListTile(
                      statesController: states,
                      selected: selected ?? false,
                      value: selected,
                      tristate: selected == null,
                      title: title,
                      dense: style.dense,
                      contentPadding: style.padding,
                      controlAffinity: position,
                      secondary: interactivePrefix
                          ? null
                          : _controlPrefix(input.control, scope),
                      fillColor: options?.trackColor == null
                          ? null
                          : WidgetStateProperty.resolveWith(
                              (states) =>
                                  colors.resolve(options!.trackColor!, scope),
                            ),
                      checkColor: resolve(options?.checkColor),
                      onChanged: enabled ? change : null,
                    )
                  : SwitchListTile(
                      statesController: states,
                      selected: selected!,
                      value: selected,
                      title: title,
                      dense: style.dense,
                      contentPadding: style.padding,
                      controlAffinity: position,
                      secondary: interactivePrefix
                          ? null
                          : _controlPrefix(input.control, scope),
                      thumbColor: options?.thumbColor == null
                          ? null
                          : WidgetStateProperty.resolveWith(
                              (states) =>
                                  colors.resolve(options!.thumbColor!, scope),
                            ),
                      trackColor: options?.trackColor == null
                          ? null
                          : WidgetStateProperty.resolveWith(
                              (states) =>
                                  colors.resolve(options!.trackColor!, scope),
                            ),
                      onChanged: enabled ? change : null,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _renderChoice({
    required skir.BoundControl control,
    required PortablePresentationScope scope,
    required List<({String id, String label, skir.DataValue value})> choices,
    skir.InputAppearance? appearance,
    skir.InputContent? content,
    skir.PopupAppearance? popup,
    skir.SelectInteractionOptions? options,
    bool allowCustom = false,
  }) {
    final current = scope.read(control.binding)?.authoredPayload;
    if (current == null) {
      return _diagnostic("The choice binding is unavailable");
    }
    if (allowCustom &&
        (options?.queryBindingId == null || options?.customValue == null)) {
      return _diagnostic(
        "Custom choice values require a query binding and value expression",
      );
    }
    if (allowCustom &&
        (options?.presentation == skir.ChoicePresentation.segmented ||
            options?.presentation == skir.ChoicePresentation.radio)) {
      return _diagnostic("Custom choice values need an editable dropdown");
    }
    final selected = choices
        .where((choice) => choice.value.authoredPayload == current)
        .firstOrNull
        ?.id;
    return _controlFrame(
      control,
      appearance == null ? scope : scope.withAppearance(appearance),
      _PortableControlInteraction(
        scope: scope,
        builder: (context, states, reportInvalid) {
          final selectedAppearance = options?.selectedTextStyle == null
              ? null
              : (skir.InputAppearance.mutable()
                      ..valueStyle = options!.selectedTextStyle)
                    .toFrozen();
          final style = _controlStyle(
            context,
            appearance == null ? scope : scope.withAppearance(appearance),
            selectedAppearance,
          );
          final enabled = scope.enabled && !scope.readOnly;
          final overrides = options?.optionOverrides;
          bool available(String id) {
            final expression = overrides
                ?.where((option) => option.optionId == id)
                .firstOrNull
                ?.enabledIf;
            return expression == null ||
                switch (_boolean(scope, expression)) {
                  _ResolvedValue(:final value) => value,
                  _ => false,
                };
          }

          Widget label(String id, String fallback) {
            final override = overrides
                ?.where((option) => option.optionId == id)
                .firstOrNull;
            final child = override?.content == null
                ? Text(
                    fallback,
                    style: style.valueStyle,
                    textAlign: style.alignment,
                  )
                : PortablePresentationNodeRenderer(
                    node: override!.content!,
                    scope: scope,
                  );
            final reason = _controlString(override?.disabledReason, scope);
            return reason == null || available(id)
                ? child
                : Tooltip(message: reason, child: child);
          }

          void choose(String? id) {
            final choice = choices
                .where((choice) => choice.id == id)
                .firstOrNull;
            if (choice != null && available(choice.id)) {
              scope.write(control.binding, choice.value);
            }
          }

          final leading = _entryLeading(
            context,
            control,
            content,
            scope,
            style,
            null,
          );
          final suffix = _entrySuffix(content, scope);
          Widget choiceSurface(Widget child) => _controlSurface(
            style,
            _entryComposition(child: child, leading: leading, trailing: suffix),
          );
          final presentation = options?.presentation;
          final segmented =
              presentation == skir.ChoicePresentation.segmented ||
              !allowCustom &&
                  (presentation == null ||
                      presentation == skir.ChoicePresentation.automatic) &&
                  choices.length >= 2 &&
                  choices.length <= 3;
          if (segmented) {
            return choiceSurface(
              SlidingChoiceControl<String>(
                selected: selected,
                enabled: enabled,
                disabled: {
                  for (final choice in choices)
                    if (!available(choice.id)) choice.id,
                },
                padding:
                    style.padding ??
                    EdgeInsets.symmetric(
                      horizontal: context.spacing.space2,
                      vertical: style.dense == false
                          ? context.spacing.space2
                          : context.spacing.space1,
                    ),
                backgroundColor: style.decoration.fillColor,
                children: {
                  for (final choice in choices)
                    choice.id: label(choice.id, choice.label),
                },
                onSelected: choose,
              ),
            );
          }
          if (presentation == skir.ChoicePresentation.radio) {
            return choiceSurface(
              RadioGroup<String>(
                groupValue: selected,
                onChanged: enabled ? choose : (_) {},
                child: Column(
                  children: [
                    for (final choice in choices)
                      RadioListTile<String>(
                        value: choice.id,
                        title: label(choice.id, choice.label),
                        enabled: enabled && available(choice.id),
                        dense: style.dense,
                        contentPadding: style.padding,
                      ),
                  ],
                ),
              ),
            );
          }
          final colors = PresentationColorEnvironment.of(context);
          final menuHeight = _number(scope, options?.maximumMenuHeight);
          if (options?.maximumMenuHeight != null &&
              (menuHeight == null || !menuHeight.isFinite || menuHeight <= 0)) {
            return _diagnostic(
              "Choice menu height must be a positive finite number",
            );
          }
          final popupConstraints = _popupConstraints(scope, popup);
          final shape = _popupShape(context, scope, popup);
          final externalLeading = _interactiveAdornment(
            switch (content?.leading) {
              skir.InputAdornment_contentWrapper(:final value) => value,
              _ => scope.associationFor(control).prefix?.node,
            },
          );
          final externalSuffix = _interactiveAdornment(content?.suffix);
          final dropdownLeading = _entryLeading(
            context,
            control,
            content,
            scope,
            style,
            Icons.arrow_drop_down,
          );
          final dropdown = Dropdown<String>(
            key: ValueKey("${node.nodeId}.input"),
            selected: selected,
            enabled: enabled,
            initialization: SelectionInitializationPolicy.explicit,
            enableFilter: options?.filtering ?? true,
            menuHeight: menuHeight ?? popupConstraints?.maxHeight,
            hintText: _entryPlaceholder(content, scope),
            textStyle: style.valueStyle,
            textAlign: style.alignment,
            leadingIcon: externalLeading ? null : dropdownLeading,
            trailingIcon: externalSuffix ? null : suffix,
            inputDecorationTheme: InputDecorationTheme(
              fillColor: style.decoration.fillColor,
              filled: style.decoration.filled,
              border: style.decoration.border,
              enabledBorder: style.decoration.enabledBorder,
              focusedBorder: style.decoration.focusedBorder,
              disabledBorder: style.decoration.disabledBorder,
              errorBorder: style.decoration.errorBorder,
              contentPadding: style.padding,
              isDense: style.dense ?? false,
              hintStyle: style.decoration.hintStyle,
            ),
            menuStyle: MenuStyle(
              backgroundColor: popup?.fill == null
                  ? null
                  : WidgetStatePropertyAll(colors.resolve(popup!.fill!, scope)),
              shape: shape == null ? null : WidgetStatePropertyAll(shape),
              padding: popup?.padding == null
                  ? null
                  : WidgetStatePropertyAll(_presentationInsets(popup!.padding)),
              minimumSize: popupConstraints == null
                  ? null
                  : WidgetStatePropertyAll(Size(popupConstraints.minWidth, 0)),
              maximumSize: popupConstraints == null
                  ? null
                  : WidgetStatePropertyAll(
                      Size(
                        popupConstraints.maxWidth,
                        popupConstraints.maxHeight,
                      ),
                    ),
            ),
            dropdownMenuEntries: [
              for (final choice in choices)
                DropdownMenuEntry(
                  value: choice.id,
                  label: choice.label,
                  labelWidget: label(choice.id, choice.label),
                  enabled: available(choice.id),
                ),
            ],
            onSelected: choose,
            onCustomValue: !allowCustom
                ? null
                : (query) {
                    if (options?.queryBindingId == null ||
                        options?.customValue == null) {
                      return;
                    }
                    final result = scope
                        .withValues({
                          options!.queryBindingId!:
                              skir.DataValue.wrapStringValue(query),
                        })
                        .evaluate(options.customValue!);
                    if (result is PortableExpressionAvailable) {
                      scope.write(control.binding, result.value);
                    }
                  },
          );
          return _entryComposition(
            child: dropdown,
            leading: externalLeading ? dropdownLeading : null,
            trailing: externalSuffix ? suffix : null,
          );
        },
      ),
    );
  }

  Widget _renderSelectInput(
    skir.SelectControl input,
    PortablePresentationScope scope,
  ) {
    final choices = <({String id, String label, skir.DataValue value})>[];
    for (final option in input.options) {
      final label = _string(scope, option.label);
      final value = scope.evaluate(option.value);
      if (label is _ResolvedValue<String> &&
          value is PortableExpressionAvailable) {
        choices.add((
          id: option.optionId,
          label: label.value,
          value: value.value,
        ));
      }
    }
    final configuredOptions =
        (input.optionsConfig ?? skir.SelectInteractionOptions.defaultInstance)
            .toMutable();
    final authoredOverrides =
        input.optionsConfig?.optionOverrides ??
        const <skir.ChoiceOptionAppearance>[];
    configuredOptions.optionOverrides = [
      for (final option in input.options)
        () {
          final override = authoredOverrides
              .where((item) => item.optionId == option.optionId)
              .firstOrNull;
          return skir.ChoiceOptionAppearance(
            optionId: option.optionId,
            content: override?.content ?? option.content,
            enabledIf: override?.enabledIf ?? option.enabledIf,
            disabledReason: override?.disabledReason ?? option.disabledReason,
          );
        }(),
    ];
    return _renderChoice(
      control: input.control,
      scope: scope,
      choices: choices,
      appearance: input.appearance,
      content: input.content,
      popup: input.popup,
      options: configuredOptions.toFrozen(),
      allowCustom: input.allowCustomValue,
    );
  }

  Widget _renderSliderInput(
    skir.SliderControl slider,
    PortablePresentationScope childScope,
  ) {
    final authored = childScope.read(slider.control.binding);
    final current = authored?.authoredPayload;
    final minimum = _number(childScope, slider.minimum);
    final maximum = _number(childScope, slider.maximum);
    final divisions = _number(childScope, slider.divisions)?.round();
    if (authored == null ||
        minimum == null ||
        maximum == null ||
        !minimum.isFinite ||
        !maximum.isFinite ||
        minimum >= maximum ||
        divisions != null && divisions <= 0 ||
        slider.options?.trackHeight != null &&
            (!slider.options!.trackHeight!.isFinite ||
                slider.options!.trackHeight! <= 0)) {
      return _diagnostic("The slider configuration is unavailable");
    }
    final expected = childScope.expectedPayloadType(slider.control.binding);
    skir.DataValue? replacement(double next) =>
        admitPortableNumericInput(
          current: current,
          expected: expected,
          text: switch (expected) {
            skir.TypeUse_scalarWrapper(
              value: skir.ScalarKind_integerWrapper(),
            ) =>
              next.round().toString(),
            _ => next.toString(),
          },
        ) ??
        (expected == null ? skir.DataValue.wrapFloat(next) : null);
    if (current == skir.DataValue.unfilled) {
      final initial = replacement(minimum);
      if (initial == null) {
        return _diagnostic("The slider configuration is unavailable");
      }
      return _controlFrame(
        slider.control,
        slider.appearance == null
            ? childScope
            : childScope.withAppearance(slider.appearance!),
        _actionAppearance(
          childScope,
          (skir.ActionAppearance.mutable()..appearance = slider.appearance)
              .toFrozen(),
          (context, states, style, resolved) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: ValueKey("${node.nodeId}.input"),
              statesController: states,
              style: style,
              onPressed: childScope.enabled && !childScope.readOnly
                  ? () =>
                        childScope.writePayload(slider.control.binding, initial)
                  : null,
              icon: const Icon(Icons.tune),
              label: Text(
                "Set to ${_displayNumber(minimum)}",
                textAlign: resolved.alignment,
              ),
            ),
          ),
          enabled: childScope.enabled && !childScope.readOnly,
        ),
        renderPrefix: true,
      );
    }
    final value = _dataNumber(current);
    if (value == null) {
      return _diagnostic("The slider control binding is unavailable");
    }
    return _controlFrame(
      slider.control,
      slider.appearance == null
          ? childScope
          : childScope.withAppearance(slider.appearance!),
      _PortableEntryEditing(
        key: ValueKey((
          node.nodeId,
          childScope.nativeSourceIdentity(slider.control.binding),
          childScope.diagnosticTarget(slider.control.binding),
        )),
        scope: childScope,
        control: slider.control,
        mappings: slider.mappings,
        parse: (text) =>
            replacement(double.parse(text)) ??
            (throw const FormatException("Enter a valid slider value")),
        builder: (context, write, complete, mutate) =>
            _PortableControlInteraction(
              scope: childScope,
              builder: (context, states, reportInvalid) {
                final style = _controlStyle(
                  context,
                  childScope,
                  slider.appearance,
                );
                final options = slider.options;
                final colors = PresentationColorEnvironment.of(context);
                Color? resolve(skir.PresentationColor? color) =>
                    color == null ? null : colors.resolve(color, childScope);
                final input = SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: resolve(options?.activeColor),
                    inactiveTrackColor: resolve(options?.inactiveColor),
                    thumbColor: resolve(options?.thumbColor),
                    trackHeight: options?.trackHeight,
                    showValueIndicator:
                        options?.showValue == skir.SliderValueDisplay.always
                        ? ShowValueIndicator.onDrag
                        : options?.showValue == skir.SliderValueDisplay.hidden
                        ? ShowValueIndicator.never
                        : ShowValueIndicator.onDrag,
                    tickMarkShape: options?.showTicks == false
                        ? SliderTickMarkShape.noTickMark
                        : null,
                  ),
                  child: Slider(
                    label:
                        _mappedDisplay(
                          childScope,
                          slider.mappings,
                          current!,
                          reference: slider.control.binding,
                        ) ??
                        _displayNumber(value),
                    allowedInteraction:
                        options?.interaction == skir.SliderInteraction.dragOnly
                        ? SliderInteraction.slideOnly
                        : SliderInteraction.tapAndSlide,
                    value: value.clamp(minimum, maximum),
                    min: minimum,
                    max: maximum,
                    divisions: divisions != null && divisions > 0
                        ? divisions
                        : null,
                    onChangeEnd: (next) =>
                        complete(TextEditingValue(text: next.toString())),
                    onChanged: childScope.enabled && !childScope.readOnly
                        ? (next) {
                            final value = replacement(next);
                            if (value != null) {
                              write(value);
                            }
                          }
                        : null,
                  ),
                );
                return Padding(
                  padding: style.padding ?? EdgeInsets.zero,
                  child: _controlSurface(
                    style,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (options?.showValue ==
                            skir.SliderValueDisplay.always)
                          Text(
                            _mappedDisplay(
                                  childScope,
                                  slider.mappings,
                                  current,
                                  reference: slider.control.binding,
                                ) ??
                                _displayNumber(value),
                            style: style.valueStyle,
                            textAlign: style.alignment,
                          ),
                        if (options?.orientation ==
                            skir.SliderOrientation.vertical)
                          RotatedBox(quarterTurns: 3, child: input)
                        else
                          input,
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      renderPrefix: true,
    );
  }

  Widget _renderDateTimeInput(
    BuildContext context,
    skir.DateTimeControl input,
    PortablePresentationScope scope,
  ) {
    final payload = scope.read(input.control.binding)?.authoredPayload;
    final timestamp = payload is skir.DataValue_timestampWrapper
        ? payload.value
        : null;
    if (payload == null ||
        timestamp == null && payload != skir.DataValue.unfilled) {
      return _diagnostic("The date and time binding is unavailable");
    }
    final date = input.includeDate != false;
    final time = input.includeTime != false;
    if (!date && !time) {
      return _diagnostic("Enable at least one date and time component");
    }
    DateTime? bound(skir.ExpressionNode? expression) => expression == null
        ? null
        : switch (scope.evaluate(expression)) {
            PortableExpressionAvailable(
              value: skir.DataValue_timestampWrapper(:final value),
            ) =>
              value,
            _ => throw const FormatException(
              "Date bounds must produce a timestamp",
            ),
          };
    final minimum = bound(input.options?.minimum);
    final maximum = bound(input.options?.maximum);
    final increment = _durationMilliseconds(
      scope,
      input.options?.timeIncrement,
    );
    if (increment != null && (!time || increment <= 0)) {
      return _diagnostic(
        "The time increment needs a time component and a positive duration",
      );
    }
    String encode(DateTime value) =>
        value.toEditorText(includeDate: date, includeTime: time);
    String? validate(skir.DataValue value) {
      if (value is! skir.DataValue_timestampWrapper) return null;
      if (minimum != null && value.value.isBefore(minimum)) {
        return "The timestamp is below the minimum";
      }
      if (maximum != null && value.value.isAfter(maximum)) {
        return "The timestamp exceeds the maximum";
      }
      return null;
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
        parse: (text) => text.isEmpty
            ? skir.DataValue.unfilled
            : skir.DataValue.wrapTimestamp(
                text.parseEditorDateTime(
                  current: timestamp ?? DateTime.now().toUtc(),
                  includeDate: date,
                  includeTime: time,
                ),
              ),
        validate: validate,
        builder: (context, write, complete, mutate) =>
            _PortableControlInteraction(
              scope: scope,
              builder: (context, states, reportInvalid) {
                final style = _controlStyle(context, scope, input.appearance);
                final popup = input.popup;
                final constraints = _popupConstraints(scope, popup);
                final leading = _entryLeading(
                  context,
                  input.control,
                  input.content,
                  scope,
                  style,
                  date ? Icons.calendar_month : Icons.schedule,
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
                final field = DateTimePickerField(
                  showDefaultIcon: false,
                  key: ValueKey("${node.nodeId}.input"),
                  value: timestamp,
                  includeDate: date,
                  includeTime: time,
                  minimum: minimum,
                  maximum: maximum,
                  timeIncrementMilliseconds: increment,
                  showPicker:
                      input.options?.presentation !=
                      skir.DateTimePickerPresentation.text,
                  enabled: scope.enabled,
                  readOnly: scope.readOnly,
                  statesController: states,
                  selectAllOnFocus: input.entry?.selectAllOnFocus ?? false,
                  style: style.valueStyle,
                  textAlign: style.alignment,
                  decoration: style.decoration.copyWith(
                    hintText: _entryPlaceholder(input.content, scope),
                    prefixIcon: externalLeading ? null : leading,
                    suffixIcon: externalSuffix ? null : suffix,
                  ),
                  display: (value) =>
                      _mappedDisplay(
                        scope,
                        input.mappings,
                        skir.DataValue.wrapTimestamp(value),
                        reference: input.control.binding,
                      ) ??
                      encode(value),
                  validator: (value) =>
                      validate(skir.DataValue.wrapTimestamp(value)),
                  onChanged: (value) {
                    final replacement = skir.DataValue.wrapTimestamp(
                      value.toUtc(),
                    );
                    if (validate(replacement) == null) write(replacement);
                  },
                  onCleared: () => write(skir.DataValue.unfilled),
                  onCommittedDone: complete,
                  onPickerCommitted: (value) =>
                      complete(TextEditingValue(text: encode(value))),
                  popupPadding: popup?.padding == null
                      ? null
                      : _presentationInsets(popup!.padding),
                  popupColor: popup?.fill == null
                      ? null
                      : PresentationColorEnvironment.of(context)
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
                              : constraints.constrainWidth(372),
                          maxHeight: constraints.maxHeight.isFinite
                              ? constraints.maxHeight
                              : 610,
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

  Widget _renderDurationInput(
    skir.DurationControl input,
    PortablePresentationScope scope,
  ) {
    final options = input.options;
    final minimum = _durationMilliseconds(scope, options?.minimum);
    final maximum = _durationMilliseconds(scope, options?.maximum);
    final step = _durationMilliseconds(scope, options?.step);
    if (minimum != null && maximum != null && minimum > maximum ||
        step != null && step <= 0) {
      return _diagnostic(
        "Duration bounds must be ordered and its step must be positive",
      );
    }
    skir.DataValue parse(String text) {
      if (text.trim().isEmpty) return skir.DataValue.unfilled;
      final milliseconds = _parseDurationMilliseconds(text);
      if (!milliseconds.isPortableDurationMilliseconds) {
        throw const FormatException("Duration exceeds the supported range");
      }
      return skir.DataValue.createDuration(
        value: skir.Duration(milliseconds: milliseconds),
      );
    }

    return _renderEntry(
      control: input.control,
      scope: scope,
      icon: Bi.stopwatch_fill,
      nativeIcon: Icons.timer,
      name: "duration",
      appearance: input.appearance,
      content: input.content,
      mappings: input.mappings,
      entry: input.entry,
      encode: (value) => value is skir.DataValue_durationWrapper
          ? _formatDurationMilliseconds(value.value.value.milliseconds)
          : "",
      parse: parse,
      validate: (value) {
        if (value is! skir.DataValue_durationWrapper) return null;
        final ms = value.value.value.milliseconds;
        if (!ms.isPortableDurationMilliseconds) {
          return "Duration exceeds the supported range";
        }
        if (minimum != null && ms < minimum) {
          return "The duration is below the minimum";
        }
        if (maximum != null && ms > maximum) {
          return "The duration exceeds the maximum";
        }
        return null;
      },
      trailingBuilder: options?.step == null
          ? null
          : (context, mutate) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final direction in [-1, 1])
                  IconButton(
                    tooltip: direction < 0
                        ? "Decrease duration"
                        : "Increase duration",
                    onPressed: scope.enabled && !scope.readOnly
                        ? () => mutate((fresh) {
                            final value = fresh
                                .read(input.control.binding)
                                ?.authoredPayload;
                            final step = _durationMilliseconds(
                              fresh,
                              options!.step,
                            );
                            if (value is! skir.DataValue_durationWrapper ||
                                step == null ||
                                step <= 0) {
                              return null;
                            }
                            final nextMilliseconds =
                                BigInt.from(value.value.value.milliseconds) +
                                BigInt.from(direction) * BigInt.from(step);
                            final limit = BigInt.from(
                              PortableDurationMilliseconds.maximum,
                            );
                            if (nextMilliseconds < -limit ||
                                nextMilliseconds > limit) {
                              return null;
                            }
                            final next = nextMilliseconds.toInt();
                            final minimum = _durationMilliseconds(
                              fresh,
                              options.minimum,
                            );
                            final maximum = _durationMilliseconds(
                              fresh,
                              options.maximum,
                            );
                            if (minimum != null && next < minimum ||
                                maximum != null && next > maximum) {
                              return null;
                            }
                            return skir.DataValue.createDuration(
                              value: skir.Duration(milliseconds: next),
                            );
                          })
                        : null,
                    icon: Icon(direction < 0 ? Icons.remove : Icons.add),
                  ),
              ],
            ),
    );
  }

  String _formatDurationMilliseconds(int milliseconds) {
    var remainder = BigInt.from(milliseconds).abs();
    final parts = <String>[];
    const units = {
      "w": 604800000,
      "d": 86400000,
      "h": 3600000,
      "m": 60000,
      "s": 1000,
      "ms": 1,
    };
    for (final unit in units.entries) {
      final divisor = BigInt.from(unit.value);
      final count = remainder ~/ divisor;
      remainder %= divisor;
      if (count != BigInt.zero) parts.add("$count${unit.key}");
    }
    return "${milliseconds < 0 ? "-" : ""}${parts.isEmpty ? "0ms" : parts.join(" ")}";
  }

  int _parseDurationMilliseconds(String text) {
    var input = text.trim();
    final negative = input.startsWith("-");
    if (negative || input.startsWith("+")) input = input.substring(1);
    const units = {
      "w": 604800000000,
      "d": 86400000000,
      "h": 3600000000,
      "m": 60000000,
      "s": 1000000,
      "ms": 1000,
      "us": 1,
    };
    final seen = <String>{};
    var microseconds = BigInt.zero;
    for (final part in input.split(" ")) {
      final match = RegExp(r"^(\d+)(w|d|h|min|m|s|ms|us)$").firstMatch(part);
      if (match == null) throw const FormatException("Invalid duration format");
      final unit = match[2] == "min" ? "m" : match[2]!;
      if (!seen.add(unit)) {
        throw const FormatException("Duration unit specified multiple times");
      }
      microseconds += BigInt.parse(match[1]!) * BigInt.from(units[unit]!);
    }
    if (microseconds.remainder(BigInt.from(1000)) != BigInt.zero) {
      throw const FormatException("Duration must use whole milliseconds");
    }
    var milliseconds = microseconds ~/ BigInt.from(1000);
    if (negative) milliseconds = -milliseconds;
    final maximum = BigInt.from(PortableDurationMilliseconds.maximum);
    if (milliseconds < -maximum || milliseconds > maximum) {
      throw const FormatException("Duration exceeds the supported range");
    }
    return milliseconds.toInt();
  }

  int? _durationMilliseconds(
    PortablePresentationScope scope,
    skir.ExpressionNode? expression,
  ) {
    if (expression == null) return null;
    final milliseconds = switch (scope.evaluate(expression)) {
      PortableExpressionAvailable(
        value: skir.DataValue_durationWrapper(:final value),
      ) =>
        value.value.milliseconds,
      _ => throw const FormatException(
        "The duration option must produce a duration",
      ),
    };
    if (!milliseconds.isPortableDurationMilliseconds) {
      throw const FormatException("Duration exceeds the supported range");
    }
    return milliseconds;
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

  Widget _renderEnumInput(
    skir.EnumControl input,
    PortablePresentationScope childScope,
  ) {
    final control = input.control;
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final selected = switch (payload) {
      skir.DataValue_enumCaseWrapper(:final value) => value,
      _ => null,
    };
    final actual =
        current?.authoredActualType ??
        switch (childScope
            .expectedType(control.binding)
            .withoutNullableWrappers) {
          skir.TypeUse_namedWrapper(:final value) => value,
          _ => null,
        };
    final representation = actual == null
        ? null
        : childScope.catalog
              ?.published(actual.definition)
              ?.definition
              .representation;
    final cases = switch (representation) {
      skir.RepresentationTemplate_enumerationWrapper(:final value) =>
        value.cases.map((variant) => variant.key).toList(growable: false),
      _ => const <String>[],
    };
    if (current == null ||
        (selected == null && payload != skir.DataValue.unfilled) ||
        cases.isEmpty) {
      return _diagnostic("The enumeration binding is unavailable");
    }
    return _renderChoice(
      control: control,
      scope: childScope,
      choices: [
        for (final value in cases)
          (
            id: value,
            label: value,
            value: current is skir.DataValue_namedWrapper
                ? current.preservingNamedIdentity(
                    skir.DataValue.wrapEnumCase(value),
                  )
                : skir.DataValue.wrapEnumCase(value),
          ),
      ],
      appearance: input.appearance,
      content: input.content,
      popup: input.popup,
      options: input.options,
    );
  }

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
                      : PresentationColorEnvironment.of(context)
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
