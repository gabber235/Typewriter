import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps slider interaction available while no shared value exists.
class MixedSlider extends StatelessWidget {
  const MixedSlider({
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    this.divisions,
    super.key,
  });

  final double minimum;
  final double maximum;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = SliderTheme.of(context);
    final trackColor = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          value: "Multiple values",
          child: SliderTheme(
            data: theme.copyWith(
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: trackColor,
              inactiveTrackColor: trackColor,
            ),
            child: Slider(
              value: (minimum + maximum) / 2,
              min: minimum,
              max: maximum,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        const MixedValueMessage(),
      ],
    );
  }
}
