import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ColorChannelSlider extends StatefulWidget {
  const ColorChannelSlider({
    required this.label,
    required this.value,
    required this.gradient,
    required this.onChanged,
    this.divisions = 100,
    this.checkerboard = false,
    this.enabled = true,
    super.key,
  }) : assert(value >= 0 && value <= 1),
       assert(divisions > 0);

  final String label;
  final double value;
  final Gradient gradient;
  final ValueChanged<double> onChanged;
  final int divisions;
  final bool checkerboard;
  final bool enabled;

  @override
  State<ColorChannelSlider> createState() => _ColorChannelSliderState();
}

class _ColorChannelSliderState extends State<ColorChannelSlider> {
  final _focusNode = FocusNode();
  var _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _set(double value) {
    if (!widget.enabled) return;
    widget.onChanged(value.clamp(0, 1));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final step = 1 / widget.divisions;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _set(widget.value + step);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _set(widget.value - step);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _set(widget.value + step * 10);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _set(widget.value - step * 10);
    } else if (key == LogicalKeyboardKey.home) {
      _set(0);
    } else if (key == LogicalKeyboardKey.end) {
      _set(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    value: "${(widget.value * widget.divisions).round()}",
    increasedValue:
        "${((widget.value + 1 / widget.divisions).clamp(0, 1) * widget.divisions).round()}",
    decreasedValue:
        "${((widget.value - 1 / widget.divisions).clamp(0, 1) * widget.divisions).round()}",
    minValue: "0",
    maxValue: "${widget.divisions}",
    slider: true,
    enabled: widget.enabled,
    onIncrease: widget.enabled
        ? () => _set(widget.value + 1 / widget.divisions)
        : null,
    onDecrease: widget.enabled
        ? () => _set(widget.value - 1 / widget.divisions)
        : null,
    child: Focus(
      focusNode: _focusNode,
      onFocusChange: (value) => setState(() => _focused = value),
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _focusNode.requestFocus();
            _set(details.localPosition.dx / constraints.maxWidth);
          },
          onHorizontalDragStart: (details) {
            _focusNode.requestFocus();
            _set(details.localPosition.dx / constraints.maxWidth);
          },
          onHorizontalDragUpdate: (details) =>
              _set(details.localPosition.dx / constraints.maxWidth),
          child: SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  top: 3,
                  bottom: 3,
                  child: Builder(
                    builder: (context) {
                      final track = DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          borderRadius: context.shapes.largeBorderRadius,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      );
                      if (!widget.checkerboard) return track;
                      return Checkerboard(
                        borderRadius: context.shapes.largeBorderRadius,
                        child: track,
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment(widget.value * 2 - 1, 0),
                  child: Container(
                    width: _focused ? 14 : 12,
                    height: _focused ? 30 : 26,
                    decoration: BoxDecoration(
                      borderRadius: context.shapes.largeBorderRadius,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
