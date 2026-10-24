part of "../portable_presentation_renderer.dart";

String _displayNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

/// The slider control for bounded numbers.
extension _PortableSliderInputRendering on PortablePresentationNodeRenderer {
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
                final colors = PresentationValueEnvironment.of(context);
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
}
