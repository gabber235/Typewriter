import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ColorFields extends StatelessWidget {
  const ColorFields({
    required this.color,
    required this.format,
    required this.includeAlpha,
    required this.enabled,
    required this.onFormatChanged,
    required this.onChanged,
    super.key,
  });

  final Color color;
  final ColorFieldFormat format;
  final bool includeAlpha;
  final bool enabled;
  final ValueChanged<ColorFieldFormat> onFormatChanged;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      AdaptiveChoiceControl<ColorFieldFormat>(
        selected: format,
        enabled: enabled,
        choices: const {
          ColorFieldFormat.hex: "Hex",
          ColorFieldFormat.rgb: "RGB",
          ColorFieldFormat.hsl: "HSL",
        },
        onSelected: (value) {
          if (value != null) onFormatChanged(value);
        },
      ),
      switch (format) {
        ColorFieldFormat.hex => _HexField(
          color: color,
          includeAlpha: includeAlpha,
          enabled: enabled,
          onChanged: onChanged,
        ),
        ColorFieldFormat.rgb => _RgbFields(
          color: color,
          includeAlpha: includeAlpha,
          enabled: enabled,
          onChanged: onChanged,
        ),
        ColorFieldFormat.hsl => _HslFields(
          color: color,
          includeAlpha: includeAlpha,
          enabled: enabled,
          onChanged: onChanged,
        ),
      },
    ],
  );
}

class _HexField extends StatelessWidget {
  const _HexField({
    required this.color,
    required this.includeAlpha,
    required this.enabled,
    required this.onChanged,
  });

  final Color color;
  final bool includeAlpha;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => ValidatedTextField<Color>(
    value: color,
    name: includeAlpha ? "ARGB color" : "RGB color",
    readOnly: !enabled,
    deserialize: (value) => value.formatHex(includeAlpha: includeAlpha),
    serialize: (value) => parseColorHex(value, includeAlpha: includeAlpha),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp("[0-9A-Fa-fxX#]")),
      LengthLimitingTextInputFormatter(includeAlpha ? 10 : 8),
    ],
    decoration: InputDecoration(
      labelText: includeAlpha ? "ARGB" : "Hex",
      prefixIcon: const SizedBox(width: 12),
    ),
    onChanged: onChanged,
  );
}

class _RgbFields extends StatelessWidget {
  const _RgbFields({
    required this.color,
    required this.includeAlpha,
    required this.enabled,
    required this.onChanged,
  });

  final Color color;
  final bool includeAlpha;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final alpha = (color.alphaByte * 100 / 255).round();
    return Row(
      spacing: 4,
      children: [
        _ChannelField(
          label: "R",
          labelColor: context.colors.danger,
          value: color.redByte,
          maximum: 255,
          enabled: enabled,
          onChanged: (value) => onChanged(
            colorFromChannels(
              red: value,
              green: color.greenByte,
              blue: color.blueByte,
              alphaPercent: alpha,
            ),
          ),
        ),
        _ChannelField(
          label: "G",
          labelColor: context.colors.success,
          value: color.greenByte,
          maximum: 255,
          enabled: enabled,
          onChanged: (value) => onChanged(
            colorFromChannels(
              red: color.redByte,
              green: value,
              blue: color.blueByte,
              alphaPercent: alpha,
            ),
          ),
        ),
        _ChannelField(
          label: "B",
          labelColor: context.colors.info,
          value: color.blueByte,
          maximum: 255,
          enabled: enabled,
          onChanged: (value) => onChanged(
            colorFromChannels(
              red: color.redByte,
              green: color.greenByte,
              blue: value,
              alphaPercent: alpha,
            ),
          ),
        ),
        if (includeAlpha)
          _ChannelField(
            label: "A%",
            labelColor: context.colors.contentSecondary,
            value: alpha,
            maximum: 100,
            enabled: enabled,
            onChanged: (value) => onChanged(
              colorFromChannels(
                red: color.redByte,
                green: color.greenByte,
                blue: color.blueByte,
                alphaPercent: value,
              ),
            ),
          ),
      ],
    );
  }
}

class _HslFields extends StatelessWidget {
  const _HslFields({
    required this.color,
    required this.includeAlpha,
    required this.enabled,
    required this.onChanged,
  });

  final Color color;
  final bool includeAlpha;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final alpha = (color.alphaByte * 100 / 255).round();
    Color next({double? hue, double? saturation, double? lightness, int? a}) =>
        colorFromHsl(
          hue: hue ?? hsl.hue,
          saturationPercent: saturation ?? hsl.saturation * 100,
          lightnessPercent: lightness ?? hsl.lightness * 100,
          alphaPercent: a ?? alpha,
        );
    return Row(
      spacing: 4,
      children: [
        _ChannelField(
          label: "H",
          labelColor: context.colors.selection,
          value: hsl.hue.round(),
          maximum: 360,
          enabled: enabled,
          onChanged: (value) => onChanged(next(hue: value.toDouble())),
        ),
        _ChannelField(
          label: "S%",
          labelColor: context.colors.success,
          value: (hsl.saturation * 100).round(),
          maximum: 100,
          enabled: enabled,
          onChanged: (value) => onChanged(next(saturation: value.toDouble())),
        ),
        _ChannelField(
          label: "L%",
          labelColor: context.colors.warning,
          value: (hsl.lightness * 100).round(),
          maximum: 100,
          enabled: enabled,
          onChanged: (value) => onChanged(next(lightness: value.toDouble())),
        ),
        if (includeAlpha)
          _ChannelField(
            label: "A%",
            labelColor: context.colors.contentSecondary,
            value: alpha,
            maximum: 100,
            enabled: enabled,
            onChanged: (value) => onChanged(next(a: value)),
          ),
      ],
    );
  }
}

class _ChannelField extends StatelessWidget {
  const _ChannelField({
    required this.label,
    required this.labelColor,
    required this.value,
    required this.maximum,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final Color labelColor;
  final int value;
  final int maximum;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (!enabled || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        final direction = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowUp => 1,
          LogicalKeyboardKey.arrowDown => -1,
          _ => 0,
        };
        if (direction == 0) return KeyEventResult.ignored;
        final step = HardwareKeyboard.instance.isShiftPressed ? 10 : 1;
        onChanged((value + direction * step).clamp(0, maximum));
        return KeyEventResult.handled;
      },
      child: ValidatedTextField<int>(
        value: value,
        name: label,
        readOnly: !enabled,
        deserialize: (value) => "$value",
        serialize: (source) {
          final parsed = int.tryParse(source);
          if (parsed == null || parsed < 0 || parsed > maximum) {
            throw FormatException("Enter a value from 0 to $maximum");
          }
          return parsed;
        },
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: labelColor,
                fontVariations: [FontVariation.weight(700)],
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
        textAlign: TextAlign.right,
        onChanged: onChanged,
      ),
    ),
  );
}
