import "package:flutter/material.dart";
import "package:flutter/services.dart";

class ColorArea extends StatefulWidget {
  const ColorArea({
    required this.color,
    required this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  State<ColorArea> createState() => _ColorAreaState();
}

class _ColorAreaState extends State<ColorArea> {
  final _focusNode = FocusNode(debugLabel: "Color area");
  var _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateFromPosition(Offset position, Size size) {
    if (!widget.enabled || size.isEmpty) return;
    widget.onChanged(
      widget.color
          .withSaturation((position.dx / size.width).clamp(0, 1))
          .withValue(1 - (position.dy / size.height).clamp(0, 1)),
    );
  }

  void _adjust({double saturation = 0, double value = 0}) {
    if (!widget.enabled) return;
    widget.onChanged(
      widget.color
          .withSaturation((widget.color.saturation + saturation).clamp(0, 1))
          .withValue((widget.color.value + value).clamp(0, 1)),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.05 : 0.01;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _adjust(saturation: -step);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _adjust(saturation: step);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _adjust(value: step);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _adjust(value: -step);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _adjust(value: 0.1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _adjust(value: -0.1);
    } else if (key == LogicalKeyboardKey.home) {
      widget.onChanged(widget.color.withSaturation(0));
    } else if (key == LogicalKeyboardKey.end) {
      widget.onChanged(widget.color.withSaturation(1));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: "Saturation and brightness",
    value:
        "Saturation ${(widget.color.saturation * 100).round()} percent, brightness ${(widget.color.value * 100).round()} percent",
    enabled: widget.enabled,
    focusable: true,
    child: Focus(
      focusNode: _focusNode,
      canRequestFocus: widget.enabled,
      autofocus: widget.autofocus,
      onFocusChange: (value) => setState(() => _focused = value),
      onKeyEvent: _handleKey,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _focusNode.requestFocus();
            _updateFromPosition(details.localPosition, constraints.biggest);
          },
          onPanStart: (details) {
            _focusNode.requestFocus();
            _updateFromPosition(details.localPosition, constraints.biggest);
          },
          onPanUpdate: (details) =>
              _updateFromPosition(details.localPosition, constraints.biggest),
          child: CustomPaint(
            painter: _ColorAreaPainter(color: widget.color, focused: _focused),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

class _ColorAreaPainter extends CustomPainter {
  const _ColorAreaPainter({required this.color, required this.focused});

  final HSVColor color;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final hue = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor();
    canvas
      ..drawRect(bounds, Paint()..color = hue)
      ..drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.white, Colors.transparent],
          ).createShader(bounds),
      )
      ..drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ).createShader(bounds),
      );
    const handleRadius = 9.0;
    final center = Offset(
      (color.saturation * size.width).clamp(
        handleRadius,
        size.width - handleRadius,
      ),
      ((1 - color.value) * size.height).clamp(
        handleRadius,
        size.height - handleRadius,
      ),
    );
    canvas
      ..drawCircle(center, focused ? 9 : 7, Paint()..color = Colors.white)
      ..drawCircle(center, focused ? 6 : 5, Paint()..color = color.toColor())
      ..drawCircle(
        center,
        focused ? 9 : 7,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_ColorAreaPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.focused != focused;
}
