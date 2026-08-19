import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_reorderable_grid_view/widgets/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ColorSwatchGrid extends StatefulWidget {
  const ColorSwatchGrid({
    required this.label,
    required this.colors,
    required this.onSelected,
    this.onRemoved,
    this.onReordered,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<int> colors;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onRemoved;
  final ValueChanged<List<int>>? onReordered;
  final bool enabled;

  @override
  State<ColorSwatchGrid> createState() => _ColorSwatchGridState();
}

class _ColorSwatchGridState extends State<ColorSwatchGrid> {
  final _focusNode = FocusNode();
  var _focusedIndex = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _moveFocus(int index) {
    if (widget.colors.isEmpty) return;
    setState(() => _focusedIndex = index.clamp(0, widget.colors.length - 1));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event, int columns) {
    if (event is! KeyDownEvent || widget.colors.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final primary =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    var target = _focusedIndex;
    if (key == LogicalKeyboardKey.arrowLeft) {
      target--;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      target++;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target -= columns;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      target += columns;
    } else if (key == LogicalKeyboardKey.home) {
      target = 0;
    } else if (key == LogicalKeyboardKey.end) {
      target = widget.colors.length - 1;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      if (widget.enabled) widget.onSelected(widget.colors[_focusedIndex]);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.delete &&
        widget.onRemoved != null &&
        widget.enabled) {
      widget.onRemoved!(widget.colors[_focusedIndex]);
      _moveFocus(_focusedIndex - 1);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    target = target.clamp(0, widget.colors.length - 1);
    if (primary && widget.onReordered != null && widget.enabled) {
      final reordered = [...widget.colors];
      final value = reordered.removeAt(_focusedIndex);
      reordered.insert(target, value);
      widget.onReordered!(reordered);
    }
    _moveFocus(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.colors.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 40).floor().clamp(1, 8);
        final children = [
          for (final (index, argb) in widget.colors.indexed)
            _ColorSwatch(
              key: ValueKey(
                argb.toUnsigned(32).toRadixString(16).padLeft(8, "0"),
              ),
              color: Color(argb),
              focused: _focusNode.hasFocus && index == _focusedIndex,
              enabled: widget.enabled,
              onPressed: () {
                _moveFocus(index);
                _focusNode.requestFocus();
                widget.onSelected(argb);
              },
              onRemoved: widget.onRemoved == null
                  ? null
                  : () => widget.onRemoved!(argb),
              onMoveEarlier: widget.onReordered == null || index == 0
                  ? null
                  : () {
                      final values = [...widget.colors];
                      values.insert(index - 1, values.removeAt(index));
                      widget.onReordered!(values);
                    },
              onMoveLater:
                  widget.onReordered == null ||
                      index == widget.colors.length - 1
                  ? null
                  : () {
                      final values = [...widget.colors];
                      values.insert(index + 1, values.removeAt(index));
                      widget.onReordered!(values);
                    },
            ),
        ];
        Widget grid(List<Widget> values) => GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: context.spacing.space1,
          crossAxisSpacing: context.spacing.space1,
          children: values,
        );
        final child = widget.onReordered == null
            ? grid(children)
            : ReorderableBuilder<int>(
                enableDraggable: widget.enabled,
                longPressDelay: const Duration(milliseconds: 180),
                onReorder: (reorder) =>
                    widget.onReordered!(reorder(widget.colors)),
                builder: grid,
                children: children,
              );
        return Semantics(
          label: widget.label,
          container: true,
          explicitChildNodes: true,
          child: Focus(
            focusNode: _focusNode,
            onFocusChange: (_) => setState(() {}),
            onKeyEvent: (node, event) => _handleKey(node, event, columns),
            child: child,
          ),
        );
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.focused,
    required this.enabled,
    required this.onPressed,
    this.onRemoved,
    this.onMoveEarlier,
    this.onMoveLater,
    super.key,
  });

  final Color color;
  final bool focused;
  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback? onRemoved;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;

  @override
  Widget build(BuildContext context) {
    final hex = color.formatHex(includeAlpha: true);
    final swatch = Semantics(
      button: true,
      label: "Color $hex",
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: context.shapes.mediumBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Checkerboard(
            borderRadius: context.shapes.mediumBorderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: context.shapes.mediumBorderRadius,
                border: Border.all(
                  color: focused
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: focused ? 3 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (onRemoved == null) return swatch;
    return ContextMenuRegion(
      items: [
        MenuItem(label: "Apply", onPressed: enabled ? onPressed : null),
        MenuItem(
          label: "Move earlier",
          onPressed: enabled ? onMoveEarlier : null,
        ),
        MenuItem(label: "Move later", onPressed: enabled ? onMoveLater : null),
        MenuItem(label: "Remove", onPressed: enabled ? onRemoved : null),
      ],
      child: swatch,
    );
  }
}
