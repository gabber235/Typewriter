part of "../portable_presentation_renderer.dart";

/// Date time and duration controls.
extension _PortableTemporalInputRendering on PortablePresentationNodeRenderer {
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
}
