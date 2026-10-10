part of "../portable_presentation_renderer.dart";

final _signedInt64Minimum = -(BigInt.one << 63);
final _signedInt64Maximum = (BigInt.one << 63) - BigInt.one;

String _displayNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

extension _PortableScalarInputRendering on PortablePresentationNodeRenderer {
  Widget _renderTextInput(
    skir.TextControl textControl,
    PortablePresentationScope childScope,
  ) {
    final control = textControl.control;
    final currentValue = childScope.read(control.binding);
    final current = switch (currentValue?.authoredPayload) {
      skir.DataValue_stringValueWrapper(:final value) => value,
      final value? when value == skir.DataValue.unfilled => "",
      _ => null,
    };
    if (current == null) {
      return _diagnostic("The text control binding is unavailable");
    }
    final placeholder = textControl.placeholder == null
        ? null
        : switch (_string(childScope, textControl.placeholder!)) {
            _ResolvedValue(:final value) => value,
            _ => null,
          };
    final prefix = control.prefix == null
        ? const Icon(Icons.edit_outlined, size: 18)
        : PortablePresentationNodeRenderer(
            node: control.prefix!,
            scope: childScope,
          );
    final multiline = textControl.multiline == true;
    return _controlFrame(
      control,
      childScope,
      EditorTextField(
        key: ValueKey("${node.nodeId}.input"),
        text: current,
        readOnly: childScope.readOnly,
        enabled: childScope.enabled,
        singleLine: !multiline,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 8 : 1,
        hintText: placeholder ?? "Enter text",
        prefix: prefix,
        onChanged: (next) => childScope.writePayload(
          control.binding,
          skir.DataValue.wrapStringValue(next),
        ),
      ),
    );
  }

  Widget _renderNumericInput(
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding)?.authoredPayload;
    final expected = childScope.expectedPayloadType(control.binding);
    final text = portableNumericInputText(current: current, expected: expected);
    if (current == null || text == null) {
      return _diagnostic("The numeric control binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      ValidatedTextField<skir.DataValue>(
        key: ValueKey("${node.nodeId}.input"),
        value: current == skir.DataValue.unfilled ? null : current,
        name: "number",
        icon: HeroiconsSolid.hashtag,
        readOnly: childScope.readOnly || !childScope.enabled,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            return acceptsPortableNumericInput(
                  current: current,
                  expected: expected,
                  text: newValue.text,
                )
                ? newValue
                : oldValue;
          }),
        ],
        decoration: InputDecoration(
          hintText: "Enter a number",
          helperText: current == skir.DataValue.unfilled
              ? "This value is Unfilled"
              : null,
          prefixIcon: _paddedControlPrefix(control, childScope),
        ),
        deserialize: (_) => text,
        serialize: (next) {
          if (next.isEmpty) {
            return skir.DataValue.unfilled;
          }
          final replacement = admitPortableNumericInput(
            current: current,
            expected: expected,
            text: next,
          );
          if (replacement == null) {
            throw const FormatException("Enter a valid number");
          }
          return replacement;
        },
        onChanged: (replacement) => replacement == skir.DataValue.unfilled
            ? childScope.write(control.binding, skir.DataValue.unfilled)
            : childScope.writePayload(control.binding, replacement),
      ),
    );
  }

  Widget _renderToggleInput(
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding)?.authoredPayload;
    if (current != skir.DataValue.unfilled &&
        current is! skir.DataValue_booleanWrapper) {
      return _diagnostic("The toggle control binding is unavailable");
    }
    final editable = childScope.enabled && !childScope.readOnly;
    final selected = switch (current) {
      skir.DataValue_booleanWrapper(:final value) => value,
      _ => null,
    };
    final input = current == skir.DataValue.unfilled
        ? _withControlPrefix(
            control,
            childScope,
            AdaptiveChoiceControl<bool>(
              key: ValueKey("${node.nodeId}.input"),
              choices: const {true: "On", false: "Off"},
              selected: null,
              enabled: editable,
              initialization: SelectionInitializationPolicy.explicit,
              onSelected: (next) {
                if (next != null) {
                  childScope.writePayload(
                    control.binding,
                    skir.DataValue.wrapBoolean(next),
                  );
                }
              },
            ),
          )
        : SwitchListTile(
            key: ValueKey("${node.nodeId}.input"),
            contentPadding: EdgeInsets.zero,
            value: selected!,
            title: Text(selected ? "On" : "Off"),
            secondary: _controlPrefix(control, childScope),
            onChanged: editable
                ? (next) => childScope.writePayload(
                    control.binding,
                    skir.DataValue.wrapBoolean(next),
                  )
                : null,
          );
    return _controlFrame(control, childScope, input);
  }

  Widget _renderSelectInput(
    skir.SelectControl select,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(select.control.binding)?.authoredPayload;
    if (current == null) {
      return _diagnostic("The select control binding is unavailable");
    }
    final options = <({String id, String label, skir.DataValue value})>[];
    for (final option in select.options) {
      final label = _string(childScope, option.label);
      final value = childScope.evaluate(option.value);
      if (label is _ResolvedValue<String> &&
          value is PortableExpressionAvailable) {
        options.add((
          id: option.optionId,
          label: label.value,
          value: value.value,
        ));
      }
    }
    final selected = options
        .where((option) => option.value.authoredPayload == current)
        .firstOrNull
        ?.id;
    return _controlFrame(
      select.control,
      childScope,
      _withControlPrefix(
        select.control,
        childScope,
        AdaptiveChoiceControl<String>(
          key: ValueKey("${node.nodeId}.input"),
          choices: {for (final option in options) option.id: option.label},
          selected: selected,
          enabled: childScope.enabled && !childScope.readOnly,
          initialization: SelectionInitializationPolicy.explicit,
          onSelected: (id) {
            final option = options.where((item) => item.id == id).firstOrNull;
            if (option != null) {
              childScope.write(select.control.binding, option.value);
            }
          },
        ),
      ),
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
        minimum >= maximum) {
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
        childScope,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: ValueKey("${node.nodeId}.input"),
            onPressed: childScope.enabled && !childScope.readOnly
                ? () => childScope.writePayload(slider.control.binding, initial)
                : null,
            icon: const Icon(Icons.tune),
            label: Text("Set to ${_displayNumber(minimum)}"),
          ),
        ),
      );
    }
    final value = _dataNumber(current);
    if (value == null) {
      return _diagnostic("The slider control binding is unavailable");
    }
    return _controlFrame(
      slider.control,
      childScope,
      Slider(
        value: value.clamp(minimum, maximum),
        min: minimum,
        max: maximum,
        divisions: divisions != null && divisions > 0 ? divisions : null,
        onChanged: childScope.enabled && !childScope.readOnly
            ? (next) {
                final value = replacement(next);
                if (value != null) {
                  childScope.writePayload(slider.control.binding, value);
                }
              }
            : null,
      ),
    );
  }

  Widget _renderDateTimeInput(
    BuildContext context,
    skir.DateTimeControl dateTime,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(dateTime.control.binding);
    final payload = current?.authoredPayload;
    final timestamp = switch (payload) {
      skir.DataValue_timestampWrapper(:final value) => value,
      _ => null,
    };
    if (current == null ||
        (timestamp == null && payload != skir.DataValue.unfilled)) {
      return _diagnostic("The date and time binding is unavailable");
    }
    if (dateTime.includeDate == false && dateTime.includeTime == false) {
      return _diagnostic("The date and time control must enable one part");
    }
    return _controlFrame(
      dateTime.control,
      childScope,
      DateTimePickerField(
        key: ValueKey("${node.nodeId}.input"),
        value: timestamp,
        includeDate: dateTime.includeDate != false,
        includeTime: dateTime.includeTime != false,
        enabled: childScope.enabled,
        readOnly: childScope.readOnly,
        onCleared: () =>
            childScope.write(dateTime.control.binding, skir.DataValue.unfilled),
        onChanged: (next) => childScope.writePayload(
          dateTime.control.binding,
          skir.DataValue.wrapTimestamp(next.toUtc()),
        ),
      ),
    );
  }

  Widget _renderDurationInput(
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final milliseconds = switch (payload) {
      skir.DataValue_durationWrapper(:final value) => value.value.milliseconds,
      _ => null,
    };
    if (current == null ||
        (milliseconds == null && payload != skir.DataValue.unfilled)) {
      return _diagnostic("The duration binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      ValidatedTextField<skir.DataValue>(
        key: ValueKey("${node.nodeId}.input"),
        value: payload == skir.DataValue.unfilled ? null : payload,
        name: "duration",
        icon: Bi.stopwatch_fill,
        readOnly: childScope.readOnly || !childScope.enabled,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu +\-]")),
        ],
        decoration: InputDecoration(
          hintText: "Enter a duration",
          helperText: milliseconds == null ? "This value is Unfilled" : null,
          prefixIcon: _paddedControlPrefix(control, childScope),
        ),
        deserialize: (value) => value == skir.DataValue.unfilled
            ? ""
            : prettyDuration(
                Duration(
                  milliseconds: (value as skir.DataValue_durationWrapper)
                      .value
                      .value
                      .milliseconds,
                ),
                abbreviated: true,
                delimiter: " ",
                spacer: "",
                tersity: DurationTersity.millisecond,
              ),
        serialize: (value) {
          if (value.trim().isEmpty) return skir.DataValue.unfilled;
          final duration = parseDuration(value, separator: " ");
          return skir.DataValue.createDuration(
            value: skir.Duration(milliseconds: duration.inMilliseconds),
          );
        },
        validator: (value) {
          if (value == skir.DataValue.unfilled) return null;
          final encoded = BigInt.from(
            (value as skir.DataValue_durationWrapper).value.value.milliseconds,
          );
          return encoded < _signedInt64Minimum || encoded > _signedInt64Maximum
              ? "Duration exceeds the supported range"
              : null;
        },
        onChanged: (value) => value == skir.DataValue.unfilled
            ? childScope.write(control.binding, value)
            : childScope.writePayload(control.binding, value),
      ),
    );
  }

  Widget _renderBytesInput(
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final bytes = switch (payload) {
      skir.DataValue_bytesWrapper(:final value) => value,
      _ => null,
    };
    if (current == null ||
        (bytes == null && payload != skir.DataValue.unfilled)) {
      return _diagnostic("The bytes binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTextField(
            key: ValueKey("${node.nodeId}.input"),
            text: bytes?.toBase16() ?? "",
            enabled: childScope.enabled,
            readOnly: childScope.readOnly,
            prefix:
                _controlPrefix(control, childScope) ??
                const Icon(Icons.data_object, size: 18),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                return RegExp(r"^[0-9a-fA-F]*$").hasMatch(newValue.text)
                    ? newValue
                    : oldValue;
              }),
            ],
            decoration: InputDecoration(
              helperText: bytes == null
                  ? "This value is Unfilled"
                  : bytes.isEmpty
                  ? "Empty byte sequence"
                  : "Hexadecimal bytes",
              suffixIcon: bytes == null
                  ? null
                  : IconButton(
                      tooltip: "Clear bytes",
                      onPressed: childScope.enabled && !childScope.readOnly
                          ? () => childScope.write(
                              control.binding,
                              skir.DataValue.unfilled,
                            )
                          : null,
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (text) {
              if (text.isEmpty || text.length.isOdd) {
                childScope.write(control.binding, skir.DataValue.unfilled);
                return;
              }
              childScope.writePayload(
                control.binding,
                skir.DataValue.wrapBytes(skir.ByteString.fromBase16(text)),
              );
            },
          ),
          if (bytes == null)
            TextButton.icon(
              onPressed: childScope.enabled && !childScope.readOnly
                  ? () => childScope.writePayload(
                      control.binding,
                      skir.DataValue.wrapBytes(skir.ByteString.empty),
                    )
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Use empty bytes"),
            ),
        ],
      ),
    );
  }

  Widget _renderEnumInput(
    skir.BoundControl control,
    PortablePresentationScope childScope,
  ) {
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
    return _controlFrame(
      control,
      childScope,
      _withControlPrefix(
        control,
        childScope,
        AdaptiveChoiceControl<String>(
          key: ValueKey("${node.nodeId}.input"),
          choices: {for (final value in cases) value: value},
          selected: cases.contains(selected) ? selected : null,
          enabled: childScope.enabled && !childScope.readOnly,
          initialization: SelectionInitializationPolicy.explicit,
          onSelected: (value) {
            if (value != null) {
              childScope.writePayload(
                control.binding,
                skir.DataValue.wrapEnumCase(value),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _renderColorInput(
    BuildContext context,
    skir.ColorControl colorControl,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(colorControl.control.binding);
    final payload = current?.authoredPayload;
    final encoded = payload?.authoredInteger;
    if (current == null ||
        (encoded == null && payload != skir.DataValue.unfilled)) {
      return _diagnostic("The color control binding is unavailable");
    }
    final color = encoded == null
        ? null
        : Color(encoded.toUnsigned(32).toInt());
    final includeAlpha = colorControl.includeAlpha;
    return _controlFrame(
      colorControl.control,
      childScope,
      ColorPickerField(
        key: ValueKey("${node.nodeId}.input"),
        color: color,
        includeAlpha: includeAlpha,
        enabled: childScope.enabled,
        readOnly: childScope.readOnly,
        onCleared: () => childScope.write(
          colorControl.control.binding,
          skir.DataValue.unfilled,
        ),
        onChanged: (next) => childScope.writePayload(
          colorControl.control.binding,
          skir.DataValue.wrapInteger(next.toARGB32().toString()),
        ),
      ),
    );
  }
}
