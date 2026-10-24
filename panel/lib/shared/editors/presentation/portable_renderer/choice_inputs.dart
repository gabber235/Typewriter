part of "../portable_presentation_renderer.dart";

/// Toggle, choice, select and enum controls.
extension _PortableChoiceInputRendering on PortablePresentationNodeRenderer {
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
          final colors = PresentationValueEnvironment.of(context);
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
        (options?.queryBinding == null || options?.customValue == null)) {
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
          final colors = PresentationValueEnvironment.of(context);
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
          // DropdownMenu replaces its component themes when overrides are
          // supplied. Apply authored properties over the panel defaults.
          final dropdownTheme = DropdownMenuTheme.of(context);
          final inputTheme =
              dropdownTheme.inputDecorationTheme ??
              Theme.of(context).inputDecorationTheme;
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
            leadingIcon: externalLeading ? null : leading,
            trailingIcon: externalSuffix ? null : suffix,
            inputDecorationTheme: InputDecorationTheme(
              data: inputTheme.copyWith(
                fillColor: style.decoration.fillColor,
                filled: style.decoration.filled,
                border: style.decoration.border,
                enabledBorder: style.decoration.enabledBorder,
                focusedBorder: style.decoration.focusedBorder,
                disabledBorder: style.decoration.disabledBorder,
                errorBorder: style.decoration.errorBorder,
                focusedErrorBorder: style.decoration.focusedErrorBorder,
                contentPadding: style.padding,
                isDense: style.dense,
                hintStyle: style.decoration.hintStyle,
              ),
            ),
            menuStyle: (dropdownTheme.menuStyle ?? const MenuStyle()).copyWith(
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
                    if (options?.queryBinding == null ||
                        options?.customValue == null) {
                      return;
                    }
                    final result = scope
                        .declare(
                          options!.queryBinding!,
                          skir.DataValue.wrapStringValue(query),
                        )
                        .evaluate(options.customValue!);
                    if (result is PortableExpressionAvailable) {
                      scope.write(control.binding, result.value);
                    }
                  },
          );
          return _entryComposition(
            child: dropdown,
            leading: externalLeading ? leading : null,
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
}
